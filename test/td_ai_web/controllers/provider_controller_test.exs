defmodule TdAiWeb.ProviderControllerTest do
  use TdAiWeb.ConnCase

  alias TdAi.Completion
  alias TdAi.Completion.Provider
  alias TdAi.ProviderClients.MockImpl

  @create_attrs %{
    name: "some name",
    type: "mock",
    properties: %{model: "some model", api_key: "some_secret"}
  }
  @update_attrs %{
    name: "some updated name",
    type: "openai",
    properties: %{
      model: "some updated model",
      organization_key: "some updated organization_key",
      api_key: "new api key"
    }
  }
  @invalid_attrs %{name: nil, properties: nil}

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    @tag authentication: [role: "admin"]
    test "lists all providers", %{conn: conn} do
      conn = get(conn, ~p"/api/providers")
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create provider" do
    @tag authentication: [role: "admin"]
    test "renders provider when data is valid", %{conn: conn} do
      conn = post(conn, ~p"/api/providers", provider: @create_attrs)
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, ~p"/api/providers/#{id}")

      assert %{
               "id" => ^id,
               "name" => "some name",
               "type" => "mock",
               "properties" => %{
                 "model" => "some model"
               }
             } = json_response(conn, 200)["data"]

      assert [%Provider{properties: %{mock: %{model: "some model", api_key: nil}}}] =
               Completion.list_providers()
    end

    @tag authentication: [role: "admin"]
    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/api/providers", provider: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end

    @tag authentication: [role: "user"]
    test "non-admin cannot create providers", %{conn: conn} do
      conn = post(conn, ~p"/api/providers", provider: @create_attrs)
      assert response(conn, 403)
    end
  end

  describe "update provider" do
    setup [:create_provider]

    @tag authentication: [role: "admin"]
    test "renders provider when data is valid", %{
      conn: conn,
      provider: %Provider{id: id} = provider
    } do
      conn = put(conn, ~p"/api/providers/#{provider}", provider: @update_attrs)
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(conn, ~p"/api/providers/#{id}")

      assert %{
               "id" => ^id,
               "name" => "some updated name",
               "type" => "openai",
               "properties" => %{
                 "model" => "some updated model",
                 "organization_key" => "some updated organization_key"
               }
             } = json_response(conn, 200)["data"]

      assert [%Provider{properties: %{openai: %{model: "some updated model", api_key: nil}}}] =
               Completion.list_providers()
    end

    @tag authentication: [role: "admin"]
    test "when updating only props, do not write secrets", %{
      conn: conn,
      provider: %Provider{id: id} = provider
    } do
      update_attrs = %{
        properties: %{
          model: "some updated model"
        }
      }

      conn = put(conn, ~p"/api/providers/#{provider}", provider: update_attrs)
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(conn, ~p"/api/providers/#{id}")

      assert %{
               "id" => ^id,
               "type" => "mock",
               "properties" => %{"model" => "some updated model"}
             } = json_response(conn, 200)["data"]

      assert [%Provider{properties: %{mock: %{model: "some updated model", api_key: nil}}}] =
               Completion.list_providers()
    end

    @tag authentication: [role: "admin"]
    test "renders errors when data is invalid", %{conn: conn, provider: provider} do
      conn = put(conn, ~p"/api/providers/#{provider}", provider: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end

    @tag authentication: [role: "user"]
    test "non-admin cannot update providers", %{
      conn: conn,
      provider: provider
    } do
      conn = put(conn, ~p"/api/providers/#{provider}", provider: @update_attrs)

      assert response(conn, 403)
    end
  end

  describe "delete provider" do
    setup [:create_provider]

    @tag authentication: [role: "admin"]
    test "deletes chosen provider", %{conn: conn, provider: provider} do
      conn = delete(conn, ~p"/api/providers/#{provider}")
      assert response(conn, 204)

      assert_error_sent 404, fn ->
        get(conn, ~p"/api/providers/#{provider}")
      end
    end

    @tag authentication: [role: "user"]
    test "non-admin cannot delete providers", %{
      conn: conn,
      provider: provider
    } do
      conn = delete(conn, ~p"/api/providers/#{provider}")

      assert response(conn, 403)
    end
  end

  describe "provider chat_completion" do
    setup [:create_provider]

    @tag authentication: [role: "admin"]
    test "runs chat_completion", %{conn: conn, provider: provider} do
      body = %{
        messages: [
          %{role: "system", content: "Hello"},
          %{role: "user", content: "Hi"}
        ]
      }

      Mox.expect(
        TdAi.ProviderClients.Mock,
        :chat_completion,
        1,
        &MockImpl.chat_completion/2
      )

      conn = post(conn, ~p"/api/providers/#{provider}/chat_completion", body)

      assert %{
               "messages" => [
                 %{"content" => "Hello", "role" => "system"},
                 %{"content" => "Hi", "role" => "user"}
               ],
               "provider_properties" => %{"model" => "some model"}
             } =
               conn
               |> json_response(200)
               |> Jason.decode!()
    end

    @tag authentication: [role: "user"]
    test "non-admin cannot run provider's chat_completion", %{
      conn: conn,
      provider: provider
    } do
      body = %{
        messages: [%{role: "user", content: "Hi"}]
      }

      conn = post(conn, ~p"/api/providers/#{provider}/chat_completion", body)

      assert response(conn, 403)
    end
  end

  defp create_provider(_) do
    provider = insert(:provider)
    %{provider: provider}
  end
end
