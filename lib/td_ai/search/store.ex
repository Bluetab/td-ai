defmodule TdAi.Search.Store do
  @moduledoc """
  Elasticsearch store implementation for Knowledge
  """

  @behaviour Elasticsearch.Store

  alias TdAi.Knowledges.KnowledgeChunk

  @impl true
  def stream(KnowledgeChunk = _schema) do
    Stream.map([], & &1)
  end

  @impl true
  def transaction(fun) do
    fun.()
  end

  def stream(KnowledgeChunk = _schema, _ids) do
    Stream.map([], & &1)
  end
end
