defmodule TdAi.Embeddings.Server do
  use GenServer

  alias TdAi.Indices
  alias TdAi.Embeddings

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

  def generate_vector(text, serving_name) do
    GenServer.call(__MODULE__, {:generate_vector, text, serving_name})
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

  def handle_call({:generate_vector, text, serving_name}, _from, state) do
    case Map.get(state, serving_name) do
      %Nx.Serving{} = serving ->
        embedding = Embeddings.vector_for_serving(serving, text)
        {:reply, embedding, state}

      nil ->
        {:reply, :noop, state}
    end
  end

  defp load_from_index(%{collection_name: name, embedding: embedding}) do
    serving =
      Embeddings.load_serving(embedding,
        model: [offline: true, cache_dir: @model_dir],
        tokenizer: [offline: true, cache_dir: @model_dir],
        embedding: [
          defn_options: [compiler: EXLA],
          compile: [batch_size: 32, sequence_length: 64]
        ]
      )

    {name, serving}
  end
end
