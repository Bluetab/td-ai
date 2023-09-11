defmodule TdAiWeb.IndexControllerTest do
  use TdAiWeb.ConnCase

  import TdAi.IndicesFixtures

  alias TdAi.Indices.Index

  @create_attrs %{
    collection_name: "some collection_name",
    embedding: "some embedding",
    mapping: ["option1", "option2"]
  }
  @update_attrs %{
    collection_name: "some updated collection_name",
    embedding: "some updated embedding",
    mapping: ["option1"]
  }
  @invalid_attrs %{collection_name: nil, embedding: nil, mapping: nil}

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "lists all indices", %{conn: conn} do
      conn = get(conn, ~p"/api/indices")
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create index" do
    test "renders index when data is valid", %{conn: conn} do
      conn = post(conn, ~p"/api/indices", index: @create_attrs)
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, ~p"/api/indices/#{id}")

      assert %{
               "id" => ^id,
               "collection_name" => "some collection_name",
               "embedding" => "some embedding",
               "mapping" => ["option1", "option2"]
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/api/indices", index: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update index" do
    setup [:create_index]

    test "renders index when data is valid", %{conn: conn, index: %Index{id: id} = index} do
      conn = put(conn, ~p"/api/indices/#{index}", index: @update_attrs)
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(conn, ~p"/api/indices/#{id}")

      assert %{
               "id" => ^id,
               "collection_name" => "some updated collection_name",
               "embedding" => "some updated embedding",
               "mapping" => ["option1"]
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn, index: index} do
      conn = put(conn, ~p"/api/indices/#{index}", index: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete index" do
    setup [:create_index]

    test "deletes chosen index", %{conn: conn, index: index} do
      conn = delete(conn, ~p"/api/indices/#{index}")
      assert response(conn, 204)

      assert_error_sent 404, fn ->
        get(conn, ~p"/api/indices/#{index}")
      end
    end
  end

  defp create_index(_) do
    index = index_fixture()
    %{index: index}
  end
end
