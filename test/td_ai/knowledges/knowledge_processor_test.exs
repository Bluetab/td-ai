defmodule TdAi.Knowledges.KnowledgeProcessorTest do
  use Oban.Testing, repo: TdAi.Repo, prefix: Application.get_env(:td_ai, Oban)[:prefix]
  use TdAi.DataCase

  import Mox

  alias TdAi.FileHelper
  alias TdAi.Knowledges
  alias TdAi.Knowledges.KnowledgeProcessor
  alias TdCore.Utils.FileHash

  setup :verify_on_exit!
  setup :set_mox_from_context

  @moduletag sandbox: :shared

  describe "TdAi.Knowledges.KnowledgeProcessor.perform/1" do
    setup %{test_pid: test_pid} do
      FileHelper.load_file("test/fixtures/art03.pdf", test_pid)
    end

    test "successfully processes a knowledge file", %{tmp_path: tmp_path, file_name: file_name} do
      insert(:index, index_type: "rag", enabled_at: DateTime.utc_now())
      md5 = FileHash.hash(tmp_path, :md5)
      %{id: id_knowledge} = insert(:knowledge, md5: md5)

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

      assert {:ok, _} =
               perform_job(
                 KnowledgeProcessor,
                 %{
                   "filename" => file_name,
                   "md5" => md5,
                   "path" => tmp_path,
                   "id_knowledge" => id_knowledge
                 }
               )

      assert %{status: "completed"} = Knowledges.get_knowledge(id_knowledge)
    end
  end
end
