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

  defp resolve_charset(false), do: PasswordGraph.printable_mapping()
  defp resolve_charset(true), do: PasswordGraph.all_mapping()

  def process(:help) do
    IO.puts("Shadow file parser and password cracker.")

    IO.puts(
      "Usage is: shadow_hash <shadow_file_path> [--user <username>] [--all-chars] [--dictionary <dictionary path>]"
    )

    IO.puts(
      " <shadow path> : The path to the linux shadow file containing hashed user passwords."
    )

    IO.puts(" --user        : Supply a username, the passwords for which will be cracked.")
    IO.puts("                 Otherwise, attempts to crack all passwords in the shadow file.")
    IO.puts(" --all-chars   : Will also bruteforce with non-printable characters")
    IO.puts(" --dictionary  : Supply a dictionary of passwords that are attempted initially")
    IO.puts(" --non-worker  : Do not spin up workers to process bruteforce requests")
    IO.puts(" --verbose     : Print verbose logging")
  end

  def process(%{
        shadow: shadow,
        user: user,
        dictionary: dictionary,
        all_chars: all_chars,
        non_worker: non_worker,
        verbose: verbose
      }) do

    unless verbose do
      Logger.configure([level: :none])
    end

    ErlexecBootstrap.prepare_port()
    BruteforceJobServer.start_link()

    workers =
      unless non_worker do
        # :erlang.system_info(:logical_processors_available)
        1..:erlang.system_info(:logical_processors_available)
        |> Enum.map(fn _ -> BruteforceClient.start_link end)
      else
        IO.puts("!!! WARNING: Started as non-worker. No workers on this node will be spawned to process bruteforce jobs.")
        []
      end

    process_file(user, File.read(shadow), dictionary, resolve_charset(all_chars))

    for w <- workers, do: BruteforceClient.shutdown(w)
  end

  def process_file(user, {:ok, contents}, dictionary, charset) do
    pwd = ShadowParse.extract_passwords(contents, user)

    if pwd == [] do
      IO.puts(
        "No user matching the search criteria #{user} was found. No attacks will be performed."
      )
    else
      IO.puts(
        "The following users were found matching the specified criteria. Bruteforce will be performed on the following users"
      )

      pwd |> Enum.each(fn {u, _} -> IO.puts(" * #{u}") end)

      IO.puts("\nStarting attack...")
      for {u, p} <- pwd, do: process_file_entry(u, p, dictionary, charset)
    end
  end

  def process_file(_, {_status, _r}, _, _) do
    IO.puts(
      "Error, unable to open the shadow file. It may not exist or you do not have permission to access the file."
    )
  end

  def process_file_entry(user, pwd, dictionary, charset) do
    IO.puts("Attempting to recover password for user #{user}")
    %{hash: hash, algo: algo} = PasswordParse.parse(pwd)

    IO.puts(" - Detected password type: #{Atom.to_string(algo.method)}")
    IO.puts(" - Detected password hash: #{hash}")

    {elapsed, password} = :timer.tc(__MODULE__, :crack, [algo, hash, dictionary, charset])

    elapsed = elapsed / 1_000_000

    case password do
      nil ->
        IO.puts("Password not found for user #{user} in #{elapsed} seconds")

      plaintext ->
        IO.puts(
          "Password cracked for user #{user} in #{elapsed} seconds. Plaintext: \"#{plaintext}\""
        )
    end
  end

  def crack(algo, hash, dictionary, charset) do
    Logger.info("Submitting bruteforce job to job server.")
    BruteforceJobServer.submit_job(self())

    jobs = [
      %DictionaryStreamJob{stream: dictionary(dictionary)},
      %BruteforceJob{begin: 0, last: :inf, charset: charset}
    ]

    Logger.info("Starting job scheduler...")
    {:ok, plaintext} = JobScheduler.schedule(jobs, algo, hash)

    Logger.info("Dismissing bruteforce job from job server.")
    BruteforceJobServer.dismiss_job(self())

    plaintext
  end

  def crack_old(algo, hash, dictionary, charset) do
    dictionary(dictionary)
    |> Stream.concat(bruteforce(charset))
    |> Stream.map(&{Hash.generate(algo, &1), &1})
    |> Stream.filter(fn {cipher, _} -> cipher === hash end)
    |> Stream.map(fn {_, plain} -> plain end)
    |> Enum.take(1)
    |> List.first()
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
    IO.puts(" - No dictonary file was supplied. Skipping dictionary attack.")
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
