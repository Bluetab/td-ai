defmodule TdAiWeb.KnowledgeControllerTest do
  use Oban.Testing, repo: TdAi.Repo, prefix: Application.get_env(:td_ai, Oban)[:prefix]
  use TdAiWeb.ConnCase

  import Mox

  alias TdAi.Knowledges
  alias TdAi.Knowledges.KnowledgeProcessor
  alias TdCore.Utils.FileHash

  setup :verify_on_exit!
  setup :set_mox_from_context

  @moduletag sandbox: :shared
  @tmp_dir Application.compile_env(:td_ai, TdAi.Knowledges)[:uploads_tmp_folder]
  @file "test/fixtures/art03.pdf"

  setup_all do
    on_exit(fn -> File.rm_rf(@tmp_dir) end)
    :ok
  end

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    @tag authentication: [role: "admin"]
    test "lists all knowledge", %{conn: conn} do
      %{id: id} = insert(:knowledge)

      assert %{"data" => data} =
               conn
               |> get(~p"/api/knowledges")
               |> json_response(200)

      assert [%{"id" => ^id}] = data
    end

    @tag authentication: [role: "non_admin"]
    test "non admin cannot list knowledge", %{conn: conn} do
      assert conn
             |> get(~p"/api/knowledges")
             |> json_response(403)
    end
  end

  describe "create" do
    @tag authentication: [role: "admin"]
    test "return 422 when no indices enabled", %{conn: conn} do
      file = "test/fixtures/art03.pdf"

      assert %{"error" => error} =
               conn
               |> post(~p"/api/knowledges", %{
                 "files" => [upload(file)],
                 "names" => "upload name",
                 "descriptions" => "upload description"
               })
               |> json_response(422)

      assert error == "No indices enabled"
    end

    @tag authentication: [role: "admin"]
    test "creates a knowledge", %{conn: conn} do
      insert(:index, enabled_at: DateTime.utc_now(), index_type: "rag")
      file = "test/fixtures/art03.pdf"
      hash = FileHash.hash(file, :md5)

      ElasticsearchMock
      |> expect(:request, fn _, :get, "/knowledge", "", [] ->
        {:ok, %{"knowledge" => %{}}}
      end)

      ElasticsearchMock
      |> expect(:request, fn _, :post, "/knowledge/_bulk", _body, [] ->
        {:ok,
         %{
           "errors" => false,
           "took" => 10,
           "items" => [%{"index" => %{"_id" => "1", "result" => "created"}}]
         }}
      end)

      description = "upload description"
      name = "upload name"

      assert %{"data" => data} =
               conn
               |> post(~p"/api/knowledges", %{
                 "files" => [upload(file)],
                 "names" => [name],
                 "descriptions" => [description]
               })
               |> json_response(202)

      [%{"knowledge" => %{"id" => id}}] = data
      tmp_path = @tmp_dir <> "#{hash}"

      assert_enqueued(
        worker: KnowledgeProcessor,
        args: %{
          "filename" => "art03.pdf",
          "md5" => hash,
          "path" => tmp_path,
          "description" => description,
          "name" => name,
          "id_knowledge" => id
        },
        queue: "knowledge_queue"
      )

      assert {:ok, _} =
               perform_job(
                 KnowledgeProcessor,
                 %{
                   "filename" => "art03.pdf",
                   "md5" => hash,
                   "path" => tmp_path,
                   "id_knowledge" => id
                 }
               )

      assert [
               %{
                 "knowledge" => %{
                   "id" => id,
                   "description" => ^description,
                   "name" => ^name,
                   "md5" => ^hash,
                   "status" => "awaiting"
                 }
               }
             ] =
               data

      assert %{status: "completed"} = Knowledges.get_knowledge(id)
    end

    @tag authentication: [role: "non_admin"]
    test "non admin cannot create knowledge", %{conn: conn} do
      assert conn
             |> post(~p"/api/knowledges", %{
               "files" => [upload("test/fixtures/art03.pdf")],
               "names" => ["upload name"],
               "descriptions" => ["upload description"]
             })
             |> json_response(403)
    end
  end

  describe "show" do
    @tag authentication: [role: "admin"]
    test "shows a knowledge", %{conn: conn} do
      %{id: id} = insert(:knowledge)

      assert %{"data" => data} =
               conn
               |> get(~p"/api/knowledges/#{id}")
               |> json_response(200)

      assert %{"id" => ^id} = data
    end

    @tag authentication: [role: "non_admin"]
    test "non admin cannot show knowledge", %{conn: conn} do
      assert conn
             |> get(~p"/api/knowledges/#{1}")
             |> json_response(403)
    end
  end

  describe "update" do
    @tag authentication: [role: "admin"]
    test "updates a knowledge", %{conn: conn} do
      %{id: id} = insert(:knowledge)

      new_name = "new name"
      new_description = "new description"
      status = "processing"

      assert %{"data" => data} =
               conn
               |> put(~p"/api/knowledges/#{id}", %{
                 name: new_name,
                 description: new_description,
                 status: status
               })
               |> json_response(200)

      assert %{
               "id" => ^id,
               "name" => ^new_name,
               "description" => ^new_description,
               "status" => ^status
             } = data
    end

    @tag authentication: [role: "non_admin"]
    test "non admin cannot update knowledge", %{conn: conn} do
      assert conn
             |> put(~p"/api/knowledges/#{1}", %{name: "new name"})
             |> json_response(403)
    end
  end

  describe "update_file" do
    @tag authentication: [role: "admin"]
    test "updates a knowledge file", %{conn: conn} do
      %{id: id_knowledge, description: description, name: name} = insert(:knowledge)
      insert(:index, enabled_at: DateTime.utc_now(), index_type: "rag")
      hash = FileHash.hash("test/fixtures/art03.pdf", :md5)

      ElasticsearchMock
      |> expect(:request, fn _, :get, "/knowledge", "", [] ->
        {:ok, %{"knowledge" => %{}}}
      end)

      ElasticsearchMock
      |> expect(:request, fn _, :post, "/knowledge/_delete_by_query", body, [] ->
        assert body == %{"query" => %{"term" => %{"md5.keyword" => "some md5"}}}

        {:ok, :ok}
      end)

      ElasticsearchMock
      |> expect(:request, fn _, :get, "/knowledge", "", [] ->
        {:ok, %{"knowledge" => %{}}}
      end)

      ElasticsearchMock
      |> expect(:request, fn _, :post, "/knowledge/_bulk", _body, [] ->
        {:ok,
         %{
           "errors" => false,
           "took" => 10,
           "items" => [%{"index" => %{"_id" => "1", "result" => "created"}}]
         }}
      end)

      tmp_path = @tmp_dir <> "#{hash}"

      assert %{"data" => data} =
               conn
               |> put(~p"/api/knowledges/#{id_knowledge}/file", %{
                 file: upload("test/fixtures/art03.pdf")
               })
               |> json_response(202)

      assert_enqueued(
        worker: KnowledgeProcessor,
        args: %{
          "filename" => "art03.pdf",
          "md5" => hash,
          "path" => tmp_path,
          "description" => description,
          "name" => name,
          "id_knowledge" => id_knowledge
        },
        queue: "knowledge_queue"
      )

      assert {:ok, _} =
               perform_job(
                 KnowledgeProcessor,
                 %{
                   "filename" => "art03.pdf",
                   "md5" => hash,
                   "path" => tmp_path,
                   "id_knowledge" => id_knowledge
                 }
               )

      assert %{"knowledge" => %{"id" => ^id_knowledge, "md5" => ^hash, "status" => "awaiting"}} =
               data

      assert %{status: "completed"} = Knowledges.get_knowledge(id_knowledge)
    end

    @tag authentication: [role: "non_admin"]
    test "non admin cannot update knowledge file", %{conn: conn} do
      assert conn
             |> put(~p"/api/knowledges/#{1}/file", %{file: upload("test/fixtures/art03.pdf")})
             |> json_response(403)
    end
  end
end
