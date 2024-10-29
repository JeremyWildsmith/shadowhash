defmodule ShadowHash.Job.JobScheduler do
  require Logger

  alias ShadowHash.Job.JobParser

  @ready_idle_timeout 5000

  def chunk_size(%{method: :md5crypt}) do
    11000
  end

  def chunk_size(_) do
    500
  end

  defp dispatch_worker(jobs, algo, target, worker_pid) do
    jobs
    |> JobParser.take_job(chunk_size(algo))
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

  def schedule(jobs, algo, target) do
    schedule(jobs, algo, target, MapSet.new())
  end

  defp schedule([], _algo, _target, workers) when map_size(workers) == 0 do
    :terminate
  end

  defp schedule(jobs, algo, target, workers) do
    receive do
      {:ready, sender} ->
        Logger.info("Receieved ready, dispatching a job.")

        next_jobs =
          jobs
          |> dispatch_worker(algo, target, sender)

        next_workers =
          if next_jobs == [] do
            MapSet.put(workers, sender)
          else
            MapSet.delete(workers, sender)
          end

        jobs
        |> schedule(algo, target, next_workers)

      {:ok, ciphertext, plain} when ciphertext == target ->
        Logger.info("Plaintext found: #{plain}. shutting down scheduler.")
        for w <- workers, do: send(w, {:terminate})
        {:ok, plain}

      {:shutdown, sender} ->
        Logger.info("Scheduler receieved shutdown.")
        schedule([], algo, target, MapSet.delete(workers, sender))
    end
  end
end
