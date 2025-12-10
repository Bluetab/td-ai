defmodule TdAi.Embeddings.Behaviour do
  @moduledoc """
  Embeddings behaviour
  """
  @callback load_local_serving(model_name :: binary()) :: Nx.Serving.t() | {:error, term()}
  @callback load_local_serving(model_name :: binary(), opts :: Keyword.t()) ::
              Nx.Serving.t() | {:error, term()}
  @callback all([binary()], index_type :: binary()) :: %{binary() => [float()]}
  @callback generate_vector(text :: binary(), index_type :: binary()) ::
              {binary(), [float()]} | :noop
  @callback generate_vector(
              text :: binary() | [binary()],
              index_type :: binary(),
              collection_name :: binary() | nil
            ) ::
              {binary(), [float()] | [[float()]]} | :noop
  @callback generate_vector(text :: binary(), index_type :: binary()) ::
              {binary(), [float()]} | :noop
end

defmodule TdAi.Embeddings do
  @moduledoc """
  Module managing embeddings
  """
  @behaviour TdAi.Embeddings.Behaviour

  alias TdAi.Embeddings.ServingSupervisor
  alias TdAi.Indices

  def load_local_serving(model_name, opts \\ []) do
    embedding_opts = opts[:embedding] || []
    local_path = :td_ai |> Application.get_env(:model_path) |> Path.join(model_name)

    with {:ok, model} <- Bumblebee.load_model({:local, local_path}),
         {:ok, tokenizer} <- Bumblebee.load_tokenizer({:local, local_path}) do
      Bumblebee.Text.text_embedding(model, tokenizer, embedding_opts)
    end
  end

  def all(texts, index_type) do
    [enabled: true, index_type: index_type]
    |> Indices.list_indices()
    |> Enum.map(fn %Indices.Index{collection_name: collection_name} ->
      generate_vector(texts, index_type, collection_name)
    end)
    |> Enum.reject(&(&1 == :noop))
    |> Map.new()
  end

  def generate_vector(text, index_type, collection_name \\ nil)

  def generate_vector(text, _index_type, collection_name) when is_binary(collection_name) do
    worker = String.to_existing_atom(collection_name)

    if ServingSupervisor.exists?(worker) do
      {collection_name, predict(worker, text)}
    else
      :noop
    end
  end

  def generate_vector(text, index_type, nil) do
    case Indices.first_enabled(index_type: index_type) do
      %Indices.Index{collection_name: collection_name} ->
        generate_vector(text, index_type, collection_name)

      nil ->
        :noop
    end
  end

  defp predict(name, texts) do
    texts = normalize(texts)

    name
    |> Nx.Serving.batched_run(texts)
    |> then(fn
      embeddings when is_list(embeddings) ->
        Enum.map(embeddings, fn %{embedding: tensor} -> Nx.to_flat_list(tensor) end)

      %{embedding: tensor} ->
        Nx.to_flat_list(tensor)
    end)
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
