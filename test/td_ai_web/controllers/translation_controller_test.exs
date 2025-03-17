defmodule TdAiWeb.TranslationControllerTest do
  use TdAiWeb.ConnCase

  alias TdAi.Completion.Translation
  alias TdAi.ProviderClients.MockImpl
  alias TdAi.Repo

  @create_attrs %{
    response: %{},
    resource_id: 42,
    generated_prompt: "some generated_translation",
    request_time: 42,
    requested_by: 42,
    status: "ok"
  }

  @update_attrs %{
    response: %{},
    resource_id: 43,
    generated_prompt: "some updated generated_translation",
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
    {:ok,
     conn: put_req_header(conn, "accept", "application/json"), translation: insert(:translation)}
  end

  describe "index/2" do
    @tag authentication: [role: "admin"]
    test "lists all translations", %{conn: conn} do
      assert %{"data" => [_]} =
               conn
               |> get(~p"/api/translations")
               |> json_response(:ok)
    end

    @tag authentication: [role: "user"]
    test "non-admin cannot list translations", %{conn: conn} do
      assert conn
             |> get(~p"/api/translations")
             |> json_response(:forbidden)
    end
  end

  describe "show/2" do
    @tag authentication: [role: "admin"]
    test "renders translation", %{
      conn: conn,
      translation: %{
        id: id,
        generated_prompt: generated_prompt,
        request_time: request_time,
        requested_by: requested_by,
        resource_id: resource_id,
        prompt_id: prompt_id,
        status: status,
        response: response
      }
    } do
      assert %{"data" => data} =
               conn
               |> get(~p"/api/translations/#{id}")
               |> json_response(:ok)

      assert %{
               "id" => ^id,
               "generated_prompt" => ^generated_prompt,
               "request_time" => ^request_time,
               "requested_by" => ^requested_by,
               "resource_id" => ^resource_id,
               "prompt_id" => ^prompt_id,
               "status" => ^status,
               "response" => ^response
             } = data
    end

    @tag authentication: [role: "user"]
    test "non-admin cannot render translations", %{conn: conn, translation: %{id: id}} do
      assert conn
             |> get(~p"/api/translations/#{id}")
             |> json_response(:forbidden)
    end
  end

  describe "create/2" do
    @tag authentication: [role: "admin"]
    test "creates translation when data is valid", %{conn: conn} do
      %{id: prompt_id} = insert(:prompt)

      attrs = Map.put(@create_attrs, :prompt_id, prompt_id)

      assert %{"data" => %{"id" => id}} =
               conn
               |> post(~p"/api/translations", translation: attrs)
               |> json_response(:created)

      assert %{
               id: ^id,
               generated_prompt: "some generated_translation",
               request_time: 42,
               requested_by: 42,
               resource_id: 42,
               prompt_id: ^prompt_id,
               status: "ok",
               response: %{}
             } =
               Repo.get(Translation, id)
    end

    @tag authentication: [role: "admin"]
    test "renders errors when data is invalid", %{conn: conn} do
      assert %{"errors" => errors} =
               conn
               |> post(~p"/api/translations", translation: @invalid_attrs)
               |> json_response(:unprocessable_entity)

      assert errors != %{}
    end

    @tag authentication: [role: "user"]
    test "non-admin cannot create translations", %{conn: conn} do
      assert conn
             |> post(~p"/api/translations", translation: @create_attrs)
             |> response(:forbidden)
    end
  end

  describe "update/2" do
    @tag authentication: [role: "admin"]
    test "renders translation when data is valid", %{
      conn: conn,
      translation: %Translation{id: id} = translation
    } do
      put(conn, ~p"/api/translations/#{translation}", translation: @update_attrs)

      assert %{
               id: ^id,
               generated_prompt: "some updated generated_translation",
               request_time: 43,
               requested_by: 43,
               resource_id: 43,
               status: "error",
               response: %{}
             } = Repo.get(Translation, id)
    end

    @tag authentication: [role: "admin"]
    test "renders errors when data is invalid", %{conn: conn, translation: %{id: id}} do
      assert %{"errors" => errors} =
               conn
               |> put(~p"/api/translations/#{id}", translation: @invalid_attrs)
               |> json_response(:unprocessable_entity)

      assert errors != %{}
    end

    @tag authentication: [role: "user"]
    test "non-admin cannot update translations", %{
      conn: conn,
      translation: %{id: id}
    } do
      assert conn
             |> put(~p"/api/translations/#{id}", translation: @update_attrs)
             |> response(:forbidden)
    end
  end

  describe "delete/2" do
    @tag authentication: [role: "admin"]
    test "deletes chosen translation", %{conn: conn, translation: %{id: id}} do
      assert conn
             |> delete(~p"/api/translations/#{id}")
             |> response(:no_content)

      assert_error_sent :not_found, fn ->
        get(conn, ~p"/api/translations/#{id}")
      end
    end

    @tag authentication: [role: "user"]
    test "non-admin cannot delete translations", %{
      conn: conn,
      translation: %{id: id}
    } do
      assert conn
             |> delete(~p"/api/translations/#{id}")
             |> response(:forbidden)
    end
  end

  describe "request translation" do
    @tag authentication: [role: "admin"]
    test "renders ok when data is valid and creates translation", %{conn: conn} do
      Mox.expect(
        TdAi.ProviderClients.Mock,
        :chat_completion,
        1,
        &MockImpl.chat_completion/2
      )

      insert(:prompt,
        language: "en",
        resource_type: "translation",
        active: true,
        user_prompt_template: "Locales: {locales} - Fields: {fields}",
        provider:
          build(:provider,
            properties:
              build(:provider_properties,
                mock: build(:provider_properties_mock, model: "test_model")
              )
          )
      )

      params = %{
        resource_type: "business_concept",
        translation_body: %{
          "resource_name" => "Resource Name",
          "field_1" => "default_lang_value_1",
          "field_2" => "default_lang_value_2"
        },
        locales: ["es", "fr"],
        domain_ids: [1]
      }

      assert %{"data" => data} =
               conn
               |> post(~p"/api/translations/request", params)
               |> json_response(:ok)

      assert assert %{
                      "provider_properties" => %{"model" => "test_model", "api_key" => nil},
                      "messages" => [
                        %{"content" => "some system_prompt", "role" => "system"},
                        %{
                          "content" =>
                            "Locales: [\"es\",\"fr\"] - Fields: {\"field_1\":\"default_lang_value_1\",\"field_2\":\"default_lang_value_2\",\"resource_name\":\"Resource Name\"}",
                          "role" => "user"
                        }
                      ]
                    } = data

      assert [_, translation] = Repo.all(Translation)

      assert %{
               generated_prompt:
                 "Locales: [\"es\",\"fr\"] - Fields: {\"field_1\":\"default_lang_value_1\",\"field_2\":\"default_lang_value_2\",\"resource_name\":\"Resource Name\"}",
               status: "ok"
             } = translation
    end

    @tag authentication: [role: "admin"]
    test "renders error if no locales", %{conn: conn} do
      Mox.expect(
        TdAi.ProviderClients.Mock,
        :chat_completion,
        1,
        &MockImpl.chat_completion/2
      )

      insert(:prompt,
        language: "en",
        resource_type: "translation",
        active: true,
        user_prompt_template: "Locales: {locales} - Fields: {fields}",
        provider:
          build(:provider,
            properties:
              build(:provider_properties,
                mock: build(:provider_properties_mock, model: "test_model")
              )
          )
      )

      params = %{
        resource_type: "business_concept",
        translation_body: %{
          "resource_name" => "Resource Name",
          "field_1" => "default_lang_value_1",
          "field_2" => "default_lang_value_2"
        },
        locales: [],
        domain_ids: [1]
      }

      assert %{"error" => "locales must be a non-empty list"} =
               conn
               |> post(~p"/api/translations/request", params)
               |> json_response(:unprocessable_entity)
    end

    @tag authentication: [role: "admin"]
    test "renders error if no translation_body fields recived", %{conn: conn} do
      Mox.expect(
        TdAi.ProviderClients.Mock,
        :chat_completion,
        1,
        &MockImpl.chat_completion/2
      )

      insert(:prompt,
        language: "en",
        resource_type: "translation",
        active: true,
        user_prompt_template: "Locales: {locales} - Fields: {fields}",
        provider:
          build(:provider,
            properties:
              build(:provider_properties,
                mock: build(:provider_properties_mock, model: "test_model")
              )
          )
      )

      params = %{
        resource_type: "business_concept",
        translation_body: %{},
        locales: ["es", "fr"],
        domain_ids: [1]
      }

      assert %{"error" => "translation_body must be a non-empty map"} =
               conn
               |> post(~p"/api/translations/request", params)
               |> json_response(:unprocessable_entity)
    end

    @tag authentication: [role: "user", permissions: [:ai_business_concepts]]
    test "user with permission can request translation", %{conn: conn, domain: %{id: domain_id}} do
      Mox.expect(
        TdAi.ProviderClients.Mock,
        :chat_completion,
        1,
        &MockImpl.chat_completion/2
      )

      insert(:prompt,
        language: "en",
        resource_type: "translation",
        active: true,
        user_prompt_template: "Locales: {locales} - Fields: {fields}",
        provider:
          build(:provider,
            properties:
              build(:provider_properties,
                mock: build(:provider_properties_mock, model: "test_model")
              )
          )
      )

      params = %{
        resource_type: "business_concept",
        translation_body: %{
          "resource_name" => "Resource Name",
          "field_1" => "default_lang_value_1",
          "field_2" => "default_lang_value_2"
        },
        locales: ["es", "fr"],
        domain_ids: [domain_id]
      }

      assert %{"data" => data} =
               conn
               |> post(~p"/api/translations/request", params)
               |> json_response(:ok)

      assert assert %{
                      "provider_properties" => %{"model" => "test_model", "api_key" => nil},
                      "messages" => [
                        %{"content" => "some system_prompt", "role" => "system"},
                        %{
                          "content" =>
                            "Locales: [\"es\",\"fr\"] - Fields: {\"field_1\":\"default_lang_value_1\",\"field_2\":\"default_lang_value_2\",\"resource_name\":\"Resource Name\"}",
                          "role" => "user"
                        }
                      ]
                    } = data
    end

    @tag authentication: [role: "user"]
    test "user without permissions cannot request translation", %{
      conn: conn
    } do
      Mox.expect(
        TdAi.ProviderClients.Mock,
        :chat_completion,
        1,
        &MockImpl.chat_completion/2
      )

      insert(:prompt,
        language: "en",
        resource_type: "translation",
        active: true,
        user_prompt_template: "Locales: {locales} - Fields: {fields}",
        provider:
          build(:provider,
            properties:
              build(:provider_properties,
                mock: build(:provider_properties_mock, model: "test_model")
              )
          )
      )

      params = %{
        resource_type: "business_concept",
        translation_body: %{
          "resource_name" => "Resource Name",
          "field_1" => "default_lang_value_1",
          "field_2" => "default_lang_value_2"
        },
        locales: ["es", "fr"],
        domain_ids: [1]
      }

      assert %{"errors" => %{"detail" => "Forbidden"}} =
               conn
               |> post(~p"/api/translations/request", params)
               |> json_response(403)
    end
  end

  describe "availability_check" do
    @tag authentication: [role: "admin"]
    test "ok with translation prompt exist", %{conn: conn} do
      insert(:prompt, resource_type: "translation", language: "en", active: true)

      params = %{
        resource_type: "business_concept",
        domain_ids: [1]
      }

      assert %{"data" => %{"status" => "ok"}} =
               conn
               |> post(~p"/api/translations/availability_check", params)
               |> json_response(:ok)
    end

    @tag authentication: [role: "admin"]
    test "error for no translation prompt exist", %{conn: conn} do
      params = %{
        resource_type: "business_concept",
        domain_ids: [1]
      }

      assert %{"data" => %{"status" => "error", "reason" => "no active prompt"}} =
               conn
               |> post(~p"/api/translations/availability_check", params)
               |> json_response(:ok)
    end

    @tag authentication: [role: "user", permissions: [:ai_business_concepts]]
    test "user with permission allowed to translate", %{conn: conn, domain: %{id: domain_id}} do
      insert(:prompt, resource_type: "translation", language: "en", active: true)

      params = %{
        resource_type: "business_concept",
        domain_ids: [domain_id]
      }

      assert %{"data" => %{"status" => "ok"}} =
               conn
               |> post(~p"/api/translations/availability_check", params)
               |> json_response(:ok)
    end

    @tag authentication: [role: "user"]
    test "user without permission not allowed to translate", %{
      conn: conn
    } do
      insert(:prompt, resource_type: "translation", language: "en", active: true)

      params = %{
        resource_type: "business_concept",
        domain_ids: [1]
      }

      assert %{"data" => %{"status" => "error", "reason" => "forbidden"}} =
               conn
               |> post(~p"/api/translations/availability_check", params)
               |> json_response(:ok)
    end
  end
end
