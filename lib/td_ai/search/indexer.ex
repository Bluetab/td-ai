defmodule TdAi.Search.Indexer do
  @moduledoc """
  Indexer for Knowledge.
  """

  alias TdCore.Search.IndexWorker

  require Logger

  @index :knowledge

  @doc """
  Index a single document directly to Elasticsearch (for RAG scenarios)
  """
  def index_document(document) do
    IndexWorker.index_document(@index, document)
  end

  @doc """
  Index multiple documents in batch (for RAG scenarios)
  """
  def index_documents_batch(documents) do
    Logger.info("Indexing #{length(documents)} documents for #{@index}")
    IndexWorker.index_documents_batch(@index, documents)
  end

  @doc """
  Delete index documents by query
  Example:
  TdAi.Search.Indexer.delete_index_documents_by_query(%{"md5.keyword" => "C0C2C04071B0C12AFE9745F6F9E83E9A"} )
  """

  def delete_index_documents_by_query(term) do
    query = %{"query" => %{"term" => term}}
    Logger.info("Deleting documents for #{@index} with query #{inspect(query)}")
    IndexWorker.delete_index_documents_by_query(@index, query)
  end
end
