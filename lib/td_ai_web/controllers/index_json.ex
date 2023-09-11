defmodule TdAiWeb.IndexJSON do
  alias TdAi.Indices.Index

  @doc """
  Renders a list of indices.
  """
  def index(%{indices: indices}) do
    %{data: for(index <- indices, do: data(index))}
  end

  @doc """
  Renders a single index.
  """
  def show(%{index: index}) do
    %{data: data(index)}
  end

  defp data(%Index{} = index) do
    %{
      id: index.id,
      collection_name: index.collection_name,
      embedding: index.embedding,
      mapping: index.mapping,
      metric_type: index.metric_type,
      index_type: index.index_type,
      index_params: index.index_params
    }
  end
end
