defmodule TdAiWeb.ResourceMappingControllerTest do
  use TdAiWeb.ConnCase

  alias TdAi.Completion.ResourceMapping

  @create_attrs %{
    name: "some name",
    fields: [%{source: "source_field"}],
    resource_type: "some resource"
  }
  @update_attrs %{
    name: "some updated name",
    fields: [%{source: "updated_source_field"}],
    resource_type: "other resorce",
    selector: %{"foo" => "bar"}
  }
  @invalid_attrs %{name: nil, fields: nil}

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "lists all resource_mappings", %{conn: conn} do
      conn = get(conn, ~p"/api/resource_mappings")
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create resource_mapping" do
    test "renders resource_mapping when data is valid", %{conn: conn} do
      conn = post(conn, ~p"/api/resource_mappings", resource_mapping: @create_attrs)
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, ~p"/api/resource_mappings/#{id}")

      assert %{
               "id" => ^id,
               "fields" => [%{"source" => "source_field", "target" => nil}],
               "name" => "some name"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/api/resource_mappings", resource_mapping: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update resource_mapping" do
    setup [:create_resource_mapping]

    test "renders resource_mapping when data is valid", %{
      conn: conn,
      resource_mapping: %ResourceMapping{id: id} = resource_mapping
    } do
      conn =
        put(conn, ~p"/api/resource_mappings/#{resource_mapping}", resource_mapping: @update_attrs)

      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(conn, ~p"/api/resource_mappings/#{id}")

      assert %{
               "id" => ^id,
               "fields" => [%{"source" => "updated_source_field", "target" => nil}],
               "name" => "some updated name"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn, resource_mapping: resource_mapping} do
      conn =
        put(conn, ~p"/api/resource_mappings/#{resource_mapping}",
          resource_mapping: @invalid_attrs
        )

      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete resource_mapping" do
    setup [:create_resource_mapping]

    test "deletes chosen resource_mapping", %{conn: conn, resource_mapping: resource_mapping} do
      conn = delete(conn, ~p"/api/resource_mappings/#{resource_mapping}")
      assert response(conn, 204)

      assert_error_sent 404, fn ->
        get(conn, ~p"/api/resource_mappings/#{resource_mapping}")
      end
    end
  end

  defp create_resource_mapping(_) do
    resource_mapping = insert(:resource_mapping)
    %{resource_mapping: resource_mapping}
  end
end
