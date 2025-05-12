defmodule TdAi.Embeddings.ServerTest do
  use TdAi.DataCase, async: false

  import ExUnit.CaptureLog
  import Mox

  alias TdAi.Embeddings.Server

  setup :verify_on_exit!
  setup :set_mox_from_context

  setup do
    # restart the GenServer fresh
    start_supervised!(Server)
    :ok
  end

  describe "get_servings/0" do
    test "returns empty map on init" do
      assert Server.get_servings() == %{}
    end
  end

  describe "add_serving/1 and get_serving/1" do
    test "adds a serving from index" do
      index = %{collection_name: "my_index", embedding: "test-model"}
      serving = Nx.Serving.new(fn opts -> Nx.Defn.jit(fn x -> x end, opts) end)
      # Expect model loading to succeed
      expect(TdAi.Embeddings.Mock, :load_local_serving, 2, fn _model, _config ->
        serving
      end)

      Server.add_serving(index)

      assert Server.get_serving("my_index") == %{single: serving, multiple: serving}
    end

    test "does not add serving if loading fails" do
      index = %{collection_name: "bad", embedding: "fail-model"}

      assert capture_log(fn ->
               expect(TdAi.Embeddings.Mock, :load_local_serving, fn _, _ ->
                 {:error, "message"}
               end)

               Server.add_serving(index)
               assert Server.get_serving("bad") == nil
             end) =~ "message"
    end
  end

  describe "remove_serving/1" do
    test "removes an existing serving" do
      expect(TdAi.Embeddings.Mock, :load_local_serving, 2, fn _, _ ->
        Nx.Serving.new(fn opts -> Nx.Defn.jit(fn x -> x end, opts) end)
      end)

      Server.add_serving(%{collection_name: "to_remove", embedding: "x"})

      assert Server.get_serving("to_remove") != nil

      Server.remove_serving(%{collection_name: "to_remove"})

      assert Server.get_serving("to_remove") == nil
    end
  end

  describe "refresh/0" do
    test "loads enabled indices on refresh" do
      insert(:index, collection_name: "col1", enabled_at: DateTime.utc_now())
      insert(:index, collection_name: "col2", enabled_at: nil)

      serving = Nx.Serving.new(fn opts -> Nx.Defn.jit(fn x -> x end, opts) end)

      expect(TdAi.Embeddings.Mock, :load_local_serving, 2, fn _, _ -> serving end)

      Server.refresh()

      assert Server.get_servings() == %{"col1" => %{single: serving, multiple: serving}}
    end
  end
end
