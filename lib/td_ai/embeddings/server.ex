defmodule TdAi.Embeddings.Server do
  # the child process is restarted only if it terminates abnormally
  use GenServer, restart: :transient

  @moduledoc """
  Server storing servings ffrom enabled indices
  """

  require Logger

  alias TdAi.Embeddings
  alias TdAi.Indices

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

  def handle_continue(:load_servings, state) do
    handle_load_servings(state)
  end

  def handle_call(:get_servings, _from, state) do
    {:reply, state, state}
  end

  def handle_call({:get_serving, collection_name}, _from, state) do
    {:reply, Map.get(state, collection_name), state}
  end

  def handle_cast(:refresh, state) do
    handle_load_servings(state)
  end

  defp handle_load_servings(state) do
    [enabled: true]
    |> Indices.list_indices()
    |> Enum.map(&load_from_index/1)
    |> Enum.split_with(&(elem(&1, 0) == :error))
    |> then(fn
      {[{:error, error_message}], _servings} ->
        Logger.error(error_message)
        {:stop, {:shutdown, error_message}, state}

      {[], [_ | _] = servings} ->
        {:noreply, Map.new(servings)}

      {[], []} ->
        {:noreply, @servings}
    end)
  end

  defp load_from_index(%{collection_name: name, embedding: embedding}) do
    @embedding_configs
    |> Enum.reduce_while(%{}, fn config, acc ->
      reduce_serving_for_config(config, acc, embedding)
    end)
    |> then(fn
      %{} = servings -> {name, servings}
      {:error, _error} = error -> error
    end)
  end

  defp reduce_serving_for_config({config_key, config}, servings, embedding) do
    case Embeddings.load_local_serving(embedding, embedding: config) do
      %Nx.Serving{} = serving ->
        {:cont, Map.put(servings, config_key, serving)}

      {:error, _error} = error ->
        {:halt, error}
    end
  end
end
