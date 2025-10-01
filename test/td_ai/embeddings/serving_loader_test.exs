defmodule TdAi.Embeddings.ServingLoaderTest do
  use TdAi.DataCase, async: false

  import Mox

  alias TdAi.Embeddings.ServingLoader
  alias TdAi.Embeddings.ServingSupervisor

  setup :verify_on_exit!
  setup :set_mox_from_context

  setup do
    # restart the GenServer fresh
    start_supervised!(ServingSupervisor)
    :ok
  end

  describe "do_add_servings" do
    test "creates processes dinamically from enabled indices" do
      service_name1 = :name1
      service_name2 = :name2
      insert(:index, enabled_at: nil)
      insert(:index, collection_name: "#{service_name1}", enabled_at: DateTime.utc_now())
      insert(:index, collection_name: "#{service_name2}", enabled_at: DateTime.utc_now())

      Mox.expect(TdAi.Embeddings.Mock, :load_local_serving, 2, fn _model, _config ->
        Nx.Serving.new(fn opts -> Nx.Defn.jit(fn x -> x end, opts) end)
      end)

      assert :ok == ServingLoader.do_add_servings()
      assert GenServer.whereis(service_name1)
      assert GenServer.whereis(service_name2)
    end
  end

  describe "do_add_serving" do
    test "adds serving" do
      service_name1 = :name1

      Mox.expect(TdAi.Embeddings.Mock, :load_local_serving, 1, fn _model, _config ->
        Nx.Serving.new(fn opts -> Nx.Defn.jit(fn x -> x end, opts) end)
      end)

      index = insert(:index, collection_name: "#{service_name1}", enabled_at: DateTime.utc_now())
      assert :ok == ServingLoader.do_add_serving(index)
      assert GenServer.whereis(service_name1)
    end
  end

  describe "do_remove_serving" do
    test "removes serving" do
      service_name1 = :name1

      Mox.expect(TdAi.Embeddings.Mock, :load_local_serving, 1, fn _model, _config ->
        Nx.Serving.new(fn opts -> Nx.Defn.jit(fn x -> x end, opts) end)
      end)

      index = insert(:index, collection_name: "#{service_name1}", enabled_at: DateTime.utc_now())
      assert :ok == ServingLoader.do_add_serving(index)
      assert GenServer.whereis(service_name1)

      assert :ok == ServingLoader.do_remove_serving(index)
      refute GenServer.whereis(service_name1)
    end
  end
end
