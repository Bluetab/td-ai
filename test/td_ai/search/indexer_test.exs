defmodule TdAi.Search.IndexerTest do
  use ExUnit.Case
  use TdAi.DataCase

  import Mox

  alias SearchHelpers
  alias TdAi.Knowledges.KnowledgeChunk
  alias TdAi.Search.Indexer
  alias TdCluster.TestHelpers.TdAiMock.Indices

  setup :verify_on_exit!
  setup :set_mox_from_context

  @test_document %KnowledgeChunk{
    chunk_id: "chunk_123",
    text: "Test content",
    embedding: [0.1, 0.2, 0.3],
    filename: "test.pdf",
    md5: "1234567890",
    format: "pdf",
    page: 1
  }

  @test_documents [
    %KnowledgeChunk{chunk_id: "chunk_1", text: "Content 1", embedding: [0.1, 0.2]},
    %KnowledgeChunk{chunk_id: "chunk_2", text: "Content 2", embedding: [0.3, 0.4]}
  ]

  describe "index_document/2" do
    test "successfully indexes a single document" do
      ElasticsearchMock
      |> expect(:request, fn _, :get, "/knowledge", "", [] ->
        {:ok, %{"knowledge" => %{}}}
      end)

      ElasticsearchMock
      |> expect(:request, fn _, :post, "/knowledge/_bulk", body, [] ->
        assert body =~ "chunk_123"
        assert body =~ "Test content"

        {:ok,
         %{
           "errors" => false,
           "took" => 10,
           "items" => [%{"index" => %{"_id" => "chunk_123", "result" => "created"}}]
         }}
      end)

      assert :ok = Indexer.index_document(@test_document)
    end

    test "creates index if it doesn't exist" do
      insert(:index,
        index_type: "rag",
        collection_name: "knowledge",
        enabled_at: DateTime.utc_now()
      )

      # Mock index doesn't exist
      ElasticsearchMock
      |> expect(:request, fn _, :get, "/knowledge", _, [] ->
        {:error, %{status: 404}}
      end)

      Indices.list_indices(
        &Mox.expect/4,
        [index_type: "rag", enabled: true],
        {:ok, []}
      )

      # Mock index creation
      ElasticsearchMock
      |> expect(:request, fn _, :put, "/knowledge", index_body, [] ->
        assert is_map(index_body)
        {:ok, %{"acknowledged" => true}}
      end)

      ElasticsearchMock
      |> expect(:request, fn _, :post, "/knowledge/_bulk", body, [] ->
        assert body =~ "chunk_123"
        assert body =~ "Test content"

        {:ok,
         %{
           "errors" => false,
           "took" => 10,
           "items" => [%{"index" => %{"_id" => "chunk_123", "result" => "created"}}]
         }}
      end)

      assert :ok = Indexer.index_document(@test_document)
    end
  end

  describe "index_documents_batch/2" do
    test "successfully indexes multiple documents" do
      ElasticsearchMock
      |> expect(:request, fn _, :get, "/knowledge", _, [] ->
        {:ok, %{"knowledge" => %{}}}
      end)

      ElasticsearchMock
      |> expect(:request, fn _, :post, "/knowledge/_bulk", bulk_data, [] ->
        # Verify bulk data format
        assert is_binary(bulk_data)
        assert bulk_data =~ "chunk_1"
        assert bulk_data =~ "chunk_2"
        {:ok, %{"errors" => false, "took" => 10, "items" => []}}
      end)

      assert :ok = Indexer.index_documents_batch(@test_documents)
    end

    test "creates index if it doesn't exist" do
      insert(:index,
        index_type: "rag",
        collection_name: "knowledge",
        enabled_at: DateTime.utc_now()
      )

      ElasticsearchMock
      |> expect(:request, fn _, :get, "/knowledge", _, [] ->
        {:error, %{status: 404}}
      end)

      Indices.list_indices(
        &Mox.expect/4,
        [index_type: "rag", enabled: true],
        {:ok, []}
      )

      ElasticsearchMock
      |> expect(:request, fn _, :put, "/knowledge", index_body, [] ->
        assert is_map(index_body)
        {:ok, %{"acknowledged" => true}}
      end)

      ElasticsearchMock
      |> expect(:request, fn _, :post, "/knowledge/_bulk", _, [] ->
        {:ok, %{"errors" => false, "took" => 10, "items" => []}}
      end)

      assert :ok = Indexer.index_documents_batch(@test_documents)
    end

    test "handles empty document list" do
      ElasticsearchMock
      |> expect(:request, fn _, :get, "/knowledge", _, [] ->
        {:ok, %{"knowledge" => %{}}}
      end)

      assert :ok = Indexer.index_documents_batch([])
    end

    test "uses correct bulk page size from configuration" do
      ElasticsearchMock
      |> expect(:request, fn _, :get, "/knowledge", _, [] ->
        {:ok, %{"knowledge" => %{}}}
      end)

      ElasticsearchMock
      |> expect(:request, fn _, :post, "/knowledge/_bulk", bulk_data, [] ->
        lines = String.split(bulk_data, "\n") |> Enum.reject(&(&1 == ""))

        assert length(lines) == 4
        {:ok, %{"errors" => false, "took" => 10, "items" => []}}
      end)

      assert :ok = Indexer.index_documents_batch(@test_documents)
    end
  end
end
