defmodule TdAiWeb.IndexControllerTest do
  use TdAiWeb.ConnCase

  alias TdAi.Indices.Index
  alias TdAi.Repo

  @create_attrs %{
    collection_name: "some collection_name",
    embedding: "some embedding",
    mapping: ["option1", "option2"],
    index_type: "some index_type",
    metric_type: "some metric_type"
  }
  @update_attrs %{
    collection_name: "some updated collection_name",
    embedding: "some updated embedding",
    mapping: ["option1"],
    index_type: "some updated index_type",
    metric_type: "some updated metric_type"
  }
  @invalid_attrs %{collection_name: nil, embedding: nil, mapping: nil}

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    @tag authentication: [role: "admin"]
    test "lists all indices", %{conn: conn} do
      conn = get(conn, ~p"/api/indices")
      assert json_response(conn, 200)["data"] == []
    end

    @tag authentication: [role: "user"]
    test "non-admin cannot list indices", %{conn: conn} do
      conn = get(conn, ~p"/api/indices")
      assert json_response(conn, 403)
    end
  end

  describe "create index" do
    @tag authentication: [role: "admin"]
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

    @tag authentication: [role: "admin"]
    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/api/indices", index: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end

    @tag authentication: [role: "user"]
    test "non-admin cannot create indices", %{conn: conn} do
      conn = post(conn, ~p"/api/indices", index: @create_attrs)
      assert response(conn, 403)
    end
  end

  describe "update index" do
    setup [:create_index]

    @tag authentication: [role: "admin"]
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

    @tag authentication: [role: "admin"]
    test "renders errors when data is invalid", %{conn: conn, index: index} do
      conn = put(conn, ~p"/api/indices/#{index}", index: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end

    @tag authentication: [role: "user"]
    test "non-admin cannot update indices", %{
      conn: conn,
      index: index
    } do
      conn = put(conn, ~p"/api/indices/#{index}", index: @update_attrs)

      assert response(conn, 403)
    end
  end

  describe "delete index" do
    setup [:create_index]

    @tag authentication: [role: "admin"]
    test "deletes chosen index", %{conn: conn, index: index} do
      conn = delete(conn, ~p"/api/indices/#{index}")
      assert response(conn, 204)

      assert_error_sent 404, fn ->
        get(conn, ~p"/api/indices/#{index}")
      end
    end

    @tag authentication: [role: "user"]
    test "non-admin cannot delete indices", %{conn: conn, index: index} do
      conn = delete(conn, ~p"/api/indices/#{index}")

      assert response(conn, 403)
    end
  end

  describe "POST /indices/:id/enable" do
    @tag authentication: [role: "admin"]
    test "enables the index", %{conn: conn} do
      %{id: index_id} = insert(:index, enabled_at: nil)

      conn = post(conn, ~p"/api/indices/#{index_id}/enable")

      assert %{"data" => %{"id" => ^index_id, "enabled_at" => enabled_at}} =
               json_response(conn, 200)

      updated_index = Repo.get!(Index, index_id)
      assert updated_index.enabled_at
      assert enabled_at
    end
  end

  describe "POST /indices/:id/disable" do
    @tag authentication: [role: "admin"]
    test "enables the index", %{conn: conn} do
      %{id: index_id} = insert(:index, enabled_at: DateTime.utc_now())

      conn = post(conn, ~p"/api/indices/#{index_id}/disable")

      assert %{"data" => %{"id" => ^index_id, "enabled_at" => nil}} =
               json_response(conn, 200)

      updated_index = Repo.get!(Index, index_id)
      refute updated_index.enabled_at
    end
  end

  defp create_index(_) do
    index = insert(:index)
    %{index: index}
  end
end
