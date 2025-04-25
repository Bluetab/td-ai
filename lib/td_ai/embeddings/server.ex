defmodule TdAi.Embeddings.Server do
  use GenServer

  @moduledoc """
  Server storing servings ffrom enabled indices
  """

  alias TdAi.Embeddings
  alias TdAi.Indices

  @model_dir Application.app_dir(:td_ai, "priv/models")
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

  def get_serving(collection_name) do
    GenServer.call(__MODULE__, {:get_serving, collection_name})
  end

  def handle_continue(:load_servings, _state) do
    new_state =
      [enabled: true]
      |> Indices.list_indices()
      |> Enum.into(%{}, &load_from_index/1)

    {:noreply, new_state}
  end

  def handle_call(:get_servings, _from, state) do
    {:reply, state, state}
  end

  def handle_call({:get_serving, collection_name}, _from, state) do
    {:reply, Map.get(state, collection_name), state}
  end

  defp load_from_index(%{collection_name: name, embedding: embedding}) do
    serving =
      Embeddings.load_serving(embedding,
        model: [offline: true, cache_dir: @model_dir],
        tokenizer: [offline: true, cache_dir: @model_dir],
        embedding: [
          defn_options: [compiler: EXLA],
          compile: [batch_size: 128, sequence_length: [128, 256, 512]]
        ]
      )

    {name, serving}
  end
end
