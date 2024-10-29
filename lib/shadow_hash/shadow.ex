defmodule ShadowHash.Shadow do
  require Logger
  alias ShadowHash.Hash
  alias ShadowHash.PasswordParse
  alias ShadowHash.ShadowParse
  alias ShadowHash.PasswordGraph
  alias ShadowHash.ErlexecBootstrap
  alias ShadowHash.Job.BruteforceJobServer
  alias ShadowHash.Job.JobScheduler
  alias ShadowHash.Job.DictionaryStreamJob
  alias ShadowHash.Job.BruteforceJob
  alias ShadowHash.Job.BruteforceClient
  alias ShadowHash.Gpu.Md5crypt
  alias ShadowHash.Gpu.Strutil

  defp resolve_charset(false), do: PasswordGraph.printable_mapping()
  defp resolve_charset(true), do: PasswordGraph.all_mapping()

  def process(:help) do
    IO.puts("Shadow file parser and password cracker.")

    IO.puts("Usage is: shadow_hash <shadow_path> [--user <username>]")

    IO.puts(
      " <shadow_path> : The path to the linux shadow file containing hashed user passwords."
    )

    IO.puts(" --user <user>  : Supply a username, the passwords for which will be cracked.")
    IO.puts("                  Otherwise, attempts to crack all passwords in the shadow file.")
    IO.puts(" --all-chars    : Will also bruteforce with non-printable characters")

    IO.puts(
      " --dictionary <dictionary>  : Supply a dictionary of passwords that are attempted initially"
    )

    IO.puts(" --gpu           : Supported for md5crypt, will execute the hash algorithm")
    IO.puts("                   on the GPU. There is initial overhead to JIT compile to CUDA")
    IO.puts("                   but after JIT compiling, significantly faster.")
    IO.puts(" --gpu-warmup    : Warm-up GPU bruteforce algorithm. Useful when capturing")
    IO.puts("                   timing metrics and you don't want to include start-up overhead")
    IO.puts(" --workers <num> : Number of workers to process bruteforce requests. Defaults")

    IO.puts(
      "                   to number of available CPU cores. Be mindful of the memory constraint "
    )

    IO.puts("                   of GPU if using GPU acceleration")
    IO.puts(" --verbose       : Print verbose logging")
  end

  def process(%{
        shadow: shadow,
        user: user,
        dictionary: dictionary,
        all_chars: all_chars,
        workers: num_workers,
        verbose: verbose,
        gpu: gpu_acceleration,
        gpu_warmup: gpu_warmup,
        password: password
      }) do
    unless verbose do
      Logger.configure(level: :none)
    end

    ErlexecBootstrap.prepare_port()
    BruteforceJobServer.start_link()

    gpu_hashers = create_gpu_hashers(gpu_acceleration, gpu_warmup)

    non_worker = num_workers <= 0

    workers =
      unless non_worker do
        1..num_workers
        |> Enum.map(fn _ -> BruteforceClient.start_link(gpu_hashers) end)
      else
        IO.puts(
          " !!! WARNING: Started as non-worker. No workers on this node will be spawned to process bruteforce jobs."
        )

        []
      end

    if gpu_acceleration do
      IO.puts(" *** GPU Acceleration is enabled.")
    else
      IO.puts(" !!! GPU Acceleration is disabled.")
    end

    IO.puts(" *** Using #{num_workers} worker processes ")

    gpu_accelerated_hashers =
      gpu_hashers
      |> Map.keys()
      |> MapSet.new()

    load_passwords(user, shadow, password)
    |> process_passwords(gpu_accelerated_hashers, dictionary, resolve_charset(all_chars))

    for {:ok, w} <- workers, do: BruteforceClient.shutdown(w)
  end

  defp warmup_gpu(gpu_hasher) do
    passwords =
      Stream.duplicate(~c"wu", chunk_size(:md5crypt, true))
      |> Enum.to_list()
      |> Strutil.create_set()

    needle =
      [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
      |> Nx.tensor(type: {:u, 8})

    salt =
      ~c"01234567"
      |> Strutil.create()

    gpu_hasher.(
      passwords,
      salt,
      needle
    )
  end

  defp create_gpu_hashers(enable_acceleration, warmup) do
    if enable_acceleration do
      md5crypt_jit = Nx.Defn.jit(&Md5crypt.md5crypt_find/3, compiler: EXLA)

      if warmup do
        IO.puts("Warming up GPU JIT compile.")
        warmup_gpu(md5crypt_jit)
        IO.puts("Warmup done.")
      end

      %{
        md5crypt: md5crypt_jit
      }
    else
      %{}
    end
  end

  defp load_passwords(user, shadow, password) do
    pwd =
      unless is_nil(shadow) do
        case File.read(shadow) do
          {:ok, r} -> ShadowParse.extract_passwords(r, user)
          _ ->
            IO.puts("Error reading from shadow file. It may not exist. No passwords will be collected from shadow file.")
            []
        end
      else
        []
      end

    unless is_nil(password) do
      pwd ++ [{"command_line_entry", password}]
    else
      pwd
    end
  end

  def process_passwords(pwd, gpu_accelerated_algorithms, dictionary, charset) do
    if pwd == [] do
      IO.puts("No user matching the search criteria was found. No attacks will be performed.")
    else
      IO.puts(" *** Bruteforce will be performed on the following users")

      pwd |> Enum.each(fn {u, _} -> IO.puts("     - #{u}") end)

      IO.puts("\nStarting attack...")
      for {u, p} <- pwd, do: process_file_entry(gpu_accelerated_algorithms, u, p, dictionary, charset)
    end
  end

  def chunk_size(:md5crypt, gpu_accelerated) do
    if gpu_accelerated do
      11000
    else
      500
    end
  end

  def chunk_size(_algo, _gpu_accelerated) do
    500
  end

  def process_file_entry(gpu_accelerated_algorithms, user, pwd, dictionary, charset) do
    IO.puts("Attempting to recover password for user #{user}")
    %{hash: hash, algo: algo} = PasswordParse.parse(pwd)
    %{method: method} = algo

    IO.puts(" - Detected password type: #{Atom.to_string(algo.method)}")
    IO.puts(" - Detected password hash: #{hash}")

    chunk = chunk_size(method, MapSet.member?(gpu_accelerated_algorithms, method))

    {elapsed, password} = :timer.tc(__MODULE__, :crack, [algo, hash, chunk, dictionary, charset])

    elapsed = elapsed / 1_000_000

    case password do
      nil ->
        IO.puts("Password not found for user #{user} in #{elapsed} seconds")

      plaintext ->
        IO.puts("Password cracked for #{user} in #{elapsed} seconds. Plaintext: \"#{plaintext}\"")
    end
  end

  def crack(algo, hash, chunk_size, dictionary, charset) do
    Logger.info("Submitting bruteforce job to job server.")
    BruteforceJobServer.submit_job(self())

    jobs = [
      %DictionaryStreamJob{stream: dictionary(dictionary)},
      %BruteforceJob{begin: 0, last: :inf, charset: charset}
    ]

    Logger.info("Starting job scheduler...")
    {:ok, plaintext} = JobScheduler.schedule(jobs, algo, hash, chunk_size)

    Logger.info("Dismissing bruteforce job from job server.")
    BruteforceJobServer.dismiss_job(self())

    plaintext
  end

  defp _dictionary_entry_trim_newline(line) do
    if String.ends_with?(line, "\r\n") do
      {trimmed, _} = String.split_at(line, String.length(line) - 1)
      trimmed
    else
      if(String.ends_with?(line, "\n")) do
        {trimmed, _} = String.split_at(line, String.length(line))
        trimmed
      else
        line
      end
    end
  end

  def dictionary(nil) do
    IO.puts(" - No dictionary file was supplied. Skipping dictionary attack.")
    []
  end

  def dictionary(dictionary) do
    IO.puts(" - Dictionary provided: #{dictionary}.")

    if File.exists?(dictionary) do
      File.stream!(dictionary, :line)
      |> Stream.map(&_dictionary_entry_trim_newline/1)
    else
      IO.puts(" ! Unable to open dictionary file. It may not exist. Skipping")
      []
    end
  end

  def bruteforce(charset) do
    Stream.iterate(0, &(&1 + 1))
    |> Stream.map(&PasswordGraph.from_index(&1, charset))
  end
end
