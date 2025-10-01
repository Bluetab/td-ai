defmodule TdAi.IndicesTest do
  use TdAi.DataCase

  alias TdAi.Indices

  describe "indices" do
    alias TdAi.Indices.Index

    @invalid_attrs %{
      collection_name: nil,
      embedding: nil,
      mapping: nil,
      index_type: nil,
      metric_type: nil
    }

    test "list_indices/0 returns all indices" do
      index = insert(:index)
      assert Indices.list_indices() == [index]
    end

    test "get_index!/1 returns the index with given id" do
      index = insert(:index)
      assert Indices.get_index!(index.id) == index
    end

    test "create_index/1 with valid data creates a index" do
      valid_attrs = %{
        collection_name: "some collection_name",
        embedding: "some embedding",
        mapping: ["option1", "option2"],
        index_type: "some index_type",
        metric_type: "some metric_type"
      }

      assert {:ok, %Index{} = index} = Indices.create_index(valid_attrs)
      assert index.collection_name == "some collection_name"
      assert index.embedding == "some embedding"
      assert index.mapping == ["option1", "option2"]
      assert index.index_type == "some index_type"
      assert index.metric_type == "some metric_type"
    end

    test "create_index/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Indices.create_index(@invalid_attrs)
    end

    test "update_index/2 with valid data updates the index" do
      index = insert(:index)

      update_attrs = %{
        collection_name: "some updated collection_name",
        embedding: "some updated embedding",
        mapping: ["option1"],
        index_type: "some updated index_type",
        metric_type: "some updated metric_type"
      }

      assert {:ok, %Index{} = index} = Indices.update_index(index, update_attrs)
      assert index.collection_name == "some updated collection_name"
      assert index.embedding == "some updated embedding"
      assert index.mapping == ["option1"]
      assert index.index_type == "some updated index_type"
      assert index.metric_type == "some updated metric_type"
    end

    test "update_index/2 with invalid data returns error changeset" do
      index = insert(:index)
      assert {:error, %Ecto.Changeset{}} = Indices.update_index(index, @invalid_attrs)
      assert index == Indices.get_index!(index.id)
    end

    test "delete_index/1 deletes the index" do
      index = insert(:index)
      assert {:ok, %Index{}} = Indices.delete_index(index)
      assert_raise Ecto.NoResultsError, fn -> Indices.get_index!(index.id) end
    end
  end

  describe "enable/1" do
    test "sets enabled_at to current datetime" do
      index = insert(:index, enabled_at: nil)

      assert index.enabled_at == nil

      {:ok, enabled_index} = Indices.enable(index)

      assert enabled_index.enabled_at != nil
      assert %DateTime{} = enabled_index.enabled_at
    end

    test "doesn't set enabled_at to current datetime" do
      index = insert(:index, enabled_at: DateTime.add(DateTime.utc_now(), -1, :day))
      {:ok, noop_index} = Indices.enable(index)

      assert noop_index.enabled_at == index.enabled_at
    end
  end

  describe "disable/1" do
    test "sets enabled_at to nil" do
      # Insert an index already enabled
      index = insert(:index, enabled_at: DateTime.utc_now())

      {:ok, disabled_index} = Indices.disable(index)
      assert disabled_index.enabled_at == nil
    end

    test "doesn't set enabled_at to nil when already disabled" do
      index = insert(:index, enabled_at: nil)

      {:ok, disabled_index} = Indices.disable(index)
      assert disabled_index.enabled_at == nil
    end
  end

  describe "list_indices/1" do
    test "lists enabled indices" do
      enabled = insert(:index, enabled_at: DateTime.utc_now())
      disabled = insert(:index, enabled_at: nil)
      assert [index] = Indices.list_indices(enabled: true)
      assert index == enabled

      assert [index] = Indices.list_indices(enabled: false)
      assert index == disabled

      assert indices = Indices.list_indices()
      assert Enum.count(indices) == 2
    end
  end

  describe "exists_enabled?" do
    test "checks if there are enabled indices" do
      insert(:index, enabled_at: nil)
      refute Indices.exists_enabled?()

      insert(:index, enabled_at: DateTime.utc_now())
      assert Indices.exists_enabled?()
    end
  end
end
