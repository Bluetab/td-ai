defmodule TdAi.Embeddings.ServingLoader do
  use GenServer

  @moduledoc """
  Loader managing servings async
  """

  require Logger

  alias TdAi.Embeddings.ServingSupervisor
  alias TdAi.Indices

  @embeddings Application.compile_env(:td_ai, :embeddings, TdAi.Embeddings)

  @config [
    defn_options: [compiler: EXLA],
    compile: [batch_size: 128, sequence_length: [128, 256, 512]],
    embedding_processor: :l2_norm
  ]

  @batch_timeout 100

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def init(_args) do
    {:ok, %{}, {:continue, :add_servings}}
  end

  def add_serving(index) do
    GenServer.cast(__MODULE__, {:add_serving, index})
  end

  def remove_serving(index) do
    GenServer.cast(__MODULE__, {:remove_serving, index})
  end

  def handle_continue(:add_servings, state) do
    do_add_servings()
    {:noreply, state}
  end

  def handle_cast({:add_serving, index}, state) do
    do_add_serving(index)
    {:noreply, state}
  end

  def handle_cast({:remove_serving, index}, state) do
    do_remove_serving(index)
    {:noreply, state}
  end

  def do_add_servings do
    [enabled: true]
    |> Indices.list_indices()
    |> Enum.map(&load_serving/1)
    |> Enum.reject(&is_nil/1)
    |> ServingSupervisor.start_workers()
  end

  def do_add_serving(index) do
    case load_serving(index) do
      nil -> :noop
      config -> ServingSupervisor.start_workers([config])
    end
  end

  def do_remove_serving(%{collection_name: name}) do
    name
    |> String.to_existing_atom()
    |> ServingSupervisor.stop_worker()
  end

  defp load_serving(%{collection_name: name, embedding: embedding}) do
    case @embeddings.load_local_serving(embedding, embedding: @config) do
      %Nx.Serving{} = serving ->
        {Nx.Serving,
         serving: serving,
         name: String.to_atom(name),
         batch_timeout: @batch_timeout,
         batch_size: @config[:compile][:batch_size],
         partitions: true}

      {:error, error} ->
        Logger.error("Error loading serving: #{inspect(error)}")
        nil
    end
  end
end
