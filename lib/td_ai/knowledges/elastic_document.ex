defmodule TdAi.Knowledges.ElasticDocument do
  @moduledoc """
  Elasticsearch document for knowledge
  """

  alias Elasticsearch.Document
  alias TdAi.Knowledges.KnowledgeChunk
  alias TdCore.Search.Cluster
  alias TdCore.Search.ElasticDocument
  alias TdCore.Search.ElasticDocumentProtocol

  defimpl Document, for: KnowledgeChunk do
    use ElasticDocument

    @impl Elasticsearch.Document
    def id(%KnowledgeChunk{id: id}), do: id

    @impl Elasticsearch.Document
    def routing(_), do: false

    @impl Elasticsearch.Document
    def encode(%KnowledgeChunk{embedding: embeddings} = chunk) do
      chunk
      |> Map.take([:text, :chunk_id, :filename, :md5, :format, :page])
      |> Map.put(:embeddings, embeddings)
    end
  end

  defimpl ElasticDocumentProtocol, for: KnowledgeChunk do
    use ElasticDocument

    def mappings(_) do
      properties =
        %{
          text: %{type: "text"},
          chunk_id: %{type: "integer"},
          filename: %{type: "keyword"},
          md5: %{type: "keyword"},
          format: %{type: "keyword"},
          page: %{type: "integer"},
          embeddings: %{properties: get_embedding_mappings("rag")}
        }

      settings = Cluster.setting(:knowledge)

      %{mappings: %{properties: properties}, settings: settings}
    end

    def query_data(_) do
      %{
        aggs: aggregations(nil)
      }
    end

    def aggregations(_), do: %{}
  end
end
