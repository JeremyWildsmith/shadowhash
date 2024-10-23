defmodule ShadowHash.Job.JobScheduler do
  alias ShadowHash.Job.JobParser

  @ready_idle_timeout 5000

  defp dispatch_worker(algo, target, worker_pid, jobs) do
    jobs
    |> JobParser.take_job()
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
    send(scheduler, {:ready, self()})

    receive do
      {:work, algo, target, job} ->
        IO.puts("Received a job. Processing the job.")

        with {:ok, plaintext} <- handler.(algo, target, job),
             do: send(scheduler, {:ok, plaintext})

        process(scheduler, handler)

      {:terimate} ->
        IO.puts("Instructed by scheduler to terminate. Worker is closing...")
        send(scheduler, {:shutdown, self()})
        :terminate
    after
      @ready_idle_timeout ->
        IO.puts("Ready timeout. Worker is closing...")
        :terminate
    end
  end

  def schedule(jobs, algo, target) do
    schedule(jobs, algo, target, MapSet.new())
  end

  defp schedule([], _algo, _target, workers) when map_size(workers) == 0 do
    :terminate
  end

  defp schedule(jobs, algo = %{method: t}, target, workers) do
    receive do
      {:ready, ^t, sender, ^t} ->
        jobs
        |> dispatch_worker(algo, target, sender)
        |> schedule(algo, target, MapSet.put(workers, sender))

      {:ready, ^t, sender, _} ->
        send(sender, {:terminate})
        schedule(jobs, algo, target, workers)

      {:ok, plain} ->
        schedule([], algo, target, workers)
        {:ok, plain}

      {:shutdown, sender} ->
        schedule([], algo, target, MapSet.delete(workers, sender))
    end
  end
end
