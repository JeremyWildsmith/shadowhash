defmodule ShadowHash.Job.BruteforceJobServer do
  use GenServer

  def start_link() do
    GenServer.start_link(__MODULE__, nil, name: {:global, :bruteforce_job_server})
    |> case do
      {:error, {:already_started, _}} -> :ok
      {:error, _} -> raise "Error occurred starting link!"
      _ -> :ok
    end
  end

  # Genserver impl
  def init(_) do
    {:ok, []}
  end

  def handle_call(:enlist, _from, current_jobs) do
    {:reply, List.first(current_jobs), current_jobs}
  end

  def handle_cast({:submit_job, scheduler_pid}, current_jobs),
    do: {:noreply, current_jobs ++ [scheduler_pid]}

  def handle_cast({:dismiss_job, scheduler_pid}, current_jobs),
    do: {:noreply, Enum.filter(current_jobs, &(&1 != scheduler_pid))}

  def submit_job(scheduler_pid) do
    GenServer.cast(__MODULE__, {:submit_job, scheduler_pid})
  end

  def dismiss_job(scheduler_pid) do
    GenServer.cast(__MODULE__, {:dismiss_job, scheduler_pid})
  end

  def enlist() do
    GenServer.call(__MODULE__, :enlist)
  end
end
