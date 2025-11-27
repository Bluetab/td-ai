defmodule TdAi.KnowledgesTest do
  use Oban.Testing, repo: TdAi.Repo, prefix: Application.get_env(:td_ai, Oban)[:prefix]
  use TdAi.DataCase

  import Mox

  alias TdAi.Knowledges
  alias TdAi.Knowledges.Knowledge
  alias TdAi.Repo
  alias TdCore.Search.IndexWorkerMock
  alias TdCore.Utils.FileHash

  setup :verify_on_exit!
  setup :set_mox_from_context

  @moduletag sandbox: :shared
  @tmp_dir Application.compile_env(:td_ai, TdAi.Knowledges)[:uploads_tmp_folder]
  @file_path "test/fixtures/art03.pdf"
  @file_name Path.basename(@file_path)

  setup do
    Mox.set_mox_global()

    start_supervised!(IndexWorkerMock)
    IndexWorkerMock.clear()

    on_exit(fn -> File.rm_rf(@tmp_dir) end)
    :ok
  end

  describe "create_knowledges/1" do
    test "creates knowledge record and enqueues processing job" do
      upload = %Plug.Upload{path: @file_path, filename: @file_name}

      assert {:ok, [{db_knowledge, _job}]} =
               Knowledges.create_knowledges([{upload, "My knowledge", "Knowledge description"}])

      assert %Knowledge{} = db_knowledge
      assert db_knowledge.filename == @file_name
      assert String.length(db_knowledge.md5) == 32

      assert_enqueued(
        worker: TdAi.Knowledges.KnowledgeProcessor,
        args: %{"md5" => db_knowledge.md5}
      )
    end

    test "creating a knowledge when md5 already exists (non-failed)" do
      md5 = FileHash.hash(@file_path, :md5)
      _existing = insert(:knowledge, md5: md5, status: "awaiting")

      upload = %Plug.Upload{path: @file_path, filename: @file_name}

      assert {:error, :conflict, msg} = Knowledges.create_knowledges([{upload, "name", "desc"}])
      assert is_binary(msg)
      assert String.contains?(msg, md5)
    end

    test "creating a knowledge with existing md5 in status failed updates it and enqueues job" do
      md5 = FileHash.hash(@file_path, :md5)
      existing = insert(:knowledge, md5: md5, status: "failed")

      ElasticsearchMock
      |> expect(:request, fn _, :get, "/knowledge", "", [] ->
        {:ok, %{"knowledge" => %{}}}
      end)

      ElasticsearchMock
      |> expect(:request, fn _, :post, "/knowledge/_delete_by_query", _body, [] ->
        {:ok, :ok}
      end)

      upload = %Plug.Upload{path: @file_path, filename: @file_name}

      assert {:ok, [{db_knowledge, _job}]} =
               Knowledges.create_knowledges([{upload, "name", "desc"}])

      assert db_knowledge.id == existing.id
      assert db_knowledge.status == "awaiting"

      assert_enqueued(
        worker: TdAi.Knowledges.KnowledgeProcessor,
        args: %{"md5" => db_knowledge.md5}
      )
    end

    test "creating fails if temporary file already exists (file is being processed)" do
      md5 = FileHash.hash(@file_path, :md5)
      tmp_path = Path.join(@tmp_dir, md5)
      File.mkdir_p!(@tmp_dir)
      File.write!(tmp_path, "locked")

      upload = %Plug.Upload{path: @file_path, filename: @file_name}

      assert {:error, :conflict, "File is already being processed"} =
               Knowledges.create_knowledges([{upload, "name", "desc"}])
    end
  end

  describe "update_knowledge_file/2" do
    test "update deletes elasticsearch chunks and enqueues job" do
      knowledge = insert(:knowledge, md5: String.duplicate("a", 32))

      ElasticsearchMock
      |> expect(:request, fn _, :get, "/knowledge", "", [] ->
        {:ok, %{"knowledge" => %{}}}
      end)

      ElasticsearchMock
      |> expect(:request, fn _, :post, "/knowledge/_delete_by_query", body, [] ->
        assert body == %{"query" => %{"term" => %{"md5.keyword" => String.duplicate("a", 32)}}}

        {:ok, :ok}
      end)

      upload = %Plug.Upload{path: @file_path, filename: @file_name}

      assert {:ok, {updated, _job}} = Knowledges.update_knowledge_file(knowledge, upload)

      assert updated.md5 != knowledge.md5
      assert_enqueued(worker: TdAi.Knowledges.KnowledgeProcessor, args: %{"md5" => updated.md5})
    end

    test "updating a knowledge with a file whose md5 already exists (non-failed)" do
      target = insert(:knowledge, md5: String.duplicate("x", 32))
      existing_md5 = FileHash.hash(@file_path, :md5)
      _other = insert(:knowledge, md5: existing_md5, status: "awaiting")

      ElasticsearchMock
      |> expect(:request, fn _, :get, "/knowledge", "", [] ->
        {:ok, %{"knowledge" => %{}}}
      end)

      ElasticsearchMock
      |> expect(:request, fn _, :post, "/knowledge/_delete_by_query", _body, [] ->
        {:ok, :ok}
      end)

      upload = %Plug.Upload{path: @file_path, filename: @file_name}

      assert {:error, :conflict, msg} = Knowledges.update_knowledge_file(target, upload)
      assert is_binary(msg)
      assert String.contains?(msg, existing_md5)
    end

    test "updating fails if temporary file already exists (file is being processed)" do
      md5 = FileHash.hash(@file_path, :md5)
      tmp_path = Path.join(@tmp_dir, md5)
      File.mkdir_p!(@tmp_dir)
      File.write!(tmp_path, "locked")

      upload = %Plug.Upload{path: @file_path, filename: @file_name}

      existing = insert(:knowledge, md5: String.duplicate("z", 32))

      assert {:error, :conflict, "File is already being processed"} =
               Knowledges.update_knowledge_file(existing, upload)
    end
  end

  describe "list_knowledges/0" do
    test "returns inserted knowledges" do
      knowledge_1 =
        insert(:knowledge, name: "one", filename: "one.pdf", md5: String.duplicate("a", 32))

      knowledge_2 =
        insert(:knowledge, name: "two", filename: "two.pdf", md5: String.duplicate("b", 32))

      list = Knowledges.list_knowledges()
      assert length(list) == 2
      assert Enum.any?(list, &(&1.id == knowledge_1.id))
      assert Enum.any?(list, &(&1.id == knowledge_2.id))
    end
  end

  describe "get_knowledge/1" do
    test "get_knowledge/1 returns nil for missing and get_knowledge!/1 raises" do
      assert Knowledges.get_knowledge(-1) == nil

      assert_raise Ecto.NoResultsError, fn -> Knowledges.get_knowledge!(-1) end
    end

    test "returns existing knowledge" do
      knowledge = insert(:knowledge)

      assert Knowledges.get_knowledge(knowledge.id).id == knowledge.id
      assert Knowledges.get_knowledge!(knowledge.id).id == knowledge.id
    end
  end

  describe "get_knowledge_by_md5/1" do
    test "returns knowledge by md5" do
      md5 = String.duplicate("m", 32)
      knowledge = insert(:knowledge, md5: md5)

      assert Knowledges.get_knowledge_by_md5(md5).id == knowledge.id
    end
  end

  describe "update_knowledge/2" do
    test "updates a knowledge changeset" do
      knowledge =
        insert(:knowledge,
          name: "up",
          filename: "up.txt",
          format: "txt",
          md5: String.duplicate("u", 32)
        )

      {:ok, updated} = Knowledges.update_knowledge(knowledge, %{name: "updated"})
      assert updated.name == "updated"
    end
  end

  describe "delete_knowledge/1" do
    test "calls indexer and deletes record" do
      knowledge =
        insert(:knowledge,
          name: "up",
          filename: "up.txt",
          format: "txt",
          md5: String.duplicate("a", 32)
        )

      ElasticsearchMock
      |> expect(:request, fn _, :get, "/knowledge", "", [] ->
        {:ok, %{"knowledge" => %{}}}
      end)

      ElasticsearchMock
      |> expect(:request, fn _, :post, "/knowledge/_delete_by_query", body, [] ->
        assert body == %{"query" => %{"term" => %{"md5.keyword" => String.duplicate("a", 32)}}}

        {:ok, :ok}
      end)

      assert :ok = Knowledges.delete_knowledge(knowledge)

      assert Repo.get(Knowledge, knowledge.id) == nil
    end
  end
end
