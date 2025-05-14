defmodule TdAi.Embeddings.Behaviour do
  @moduledoc """
  Embeddings behaviour
  """
  @callback load_local_serving(model_name :: binary()) :: Nx.Serving.t() | {:error, term()}
  @callback load_local_serving(model_name :: binary(), opts :: Keyword.t()) ::
              Nx.Serving.t() | {:error, term()}
  @callback all([binary()]) :: %{binary() => [float()]}
  @callback generate_vector(text :: binary()) :: {binary(), [float()]} | :noop
  @callback generate_vector(text :: binary(), collection_name :: binary() | nil) ::
              {binary(), [float()]} | :noop
end

defmodule TdAi.Embeddings do
  @moduledoc """
  Module managing embeddings
  """
  @behaviour TdAi.Embeddings.Behaviour

  alias TdAi.Embeddings.Server
  alias TdAi.Indices

  @model_base_path Application.compile_env!(:td_ai, :model_path)

  def load_local_serving(model_name, opts \\ []) do
    embedding_opts = opts[:embedding] || []
    local_path = Path.join(@model_base_path, model_name)

    with {:ok, model} <- Bumblebee.load_model({:local, local_path}),
         {:ok, tokenizer} <- Bumblebee.load_tokenizer({:local, local_path}) do
      Bumblebee.Text.text_embedding(model, tokenizer, embedding_opts)
    end
  end

  def all(texts) do
    Enum.into(Server.get_servings(), %{}, fn {collection_name, serving} ->
      {collection_name, vector_for_serving(serving, texts)}
    end)
  end

  def generate_vector(text, collection_name \\ nil)

  def generate_vector(text, collection_name) when is_binary(collection_name) do
    case Server.get_serving(collection_name) do
      %{} = serving -> {collection_name, vector_for_serving(serving, text)}
      nil -> :noop
    end
  end

  def generate_vector(text, nil) do
    case Indices.first_enabled() do
      %Indices.Index{collection_name: collection_name} -> generate_vector(text, collection_name)
      nil -> :noop
    end
  end

  defp vector_for_serving(%{multiple: %Nx.Serving{} = serving}, texts) when is_list(texts) do
    texts = normalize(texts)

    serving
    |> Nx.Serving.run(texts)
    |> Enum.map(fn %{embedding: tensor} -> Nx.to_flat_list(tensor) end)
  end

  defp vector_for_serving(%{single: %Nx.Serving{} = serving}, text) do
    text = normalize(text)
    %{embedding: embedding} = Nx.Serving.run(serving, text)
    Nx.to_flat_list(embedding)
  end

  defp normalize(texts) when is_list(texts) do
    Enum.map(texts, &normalize/1)
  end

  defp normalize(text) when is_binary(text) do
    text
    |> split_snake_case()
    |> split_camel_case()
    |> String.downcase()
    |> String.trim()
  end

  defp split_snake_case(text) do
    String.replace(text, "_", " ")
  end

  defp split_camel_case(text) do
    Regex.replace(~r/([a-z])([A-Z])/, text, "\\1 \\2")
  end
end
