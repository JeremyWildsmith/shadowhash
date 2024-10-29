defmodule ShadowHash.Job.JobScheduler do
  require Logger

  alias ShadowHash.Job.JobParser

  @ready_idle_timeout 5000

  defp dispatch_worker(jobs, algo, target, worker_pid, chunk_size) do
    jobs
    |> JobParser.take_job(chunk_size)
    |> case do
      {current, next} ->
        send(worker_pid, {:work, algo, target, current})
        next

      :empty ->
        send(worker_pid, {:terminate})
        []
    end
  end

  def process(scheduler, handler) do
    Logger.info("Letting scheduler know I am ready.")
    send(scheduler, {:ready, self()})

    receive do
      {:work, algo, target, job} ->
        Logger.info("Received a job. Processing the job.")

        with {:ok, plaintext} <- handler.(algo, target, job),
             do: send(scheduler, {:ok, target, plaintext})

        Logger.info("Done assigned job.")
        process(scheduler, handler)

      {:terminate} ->
        Logger.info("Instructed by scheduler to terminate. Worker is closing...")
        send(scheduler, {:shutdown, self()})
        :terminate
    after
      @ready_idle_timeout ->
        Logger.info("Ready timeout. Worker is closing...")
        :terminate
    end
  end

  def schedule(jobs, algo, target, chunk_size) do
    schedule(jobs, algo, target, chunk_size, MapSet.new())
  end

  defp schedule([], _algo, _target, _chunk_size, workers) when map_size(workers) == 0 do
    :terminate
  end

  defp schedule(jobs, algo, target, chunk_size, workers) do
    receive do
      {:ready, sender} ->
        Logger.info("Receieved ready, dispatching a job.")

        next_jobs =
          jobs
          |> dispatch_worker(algo, target, sender, chunk_size)

        next_workers =
          if next_jobs == [] do
            MapSet.put(workers, sender)
          else
            MapSet.delete(workers, sender)
          end

        next_jobs
        |> schedule(algo, target, chunk_size, next_workers)

      {:ok, ciphertext, plain} when ciphertext == target ->
        Logger.info("Plaintext found: #{plain}. shutting down scheduler.")
        for w <- workers, do: send(w, {:terminate})
        {:ok, plain}

      {:shutdown, sender} ->
        Logger.info("Scheduler receieved shutdown.")

        []
        |> schedule(algo, target, chunk_size, MapSet.delete(workers, sender))
    end
  end
end
