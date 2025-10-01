defmodule TdAi.Embeddings.ServingSupervisor do
  @moduledoc """
  Supervises serving processes created dynamically
  """
  use DynamicSupervisor

  require Logger

  def start_link(init_arg \\ []) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_), do: DynamicSupervisor.init(strategy: :one_for_one)

  def start_workers(workers) do
    workers
    |> Enum.map(&DynamicSupervisor.start_child(__MODULE__, &1))
    |> Enum.each(fn
      {:ok, pid} ->
        Logger.info("Process started with pid: #{inspect(pid)}")

      {:ok, pid, info} ->
        Logger.info("Process started with pid: #{inspect(pid)} and info: #{inspect(info)}")

      :ignored ->
        Logger.info("Process ignored")

      {:error, error} ->
        Logger.error("Error on process start: #{inspect(error)}")
    end)
  end

  def stop_worker(worker) do
    case GenServer.whereis(worker) do
      nil ->
        false

      child_pid ->
        __MODULE__
        |> DynamicSupervisor.which_children()
        |> Enum.find(fn
          {_, parent_pid, :supervisor, _} -> parent_of(parent_pid, child_pid)
          _ -> false
        end)
        |> then(fn
          nil ->
            {:error, :not_found}

          {_, parent_pid, :supervisor, _} ->
            DynamicSupervisor.terminate_child(__MODULE__, parent_pid)
        end)
    end
  end

  def exists?(worker) do
    case GenServer.whereis(worker) do
      nil -> false
      pid -> Process.alive?(pid)
    end
  end

  defp parent_of(parent_pid, child_pid) do
    parent_pid
    |> Supervisor.which_children()
    |> Enum.find(&(elem(&1, 1) == child_pid))
  end
end
