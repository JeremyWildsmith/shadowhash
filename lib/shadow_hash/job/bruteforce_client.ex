defmodule ShadowHash.Job.BruteforceClient do
  require Logger

  alias ShadowHash.Job.BruteforceJobServer
  alias ShadowHash.Job.JobScheduler
  alias ShadowHash.Job.DictionaryJob
  alias ShadowHash.Job.BruteforceJob
  alias ShadowHash.PasswordGraph
  alias ShadowHash.Hash
  alias ShadowHash.Gpu.Strutil
  alias ShadowHash.Gpu.Md5

  def start_link(gpu_acceleration) do
    Logger.info("* Bruteforce Client Starting")

    gpu_hashers =
      if gpu_acceleration do
        %{
          md5crypt: Nx.Defn.jit(&Strutil.md5crypt_find/3, compiler: EXLA)
        }
      else
        %{}
      end

    spawn(__MODULE__, :process, [gpu_hashers])

    :sleeplocks.new(1, name: :gpu_lock)
  end

  def process(gpu_hashers) do
    receive do
      :shutdown ->
        Logger.info("Bruteforce client shutting down per request.")
        nil
    after
      200 ->
        with scheduler when not is_nil(scheduler) <- BruteforceJobServer.enlist() do
          Logger.info("Bruteforce client assigned to scheduler.")
          process_job(gpu_hashers, scheduler)
        end

        process(gpu_hashers)
    end
  end

  def shutdown(process) do
    send(process, :shutdown)
  end

  defp process_job(gpu_hashers, scheduler) do
    JobScheduler.process(scheduler, fn algo, target, job ->
      handle_job(gpu_hashers, algo, target, job)
    end)
  end

  defp generate_hashes(stream, algo) do
    stream
    |> Stream.map(&{Hash.generate(algo, &1), &1})
  end

  defp crack(stream, algo, hash) do
    generate_hashes(stream, algo)
    |> Stream.filter(fn {cipher, _} -> cipher === hash end)
    |> Stream.map(fn {_, plain} -> plain end)
    |> Enum.take(1)
    |> List.first()
    |> case do
      nil -> nil
      plain -> {:ok, plain}
    end
  end

  defp handle_generic_cpu(gpu_hashers, algo, target, %BruteforceJob{
         begin: start,
         last: last,
         charset: charset
       }) do
    start..last
    |> Stream.map(&PasswordGraph.from_index(&1, charset))
    |> crack(algo, target)
  end

  defp handle_md5crypt_gpu(gpu_hashers, %{config: config}, target, %BruteforceJob{
         begin: start,
         last: last,
         charset: charset
       }) do
    salt =
      config
      |> :binary.bin_to_list()
      |> Enum.drop(3)
      |> Strutil.create()

    passwords =
      start..last
      |> Stream.map(&(PasswordGraph.from_index(&1, charset) |> :binary.bin_to_list()))
      |> Enum.to_list()
      |> Strutil.create_set()

    needle =
      target
      |> :binary.bin_to_list()
      |> Md5.decode_b64_hash()
      |> Nx.tensor(type: {:u, 8})

    try do
      match_index =
        Map.get(gpu_hashers, :md5crypt).(
          passwords,
          salt,
          needle
        )
        |> Nx.to_number()
        |> IO.inspect()
        |> case do
          -1 -> nil
          n -> {:ok, PasswordGraph.from_index(n + start, charset)}
        end
    rescue
      r -> r |> IO.inspect()
    end
  end

  defp handle_job(gpu_hashers, algo, target, %DictionaryJob{names: names}) do
    names
    |> crack(algo, target)
  end

  defp handle_job(gpu_hashers, algo = %{method: :md5crypt}, target, %BruteforceJob{} = job) do
    Logger.info(
      "MD5crypt is supported by a GPU accelerated hasher. Attempting to acquire GPU lock"
    )

    unless Map.has_key?(gpu_hashers, :md5crypt) do
      Logger.info("No md5crypt GPU hasher loaded. Falling back to CPU hasher.")
      handle_generic_cpu(gpu_hashers, algo, target, job)
    else
      :sleeplocks.attempt(:gpu_lock)
      |> case do
        :ok ->
          Logger.info("Lock acquired. Applying GPU accelerated hashing")
          r = handle_md5crypt_gpu(gpu_hashers, algo, target, job)
          Logger.info("Releasing lock")
          :sleeplocks.release(:gpu_lock)
          r

        _ ->
          Logger.info("GPU is in use. Falling back to CPU bound")
          handle_generic_cpu(gpu_hashers, algo, target, job)
      end
    end
  end

  defp handle_job(gpu_hashers, algo, target, %BruteforceJob{} = job) do
    handle_generic_cpu(gpu_hashers, algo, target, job)
  end
end
