defmodule ShadowHash.Job.BruteforceClient do
  require Logger

  alias ShadowHash.Job.BruteforceJobServer
  alias ShadowHash.Job.JobScheduler
  alias ShadowHash.Job.DictionaryJob
  alias ShadowHash.Job.BruteforceJob
  alias ShadowHash.PasswordGraph
  alias ShadowHash.Hash

  def start_link() do
    Logger.info("* Bruteforce Client Starting")
    spawn(__MODULE__, :process, [])
  end

  def process() do
    receive do
      :shutdown ->
        Logger.info("Bruteforce client shutting down per request.")
        nil
    after
      200 ->
        with scheduler when not is_nil(scheduler) <- BruteforceJobServer.enlist() do
          Logger.info("Bruteforce client assigned to scheduler.")
          process_job(scheduler)
        end

        process()
    end
  end

  def shutdown(process) do
    send(process, :shutdown)
  end

  defp process_job(scheduler) do
    JobScheduler.process(scheduler, &handle_job/3)
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

  defp handle_job(algo, target, %DictionaryJob{names: names}) do
    names
    |> crack(algo, target)
  end

  defp handle_job(algo, target, %BruteforceJob{begin: start, last: last, charset: charset}) do
    start..last
    |> Stream.map(&PasswordGraph.from_index(&1, charset))
    |> crack(algo, target)
  end
end
