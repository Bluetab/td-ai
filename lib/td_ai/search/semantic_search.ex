defmodule TdAi.Search.SemanticSearch do
  @moduledoc """
  Module for performing semantic search on the knowledge base.
  """

  alias TdAi.Embeddings
  alias TdAi.Indices
  alias TdCache.TaxonomyCache
  alias TdCore.Search.Cluster

  require Logger

  @index :knowledge

  @num_candidates Application.compile_env(:td_ai, [:semantic_search, :num_candidates], 200)
  @k Application.compile_env(:td_ai, [:semantic_search, :k], 20)
  @similarity Application.compile_env(:td_ai, [:semantic_search, :similarity], 0.30)
  @boost Application.compile_env(:td_ai, [:semantic_search, :boost], 1.0)
  @index_type "rag"

  def semantic_search(resource_body, domain_ids, opts \\ [])

  def semantic_search(%{"name" => name} = _resource_body, [domain_id], opts) do
    %{name: domain_name} = TaxonomyCache.get_domain(domain_id)

    # TODO TD-7302: Collect name should be passed as a parameter or get the first one
    case Indices.first_enabled(index_type: to_string(@index_type)) do
      nil ->
        {:ok, []}

      %{collection_name: collection_name} ->
        [name, domain_name]
        |> Enum.map(fn query ->
          do_semantic_search(query, collection_name, opts)
        end)
        |> List.flatten()
        |> then(&{:ok, &1})
    end
  end

  def semantic_search(_resource_body, _domain_ids, _opts), do: {:ok, []}

  def do_semantic_search(query, collection_type, opts) do
    k = Keyword.get(opts, :k, @k)
    similarity = Keyword.get(opts, :similarity, @similarity)
    num_candidates = Keyword.get(opts, :num_candidates, @num_candidates)

    with {:ok, query_embedding} <- generate_query_embedding(query, collection_type),
         {:ok, results} <-
           perform_knn_search(collection_type, query_embedding, k, similarity, num_candidates) do
      results
    else
      _ ->
        []
    end
  end

  defp generate_query_embedding(query, collection_type) do
    case Embeddings.generate_vector(query, @index_type, collection_type) do
      {_collection_name, embedding} when is_list(embedding) ->
        {:ok, embedding}

      :noop ->
        :noop
    end
  end

  ### TODO TD-7302: Add to core
  defp perform_knn_search(collection_type, query_embedding, k, similarity, num_candidates) do
    body =
      %{
        "knn" => %{
          "field" => "embeddings.vector_#{collection_type}",
          "query_vector" => query_embedding,
          "k" => k,
          "num_candidates" => num_candidates,
          "similarity" => similarity,
          "boost" => @boost
        }
      }

    case Elasticsearch.post(Cluster, "/#{@index}/_search", body) do
      {:ok, response} ->
        results = extract_search_results(response)

        {:ok, results}

      error ->
        Logger.error("Error performing knn search: #{inspect(error)}")
        :noop
    end
  end

  defp extract_search_results(response) do
    response
    |> Map.get("hits", %{})
    |> Map.get("hits", [])
    |> Enum.map(fn hit ->
      source = Map.get(hit, "_source", %{})
      score = Map.get(hit, "_score", 0.0)

      %{
        id: Map.get(hit, "_id"),
        score: score,
        text: Map.get(source, "text", ""),
        chunk_id: Map.get(source, "chunk_id", ""),
        filename: Map.get(source, "filename", ""),
        page: Map.get(source, "page", 0)
      }
    end)
  end
end
