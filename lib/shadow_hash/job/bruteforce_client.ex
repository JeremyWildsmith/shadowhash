defmodule ShadowHash.Job.BruteforceClient do
  require Logger

  alias ShadowHash.Job.BruteforceJobServer
  alias ShadowHash.Job.JobScheduler
  alias ShadowHash.Job.DictionaryJob
  alias ShadowHash.Job.BruteforceJob
  alias ShadowHash.PasswordGraph
  alias ShadowHash.Hash
  alias ShadowHash.Gpu.Md5crypt
  alias ShadowHash.ShadowBase64

  def start_link(gpu_hashers) do
    Logger.info("* Bruteforce Client Starting")

    :sleeplocks.new(1, name: :gpu_lock)

    spawn(__MODULE__, :process, [gpu_hashers])
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

  defp handle_generic_cpu(_gpu_hashers, algo, target, %BruteforceJob{
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
      |> Md5crypt.create()

    passwords =
      start..last
      |> Stream.map(&(PasswordGraph.from_index(&1, charset) |> :binary.bin_to_list()))
      |> Enum.to_list()
      |> Md5crypt.create_set()

    needle =
      target
      |> :binary.bin_to_list()
      |> ShadowBase64.decode_b64_hash()
      |> Nx.tensor(type: {:u, 8})

    Logger.info("Tensor data constructed for GPU hashing. Waiting for lock...")
    :sleeplocks.acquire(:gpu_lock)
    Logger.info("Lock acquired. Applying GPU accelerated hashing")

    try do
      Map.get(gpu_hashers, :md5crypt).(
        passwords,
        salt,
        needle
      )
      |> Nx.to_number()
      |> case do
        -1 -> nil
        n -> {:ok, PasswordGraph.from_index(n + start, charset)}
      end
    rescue
      r ->
        Logger.error("GPU Hasher failed. Dumping information to IO.Inspect...")
        r |> IO.inspect()
    after
      Logger.info("Releasing GPU lock")
      :sleeplocks.release(:gpu_lock)
    end
  end

  defp handle_job(_gpu_hashers, algo, target, %DictionaryJob{names: names}) do
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
      Logger.info("Md5crypt gpu hasher is available. Using GPU Hasher")
      handle_md5crypt_gpu(gpu_hashers, algo, target, job)
    end
  end

  defp handle_job(gpu_hashers, algo, target, %BruteforceJob{} = job) do
    handle_generic_cpu(gpu_hashers, algo, target, job)
  end
end
