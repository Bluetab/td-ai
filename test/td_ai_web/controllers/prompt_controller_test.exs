defmodule TdAiWeb.PromptControllerTest do
  use TdAiWeb.ConnCase

  alias TdAi.Completion.Prompt

  @create_attrs %{
    name: "some name",
    language: "some language",
    resource_type: "some resource_type",
    system_prompt: "some system_prompt",
    user_prompt_template: "some user_prompt_template",
    model: "some model",
    provider: "some provider"
  }
  @update_attrs %{
    name: "some updated name",
    language: "some updated language",
    resource_type: "some updated resource_type",
    system_prompt: "some updated system_prompt",
    user_prompt_template: "some updated user_prompt_template",
    model: "some updated model",
    provider: "some updated provider"
  }
  @invalid_attrs %{
    name: nil,
    language: nil,
    resource_type: nil,
    system_prompt: nil,
    user_prompt_template: nil,
    model: nil,
    provider: nil
  }

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    @tag authentication: [role: "admin"]
    test "lists all prompts", %{conn: conn} do
      conn = get(conn, ~p"/api/prompts")
      assert json_response(conn, 200)["data"] == []
    end

    @tag authentication: [role: "user"]
    test "non-admin cannot list prompts", %{conn: conn} do
      conn = get(conn, ~p"/api/prompts")
      assert json_response(conn, 403)
    end
  end

  describe "create prompt" do
    @tag authentication: [role: "admin"]
    test "renders prompt when data is valid", %{conn: conn} do
      conn = post(conn, ~p"/api/prompts", prompt: @create_attrs)
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, ~p"/api/prompts/#{id}")

      assert %{
               "id" => ^id,
               "language" => "some language",
               "name" => "some name",
               "resource_type" => "some resource_type",
               "system_prompt" => "some system_prompt",
               "user_prompt_template" => "some user_prompt_template",
               "model" => "some model",
               "provider" => "some provider"
             } = json_response(conn, 200)["data"]
    end

    @tag authentication: [role: "admin"]
    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/api/prompts", prompt: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end

    @tag authentication: [role: "user"]
    test "non-admin cannot create prompts", %{conn: conn} do
      conn = post(conn, ~p"/api/prompts", prompt: @create_attrs)
      assert response(conn, 403)
    end
  end

  describe "update prompt" do
    setup [:create_prompt]

    @tag authentication: [role: "admin"]
    test "renders prompt when data is valid", %{conn: conn, prompt: %Prompt{id: id} = prompt} do
      conn = put(conn, ~p"/api/prompts/#{prompt}", prompt: @update_attrs)
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(conn, ~p"/api/prompts/#{id}")

      assert %{
               "id" => ^id,
               "language" => "some updated language",
               "name" => "some updated name",
               "resource_type" => "some updated resource_type",
               "system_prompt" => "some updated system_prompt",
               "user_prompt_template" => "some updated user_prompt_template",
               "model" => "some updated model",
               "provider" => "some updated provider"
             } = json_response(conn, 200)["data"]
    end

    @tag authentication: [role: "admin"]
    test "renders errors when data is invalid", %{conn: conn, prompt: prompt} do
      conn = put(conn, ~p"/api/prompts/#{prompt}", prompt: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end

    @tag authentication: [role: "user"]
    test "non-admin cannot update prompts", %{
      conn: conn,
      prompt: prompt
    } do
      conn = put(conn, ~p"/api/prompts/#{prompt}", prompt: @update_attrs)

      assert response(conn, 403)
    end
  end

  describe "set prompt active" do
    setup [:create_prompt]

    @tag authentication: [role: "admin"]
    test "will make a prompt active", %{conn: conn, prompt: %Prompt{id: id} = prompt} do
      conn = patch(conn, ~p"/api/prompts/#{prompt}/set_active")
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(conn, ~p"/api/prompts/#{id}")

      assert %{
               "id" => ^id,
               "active" => true
             } = json_response(conn, 200)["data"]
    end

    @tag authentication: [role: "admin"]
    test "will make other prompts with same language and resource_type not active", %{
      conn: conn,
      prompt: %Prompt{id: id, language: language, resource_type: resource_type}
    } do
      %{id: another_prompt_id} =
        insert(:prompt, %{language: language, resource_type: resource_type})

      conn = patch(conn, ~p"/api/prompts/#{another_prompt_id}/set_active")
      assert %{"id" => ^another_prompt_id, "active" => true} = json_response(conn, 200)["data"]

      conn = patch(conn, ~p"/api/prompts/#{id}/set_active")
      assert %{"id" => ^id, "active" => true} = json_response(conn, 200)["data"]

      conn = get(conn, ~p"/api/prompts/#{another_prompt_id}")

      assert %{
               "id" => ^another_prompt_id,
               "active" => false
             } = json_response(conn, 200)["data"]
    end

    @tag authentication: [role: "user"]
    test "non admin cannot make a prompt active", %{conn: conn, prompt: prompt} do
      conn = patch(conn, ~p"/api/prompts/#{prompt}/set_active")
      assert response(conn, 403)
    end
  end

  describe "delete prompt" do
    setup [:create_prompt]

    @tag authentication: [role: "admin"]
    test "deletes chosen prompt", %{conn: conn, prompt: prompt} do
      conn = delete(conn, ~p"/api/prompts/#{prompt}")
      assert response(conn, 204)

      assert_error_sent 404, fn ->
        get(conn, ~p"/api/prompts/#{prompt}")
      end
    end

    @tag authentication: [role: "user"]
    test "non-admin cannot delete prompts", %{
      conn: conn,
      prompt: prompt
    } do
      conn = delete(conn, ~p"/api/prompts/#{prompt}")

      assert response(conn, 403)
    end
  end

  defp create_prompt(_) do
    prompt = insert(:prompt)
    %{prompt: prompt}
  end
end
