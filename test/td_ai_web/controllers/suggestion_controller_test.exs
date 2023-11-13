defmodule TdAiWeb.SuggestionControllerTest do
  use TdAiWeb.ConnCase

  alias TdAi.Completion.Suggestion

  @create_attrs %{
    response: %{},
    resource_id: 42,
    generated_prompt: "some generated_prompt",
    request_time: 42,
    requested_by: 42
  }
  @update_attrs %{
    response: %{},
    resource_id: 43,
    generated_prompt: "some updated generated_prompt",
    request_time: 43,
    requested_by: 43
  }
  @invalid_attrs %{
    response: nil,
    resource_id: nil,
    generated_prompt: nil,
    request_time: nil,
    requested_by: nil,
    prompt_id: nil
  }

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "lists all suggestions", %{conn: conn} do
      conn = get(conn, ~p"/api/suggestions")
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create suggestion" do
    test "renders suggestion when data is valid", %{conn: conn} do
      %{id: prompt_id} = insert(:prompt)
      attrs = Map.put(@create_attrs, :prompt_id, prompt_id)
      conn = post(conn, ~p"/api/suggestions", suggestion: attrs)
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, ~p"/api/suggestions/#{id}")

      assert %{
               "id" => ^id,
               "generated_prompt" => "some generated_prompt",
               "request_time" => 42,
               "requested_by" => 42,
               "resource_id" => 42,
               "prompt_id" => ^prompt_id,
               "response" => %{}
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/api/suggestions", suggestion: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update suggestion" do
    setup [:create_suggestion]

    test "renders suggestion when data is valid", %{
      conn: conn,
      suggestion: %Suggestion{id: id} = suggestion
    } do
      conn = put(conn, ~p"/api/suggestions/#{suggestion}", suggestion: @update_attrs)
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(conn, ~p"/api/suggestions/#{id}")

      assert %{
               "id" => ^id,
               "generated_prompt" => "some updated generated_prompt",
               "request_time" => 43,
               "requested_by" => 43,
               "resource_id" => 43,
               "response" => %{}
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn, suggestion: suggestion} do
      conn = put(conn, ~p"/api/suggestions/#{suggestion}", suggestion: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete suggestion" do
    setup [:create_suggestion]

    test "deletes chosen suggestion", %{conn: conn, suggestion: suggestion} do
      conn = delete(conn, ~p"/api/suggestions/#{suggestion}")
      assert response(conn, 204)

      assert_error_sent 404, fn ->
        get(conn, ~p"/api/suggestions/#{suggestion}")
      end
    end
  end

  defp create_suggestion(_) do
    suggestion = insert(:suggestion)
    %{suggestion: suggestion}
  end
end
