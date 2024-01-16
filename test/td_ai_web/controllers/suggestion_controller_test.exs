defmodule TdAiWeb.SuggestionControllerTest do
  use TdAiWeb.ConnCase

  alias TdAi.Completion.Suggestion
  alias TdCluster.TestHelpers.TdDfMock

  @create_attrs %{
    response: %{},
    resource_id: 42,
    generated_prompt: "some generated_prompt",
    request_time: 42,
    requested_by: 42,
    status: "ok"
  }
  @update_attrs %{
    response: %{},
    resource_id: 43,
    generated_prompt: "some updated generated_prompt",
    request_time: 43,
    requested_by: 43,
    status: "error"
  }
  @invalid_attrs %{
    response: nil,
    resource_id: nil,
    generated_prompt: nil,
    request_time: nil,
    requested_by: nil,
    prompt_id: nil,
    status: nil
  }

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    @tag authentication: [role: "admin"]
    test "lists all suggestions", %{conn: conn} do
      conn = get(conn, ~p"/api/suggestions")
      assert json_response(conn, 200)["data"] == []
    end

    @tag authentication: [role: "user"]
    test "non-admin cannot list suggestions", %{conn: conn} do
      conn = get(conn, ~p"/api/suggestions")
      assert json_response(conn, 403)
    end
  end

  describe "create suggestion" do
    @tag authentication: [role: "admin"]
    test "renders suggestion when data is valid", %{conn: conn} do
      %{id: prompt_id} = insert(:prompt)
      %{id: resource_mapping_id} = insert(:resource_mapping)

      attrs =
        @create_attrs
        |> Map.put(:prompt_id, prompt_id)
        |> Map.put(:resource_mapping_id, resource_mapping_id)

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
               "resource_mapping_id" => ^resource_mapping_id,
               "status" => "ok",
               "response" => %{}
             } = json_response(conn, 200)["data"]
    end

    @tag authentication: [role: "admin"]
    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/api/suggestions", suggestion: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end

    @tag authentication: [role: "user"]
    test "non-admin cannot create suggestions", %{conn: conn} do
      conn = post(conn, ~p"/api/suggestions", suggestion: @create_attrs)
      assert response(conn, 403)
    end
  end

  describe "update suggestion" do
    setup [:create_suggestion]

    @tag authentication: [role: "admin"]
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
               "status" => "error",
               "response" => %{}
             } = json_response(conn, 200)["data"]
    end

    @tag authentication: [role: "admin"]
    test "renders errors when data is invalid", %{conn: conn, suggestion: suggestion} do
      conn = put(conn, ~p"/api/suggestions/#{suggestion}", suggestion: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end

    @tag authentication: [role: "user"]
    test "non-admin cannot update suggestions", %{
      conn: conn,
      suggestion: suggestion
    } do
      conn = put(conn, ~p"/api/suggestions/#{suggestion}", suggestion: @update_attrs)

      assert response(conn, 403)
    end
  end

  describe "availability_check" do
    @tag authentication: [role: "admin"]
    test "renders ok when data is valid", %{conn: conn} do
      template_id = 1

      TdDfMock.get_template(
        &Mox.expect/4,
        template_id,
        {:ok,
         %{
           content: [
             %{"name" => "group", "fields" => [%{"name" => "foo", "ai_suggestion" => true}]}
           ]
         }}
      )

      insert(:prompt, resource_type: "business_concept", language: "en", active: true)

      params = %{
        resource_type: "business_concept",
        domain_ids: [1],
        template_id: template_id
      }

      conn = post(conn, ~p"/api/suggestions/availability_check", params)

      assert %{"status" => "ok"} = json_response(conn, 200)["data"]
    end

    @tag authentication: [role: "admin"]
    test "renders error if template does not have ai_suggestion fields", %{conn: conn} do
      template_id = 1

      TdDfMock.get_template(
        &Mox.expect/4,
        template_id,
        {:ok, %{content: [%{"name" => "group", "fields" => [%{"name" => "foo"}]}]}}
      )

      params = %{
        resource_type: "business_concept",
        domain_ids: [1],
        template_id: template_id
      }

      conn = post(conn, ~p"/api/suggestions/availability_check", params)

      assert %{
               "status" => "error",
               "reason" => "template has no ai_suggestion fields"
             } = json_response(conn, 200)["data"]
    end

    @tag authentication: [role: "admin"]
    test "renders error if template does not exist", %{conn: conn} do
      template_id = 1

      TdDfMock.get_template(
        &Mox.expect/4,
        template_id,
        nil
      )

      params = %{
        resource_type: "business_concept",
        domain_ids: [1],
        template_id: template_id
      }

      conn = post(conn, ~p"/api/suggestions/availability_check", params)

      assert %{
               "status" => "error",
               "reason" => "template not found"
             } = json_response(conn, 200)["data"]
    end

    @tag authentication: [role: "user", permissions: [:ai_business_concepts]]
    test "user with permission can request suggestion", %{conn: conn, domain: %{id: domain_id}} do
      template_id = 1

      TdDfMock.get_template(
        &Mox.expect/4,
        template_id,
        {:ok,
         %{
           content: [
             %{"name" => "group", "fields" => [%{"name" => "foo", "ai_suggestion" => true}]}
           ]
         }}
      )

      insert(:prompt, resource_type: "business_concept", language: "en", active: true)

      params = %{
        resource_type: "business_concept",
        domain_ids: [domain_id],
        template_id: template_id
      }

      conn = post(conn, ~p"/api/suggestions/availability_check", params)

      assert %{"status" => "ok"} = json_response(conn, 200)["data"]
    end

    @tag authentication: [role: "user"]
    test "user without permissions cannot request suggestions", %{conn: conn} do
      params = %{
        resource_type: "business_concept",
        domain_ids: [1],
        template_id: 1
      }

      conn = post(conn, ~p"/api/suggestions/availability_check", params)

      assert %{
               "status" => "error",
               "reason" => "forbidden"
             } = json_response(conn, 200)["data"]
    end

    @tag authentication: [role: "admin"]
    test "renders error if there are no active prompts", %{conn: conn} do
      template_id = 1

      TdDfMock.get_template(
        &Mox.expect/4,
        template_id,
        {:ok,
         %{
           content: [
             %{"name" => "group", "fields" => [%{"name" => "foo", "ai_suggestion" => true}]}
           ]
         }}
      )

      params = %{
        resource_type: "business_concept",
        domain_ids: [1],
        template_id: template_id
      }

      conn = post(conn, ~p"/api/suggestions/availability_check", params)

      assert %{"status" => "error", "reason" => "no active prompt"} =
               json_response(conn, 200)["data"]
    end
  end

  describe "request suggestions" do
    @tag authentication: [role: "admin"]
    test "renders ok when data is valid", %{conn: conn} do
      template_id = 1
      language = "en"
      resource_type = "business_concept"
      provider = "mock"
      model = "test_model"

      TdDfMock.get_template(
        &Mox.expect/4,
        template_id,
        {:ok,
         %{
           content: [
             %{"name" => "group", "fields" => [%{"name" => "foo", "ai_suggestion" => true}]}
           ]
         }}
      )

      Mox.expect(TdAi.Provider.Mock, :chat_completion, 1, fn
        model, system_prompt, user_prompt ->
          response =
            %{
              "model" => model,
              "system_prompt" => system_prompt,
              "user_prompt" => user_prompt
            }
            |> Jason.encode!()

          {:ok, response}
      end)

      insert(:prompt,
        language: language,
        resource_type: resource_type,
        active: true,
        provider: provider,
        model: model,
        user_prompt_template: "Structure: {resource} - Fields: {fields}"
      )

      params = %{
        resource_type: "business_concept",
        resource_body: %{"hello" => "world"},
        domain_ids: [1],
        template_id: template_id
      }

      conn = post(conn, ~p"/api/suggestions/request", params)

      assert %{
               "model" => "test_model",
               "system_prompt" => "some system_prompt",
               "user_prompt" => "Structure: {\"hello\":\"world\"} - Fields: [{\"name\":\"foo\"}]"
             } = json_response(conn, 200)["data"]
    end

    @tag authentication: [role: "admin"]
    test "renders error if template does not have ai_suggestion fields", %{conn: conn} do
      template_id = 1

      TdDfMock.get_template(
        &Mox.expect/4,
        template_id,
        {:ok, %{content: [%{"name" => "group", "fields" => [%{"name" => "foo"}]}]}}
      )

      params = %{
        resource_type: "business_concept",
        resource_body: %{},
        domain_ids: [1],
        template_id: template_id
      }

      conn = post(conn, ~p"/api/suggestions/request", params)

      assert %{"error" => "template has no ai_suggestion fields"} = json_response(conn, 422)
    end

    @tag authentication: [role: "admin"]
    test "renders error if template does not exist", %{conn: conn} do
      template_id = 1

      TdDfMock.get_template(
        &Mox.expect/4,
        template_id,
        nil
      )

      params = %{
        resource_type: "business_concept",
        resource_body: %{},
        domain_ids: [1],
        template_id: template_id
      }

      conn = post(conn, ~p"/api/suggestions/request", params)

      assert %{"error" => "template not found"} = json_response(conn, 422)
    end

    @tag authentication: [role: "user", permissions: [:ai_business_concepts]]
    test "user with permission can request suggestion", %{conn: conn, domain: %{id: domain_id}} do
      template_id = 1
      language = "en"
      resource_type = "business_concept"
      provider = "mock"
      model = "test_model"

      TdDfMock.get_template(
        &Mox.expect/4,
        template_id,
        {:ok,
         %{
           content: [
             %{"name" => "group", "fields" => [%{"name" => "foo", "ai_suggestion" => true}]}
           ]
         }}
      )

      Mox.expect(TdAi.Provider.Mock, :chat_completion, 1, fn
        model, system_prompt, user_prompt ->
          response =
            %{
              "model" => model,
              "system_prompt" => system_prompt,
              "user_prompt" => user_prompt
            }
            |> Jason.encode!()

          {:ok, response}
      end)

      insert(:prompt,
        language: language,
        resource_type: resource_type,
        active: true,
        provider: provider,
        model: model,
        user_prompt_template: "Structure: {resource} - Fields: {fields}"
      )

      params = %{
        resource_type: "business_concept",
        resource_body: %{"hello" => "world"},
        domain_ids: [domain_id],
        template_id: template_id
      }

      conn = post(conn, ~p"/api/suggestions/request", params)

      assert %{
               "model" => "test_model",
               "system_prompt" => "some system_prompt",
               "user_prompt" => "Structure: {\"hello\":\"world\"} - Fields: [{\"name\":\"foo\"}]"
             } = json_response(conn, 200)["data"]
    end

    @tag authentication: [role: "user"]
    test "user without permissions cannot request suggestions", %{conn: conn} do
      params = %{
        resource_type: "business_concept",
        resource_body: %{},
        domain_ids: [1],
        template_id: 1
      }

      conn = post(conn, ~p"/api/suggestions/request", params)

      assert response(conn, 403)
    end

    @tag authentication: [role: "admin"]
    test "renders error if there are no active prompts", %{conn: conn} do
      template_id = 1

      TdDfMock.get_template(
        &Mox.expect/4,
        template_id,
        {:ok,
         %{
           content: [
             %{"name" => "group", "fields" => [%{"name" => "foo", "ai_suggestion" => true}]}
           ]
         }}
      )

      params = %{
        resource_type: "business_concept",
        resource_body: %{},
        domain_ids: [1],
        template_id: template_id
      }

      conn = post(conn, ~p"/api/suggestions/request", params)

      assert %{"error" => "invalid_prompt"} = json_response(conn, 422)
    end
  end

  describe "delete suggestion" do
    setup [:create_suggestion]

    @tag authentication: [role: "admin"]
    test "deletes chosen suggestion", %{conn: conn, suggestion: suggestion} do
      conn = delete(conn, ~p"/api/suggestions/#{suggestion}")
      assert response(conn, 204)

      assert_error_sent 404, fn ->
        get(conn, ~p"/api/suggestions/#{suggestion}")
      end
    end

    @tag authentication: [role: "user"]
    test "non-admin cannot delete suggestions", %{
      conn: conn,
      suggestion: suggestion
    } do
      conn = delete(conn, ~p"/api/suggestions/#{suggestion}")

      assert response(conn, 403)
    end
  end

  defp create_suggestion(_) do
    suggestion = insert(:suggestion)
    %{suggestion: suggestion}
  end
end
