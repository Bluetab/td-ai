defmodule TdAi.IndicesTest do
  use TdAi.DataCase

  alias TdAi.Indices

  describe "indices" do
    alias TdAi.Indices.Index

    import TdAi.IndicesFixtures

    @invalid_attrs %{collection_name: nil, embedding: nil, mapping: nil}

    test "list_indices/0 returns all indices" do
      index = index_fixture()
      assert Indices.list_indices() == [index]
    end

    test "get_index!/1 returns the index with given id" do
      index = index_fixture()
      assert Indices.get_index!(index.id) == index
    end

    test "create_index/1 with valid data creates a index" do
      valid_attrs = %{collection_name: "some collection_name", embedding: "some embedding", mapping: ["option1", "option2"]}

      assert {:ok, %Index{} = index} = Indices.create_index(valid_attrs)
      assert index.collection_name == "some collection_name"
      assert index.embedding == "some embedding"
      assert index.mapping == ["option1", "option2"]
    end

    test "create_index/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Indices.create_index(@invalid_attrs)
    end

    test "update_index/2 with valid data updates the index" do
      index = index_fixture()
      update_attrs = %{collection_name: "some updated collection_name", embedding: "some updated embedding", mapping: ["option1"]}

      assert {:ok, %Index{} = index} = Indices.update_index(index, update_attrs)
      assert index.collection_name == "some updated collection_name"
      assert index.embedding == "some updated embedding"
      assert index.mapping == ["option1"]
    end

    test "update_index/2 with invalid data returns error changeset" do
      index = index_fixture()
      assert {:error, %Ecto.Changeset{}} = Indices.update_index(index, @invalid_attrs)
      assert index == Indices.get_index!(index.id)
    end

    test "delete_index/1 deletes the index" do
      index = index_fixture()
      assert {:ok, %Index{}} = Indices.delete_index(index)
      assert_raise Ecto.NoResultsError, fn -> Indices.get_index!(index.id) end
    end

    test "change_index/1 returns a index changeset" do
      index = index_fixture()
      assert %Ecto.Changeset{} = Indices.change_index(index)
    end
  end
end
