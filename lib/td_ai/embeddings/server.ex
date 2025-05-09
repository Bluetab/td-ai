defmodule TdAi.Embeddings.Server do
  # the child process is restarted only if it terminates abnormally
  use GenServer, restart: :transient

  @moduledoc """
  Server storing servings ffrom enabled indices
  """

  require Logger

  alias TdAi.Indices

  @embeddings Application.compile_env(:td_ai, :embeddings, TdAi.Embeddings)

  @embedding_configs [
    single: [
      defn_options: [compiler: EXLA],
      compile: [batch_size: 1, sequence_length: [128, 256, 512]]
    ],
    multiple: [
      defn_options: [compiler: EXLA],
      compile: [batch_size: 128, sequence_length: [128, 256, 512]]
    ]
  ]
  @servings %{}

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def init(_args) do
    {:ok, @servings, {:continue, :load_servings}}
  end

  def get_servings do
    GenServer.call(__MODULE__, :get_servings)
  end

  def refresh do
    GenServer.cast(__MODULE__, :refresh)
  end

  def get_serving(collection_name) do
    GenServer.call(__MODULE__, {:get_serving, collection_name})
  end

  def add_serving(index) do
    GenServer.cast(__MODULE__, {:add_serving, index})
  end

  def remove_serving(index) do
    GenServer.cast(__MODULE__, {:remove_serving, index})
  end

  def handle_continue(:load_servings, _state) do
    {:noreply, handle_load_servings()}
  end

  def handle_call(:get_servings, _from, state) do
    {:reply, state, state}
  end

  def handle_call({:get_serving, collection_name}, _from, state) do
    {:reply, Map.get(state, collection_name), state}
  end

  def handle_cast(:refresh, _state) do
    {:noreply, handle_load_servings()}
  end

  def handle_cast({:add_serving, index}, state) do
    index
    |> load_from_index()
    |> then(fn
      {:error, _message} ->
        {:noreply, state}

      {name, serving} ->
        {:noreply, Map.put(state, name, serving)}
    end)
  end

  def handle_cast({:remove_serving, %{collection_name: collection_name}}, state) do
    {:noreply, Map.delete(state, collection_name)}
  end

  defp handle_load_servings do
    [enabled: true]
    |> Indices.list_indices()
    |> Enum.map(&load_from_index/1)
    |> Enum.reject(&(elem(&1, 0) == :error))
    |> Map.new()
  end

  defp load_from_index(%{collection_name: name, embedding: embedding}) do
    @embedding_configs
    |> Enum.reduce_while(%{}, fn config, acc ->
      reduce_serving_for_config(config, acc, embedding)
    end)
    |> then(fn
      %{} = servings ->
        {name, servings}

      {:error, message} = error ->
        Logger.error(message)
        error
    end)
  end

  defp reduce_serving_for_config({config_key, config}, servings, embedding) do
    case @embeddings.load_local_serving(embedding, embedding: config) do
      %Nx.Serving{} = serving ->
        {:cont, Map.put(servings, config_key, serving)}

      {:error, _error} = error ->
        {:halt, error}
    end
  end
end
