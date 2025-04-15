defmodule TdAi.Embeddings do
  alias TdAi.Indices
  alias TdAi.Embeddings.Server

  def load_serving(model_name, opts \\ []) do
    model_opts = opts[:model] || []
    tokenizer_opts = opts[:tokenizer] || []
    embedding_opts = opts[:embedding] || []
    {:ok, model} = Bumblebee.load_model({:hf, model_name, model_opts})
    {:ok, tokenizer} = Bumblebee.load_tokenizer({:hf, model_name, tokenizer_opts})

    Bumblebee.Text.text_embedding(model, tokenizer, embedding_opts)
  end

  def generate_vector(text, collection_name \\ nil)

  def generate_vector(text, collection_name) when is_binary(collection_name) do
    Server.generate_vector(text, collection_name)
  end

  def generate_vector(text, nil) do
    case Indices.first_enabled() do
      %Indices.Index{collection_name: collection_name} -> generate_vector(text, collection_name)
      nil -> :noop
    end
  end

  def vector_for_serving(%Nx.Serving{} = serving, texts) when is_list(texts) do
    serving
    |> Nx.Serving.run(texts)
    |> Enum.map(fn %{embedding: tensor} -> Nx.to_flat_list(tensor) end)
  end

  def vector_for_serving(%Nx.Serving{} = serving, text) do
    %{embedding: embedding} = Nx.Serving.run(serving, text)
    Nx.to_flat_list(embedding)
  end
end
