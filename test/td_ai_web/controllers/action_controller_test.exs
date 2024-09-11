defmodule TdAiWeb.ActionControllerTest do
  use TdAiWeb.ConnCase

  import TdAi.TestOperators

  alias TdAi.Actions.Action
  alias TdAi.Repo
  alias TdCore.TestSupport.CacheHelpers

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    @tag authentication: [role: "admin"]
    test "list all actions", %{conn: conn} do
      actions =
        Enum.map(1..3, fn _ ->
          :action
          |> insert()
          |> Map.get(:id)
        end)

      assert actions |||
               conn
               |> get(~p"/api/actions")
               |> json_response(200)
               |> Map.get("data")
               |> Enum.map(&Map.get(&1, "id"))
    end

    @tag authentication: [role: "admin"]
    test "list actions returns user information", %{conn: conn} do
      %{
        full_name: user_full_name,
        id: user_id
      } = CacheHelpers.insert_user()

      insert(:action, user_id: user_id)

      assert %{
               "data" => [
                 %{
                   "user" => %{
                     "id" => ^user_id,
                     "full_name" => ^user_full_name
                   }
                 }
               ]
             } =
               conn
               |> get(~p"/api/actions")
               |> json_response(200)
    end

    @tag authentication: [role: "user"]
    test "non admin is unauthorized", %{conn: conn} do
      assert conn
             |> get(~p"/api/actions")
             |> json_response(403)
    end
  end

  describe "search" do
    @tag authentication: [role: "admin"]
    test "list actions filtered by params", %{conn: conn} do
      %{id: id1} = insert(:action, user_id: 1, is_enabled: false)
      %{id: id2} = insert(:action, user_id: 2)
      %{id: id3} = insert(:action, user_id: 1)

      by_user_id = [id1, id3]
      by_is_enabled = [id2, id3]

      assert by_user_id |||
               conn
               |> post(~p"/api/actions/search", %{"user_id" => 1})
               |> json_response(200)
               |> Map.get("data")
               |> Enum.map(&Map.get(&1, "id"))

      assert by_is_enabled |||
               conn
               |> post(~p"/api/actions/search", %{"is_enabled" => true})
               |> json_response(200)
               |> Map.get("data")
               |> Enum.map(&Map.get(&1, "id"))

      assert [id1] ==
               conn
               |> post(~p"/api/actions/search", %{
                 "is_enabled" => false,
                 "user_id" => 1
               })
               |> json_response(200)
               |> Map.get("data")
               |> Enum.map(&Map.get(&1, "id"))

      assert [id1] ==
               conn
               |> post(~p"/api/actions/search", %{"id" => id1})
               |> json_response(200)
               |> Map.get("data")
               |> Enum.map(&Map.get(&1, "id"))
    end

    @tag authentication: [role: "admin"]
    test "empty list actions filtered by params", %{conn: conn} do
      insert(:action, user_id: 1)

      assert %{"data" => []} =
               conn
               |> post(~p"/api/actions/search", %{
                 "is_enabled" => false,
                 "user_id" => 2
               })
               |> json_response(200)
    end

    @tag authentication: [role: "admin"]
    test "list all actions when no params", %{conn: conn} do
      Enum.map(1..3, fn _ ->
        :action
        |> insert()
        |> Map.get(:id)
      end)

      assert %{"data" => data} =
               conn
               |> post(~p"/api/actions/search", %{})
               |> json_response(200)

      assert length(data) == 3
    end

    @tag authentication: [role: "user"]
    test "non admin is unauthorized", %{conn: conn} do
      assert conn
             |> post(~p"/api/actions/search", %{
               "user_id" => 1
             })
             |> json_response(403)
    end
  end

  describe "me" do
    @tag authentication: [role: "agent"]
    test "list all user active actions when no params", %{
      conn: conn,
      claims: %{user_id: user_id}
    } do
      current_date = DateTime.utc_now()
      %{id: id1} = insert(:action, user_id: user_id)
      %{id: id2} = insert(:action, user_id: user_id)
      insert(:action, user_id: 1)
      insert(:action, user_id: user_id, is_enabled: false)
      insert(:action, user_id: user_id, deleted_at: current_date)

      assert [id1, id2] |||
               conn
               |> post(~p"/api/actions/me")
               |> json_response(200)
               |> Map.get("data")
               |> Enum.map(&Map.get(&1, "id"))
    end

    @tag authentication: [role: "agent"]
    test "list all user active actions with types param", %{
      conn: conn,
      claims: %{user_id: user_id}
    } do
      current_date = DateTime.utc_now()
      %{id: id1} = insert(:action, user_id: user_id, type: "action_type_1")
      %{id: id2} = insert(:action, user_id: user_id, type: "action_type_2")
      insert(:action, user_id: user_id, type: "action_type_3")
      insert(:action, user_id: 1, type: "action_type_1")
      insert(:action, user_id: user_id, is_enabled: false, type: "action_type_1")
      insert(:action, user_id: user_id, deleted_at: current_date, type: "action_type_1")

      assert [id1] ==
               conn
               |> post(~p"/api/actions/me", %{"types" => ["action_type_1"]})
               |> json_response(200)
               |> Map.get("data")
               |> Enum.map(&Map.get(&1, "id"))

      assert [id1, id2] ==
               conn
               |> post(~p"/api/actions/me", %{"types" => ["action_type_1", "action_type_2"]})
               |> json_response(200)
               |> Map.get("data")
               |> Enum.map(&Map.get(&1, "id"))
    end

    @tag authentication: [role: "user"]
    test "non admin or agent is unauthorized", %{conn: conn} do
      assert conn
             |> post(~p"/api/actions/me")
             |> json_response(403)
    end
  end

  describe "show" do
    @tag authentication: [role: "admin"]
    test "get action", %{conn: conn} do
      %{id: id} = insert(:action)
      insert(:action)

      assert %{"data" => %{"id" => ^id}} =
               conn
               |> get(~p"/api/actions/#{id}")
               |> json_response(200)
    end

    @tag authentication: [role: "admin"]
    test "return not_found when id not exist", %{conn: conn} do
      assert conn
             |> get(~p"/api/actions/123")
             |> json_response(404)
    end

    @tag authentication: [role: "user"]
    test "non admin is unauthorized", %{conn: conn} do
      assert conn
             |> get(~p"/api/actions/123")
             |> json_response(403)
    end
  end

  describe "create" do
    @tag authentication: [role: "admin"]
    test "create action with require data", %{conn: conn} do
      create_attrs = %{
        "name" => "AI Action Name",
        "user_id" => 1,
        "type" => "template_name"
      }

      assert %{"data" => %{"id" => id}} =
               conn
               |> post(~p"/api/actions", create_attrs)
               |> json_response(201)

      assert %{
               name: "AI Action Name",
               user_id: 1,
               type: "template_name",
               dynamic_content: %{},
               is_enabled: true,
               deleted_at: nil
             } = Repo.get(Action, id)
    end

    @tag authentication: [role: "admin"]
    test "create action with optional data", %{conn: conn} do
      current_date = DateTime.utc_now()

      create_attrs = %{
        "name" => "AI Action Name",
        "user_id" => 1,
        "type" => "template_name",
        "dynamic_content" => %{"foo" => "bar"},
        "is_enabled" => false,
        "deleted_at" => DateTime.to_string(current_date)
      }

      assert %{"data" => %{"id" => id}} =
               conn
               |> post(~p"/api/actions", create_attrs)
               |> json_response(201)

      assert %{
               name: "AI Action Name",
               user_id: 1,
               type: "template_name",
               dynamic_content: %{"foo" => "bar"},
               is_enabled: false,
               deleted_at: ^current_date
             } = Repo.get(Action, id)
    end

    @tag authentication: [role: "admin"]
    test "error creating action with invalid data", %{conn: conn} do
      create_attrs = %{
        "user_id" => true,
        "type" => false,
        "dynamic_content" => "Bash",
        "is_enabled" => "Apple",
        "deleted_at" => 123_456_789
      }

      assert %{"errors" => _} =
               conn
               |> post(~p"/api/actions", create_attrs)
               |> json_response(422)
    end

    @tag authentication: [role: "user"]
    test "non admin is unauthorized", %{conn: conn} do
      assert conn
             |> post(~p"/api/actions", %{})
             |> json_response(403)
    end
  end

  describe "update" do
    @tag authentication: [role: "admin"]
    test "update action data", %{conn: conn} do
      %{id: id} = insert(:action)

      update_attrs = %{
        "dynamic_content" => %{"foo" => "bar"},
        "is_enabled" => false
      }

      conn
      |> put(~p"/api/actions/#{id}", update_attrs)
      |> json_response(200)

      assert %{
               dynamic_content: %{"foo" => "bar"},
               is_enabled: false
             } = Repo.get(Action, id)
    end

    @tag authentication: [role: "admin"]
    test "return not_found when id not exist", %{conn: conn} do
      assert conn
             |> put(~p"/api/actions/123", %{})
             |> json_response(404)
    end

    @tag authentication: [role: "user"]
    test "non admin is unauthorized", %{conn: conn} do
      assert conn
             |> put(~p"/api/actions/123", %{})
             |> json_response(403)
    end
  end

  describe "delete" do
    @tag authentication: [role: "admin"]
    test "fisical default delete action without param", %{conn: conn} do
      %{id: id} = insert(:action)

      assert %{"data" => %{"id" => ^id, "deleted_at" => _}} =
               conn
               |> delete(~p"/api/actions/#{id}")
               |> json_response(200)

      refute Repo.get(Action, id)
    end

    @tag authentication: [role: "admin"]
    test "fisical delete action with param", %{conn: conn} do
      %{id: id} = insert(:action)

      delete_params = %{
        "logical" => false
      }

      assert %{"data" => %{"id" => ^id, "deleted_at" => _}} =
               conn
               |> delete(~p"/api/actions/#{id}", delete_params)
               |> json_response(200)

      refute Repo.get(Action, id)
    end

    @tag authentication: [role: "admin"]
    test "logical delete action", %{conn: conn} do
      %{id: id} = insert(:action)

      delete_params = %{"logical" => "true"}

      assert %{"data" => %{"id" => ^id, "deleted_at" => deleted_at}} =
               conn
               |> delete(~p"/api/actions/#{id}", delete_params)
               |> json_response(200)

      refute is_nil(deleted_at)
      assert %{deleted_at: ddbb_deleted_at} = Repo.get(Action, id)
      assert DateTime.to_iso8601(ddbb_deleted_at) == deleted_at
    end

    @tag authentication: [role: "admin"]
    test "return not_found when id not exist", %{conn: conn} do
      assert conn
             |> delete(~p"/api/actions/123")
             |> json_response(404)
    end

    @tag authentication: [role: "user"]
    test "non admin is unauthorized", %{conn: conn} do
      assert conn
             |> delete(~p"/api/actions/123")
             |> json_response(403)
    end
  end

  describe "set_active" do
    @tag authentication: [role: "admin"]
    test "set active true", %{conn: conn} do
      %{id: id} = insert(:action, is_enabled: false)

      update_params = %{
        "active" => true
      }

      assert %{"data" => %{"id" => ^id, "is_enabled" => true}} =
               conn
               |> post(~p"/api/actions/#{id}/set_active", update_params)
               |> json_response(200)
    end

    @tag authentication: [role: "admin"]
    test "set active false", %{conn: conn} do
      %{id: id} = insert(:action, is_enabled: true)

      update_params = %{
        "active" => false
      }

      assert %{"data" => %{"id" => ^id, "is_enabled" => false}} =
               conn
               |> post(~p"/api/actions/#{id}/set_active", update_params)
               |> json_response(200)
    end

    @tag authentication: [role: "admin"]
    test "return not_found when id not exist", %{conn: conn} do
      update_params = %{
        "active" => "false"
      }

      assert %{"errors" => _} =
               conn
               |> post(~p"/api/actions/100/set_active", update_params)
               |> json_response(404)
    end
  end
end
