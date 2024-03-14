defmodule TdAi.CompletionTest do
  use TdAi.DataCase

  alias TdAi.Completion

  describe "resource_mappings" do
    alias TdAi.Completion.ResourceMapping

    @invalid_attrs %{name: nil, fields: nil}

    test "list_resource_mappings/0 returns all resource_mappings" do
      resource_mapping = insert(:resource_mapping)
      assert Completion.list_resource_mappings() == [resource_mapping]
    end

    test "get_resource_mapping!/1 returns the resource_mapping with given id" do
      resource_mapping = insert(:resource_mapping)
      assert Completion.get_resource_mapping!(resource_mapping.id) == resource_mapping
    end

    test "get_resource_mapping_by_selector/2 returns a resource_mapping for resource_type" do
      resource_type = "some_type"

      resource_mapping = insert(:resource_mapping, resource_type: resource_type)

      assert Completion.get_resource_mapping_by_selector(resource_type) ==
               resource_mapping
    end

    test "get_resource_mapping_by_selector/2 exactly matches the selector" do
      resource_type = "some_type"

      insert(:resource_mapping, resource_type: resource_type)
      insert(:resource_mapping, resource_type: resource_type, selector: %{"a" => 1})

      resource_mapping =
        insert(:resource_mapping, resource_type: resource_type, selector: %{"a" => 1, "b" => 2})

      assert Completion.get_resource_mapping_by_selector(resource_type, %{b: 2, a: 1}) ==
               resource_mapping
    end

    test "get_resource_mapping_by_selector!/2 does not matches any selector" do
      resource_type = "some_type"

      insert(:resource_mapping, resource_type: resource_type, selector: %{"a" => 1})

      assert is_nil(Completion.get_resource_mapping_by_selector(resource_type))
    end

    test "create_resource_mapping/1 with valid data creates a resource_mapping" do
      resource_type = "some_type"

      valid_attrs = %{
        name: "some name",
        fields: [%{source: "some source"}],
        resource_type: resource_type
      }

      assert {:ok, %ResourceMapping{} = resource_mapping} =
               Completion.create_resource_mapping(valid_attrs)

      assert resource_mapping.name == "some name"
      assert [%{source: "some source"}] = resource_mapping.fields
    end

    test "create_resource_mapping/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Completion.create_resource_mapping(@invalid_attrs)
    end

    test "update_resource_mapping/2 with valid data updates the resource_mapping" do
      resource_mapping = insert(:resource_mapping)

      update_attrs = %{
        name: "some updated name",
        fields: [%{source: "updated", target: "target"}]
      }

      assert {:ok, %ResourceMapping{} = resource_mapping} =
               Completion.update_resource_mapping(resource_mapping, update_attrs)

      assert resource_mapping.name == "some updated name"
      assert [%{source: "updated", target: "target"}] = resource_mapping.fields
    end

    test "update_resource_mapping/2 with invalid data returns error changeset" do
      resource_mapping = insert(:resource_mapping)

      assert {:error, %Ecto.Changeset{}} =
               Completion.update_resource_mapping(resource_mapping, @invalid_attrs)

      assert resource_mapping == Completion.get_resource_mapping!(resource_mapping.id)
    end

    test "delete_resource_mapping/1 deletes the resource_mapping" do
      resource_mapping = insert(:resource_mapping)
      assert {:ok, %ResourceMapping{}} = Completion.delete_resource_mapping(resource_mapping)

      assert_raise Ecto.NoResultsError, fn ->
        Completion.get_resource_mapping!(resource_mapping.id)
      end
    end

    test "change_resource_mapping/1 returns a resource_mapping changeset" do
      resource_mapping = insert(:resource_mapping)
      assert %Ecto.Changeset{} = Completion.change_resource_mapping(resource_mapping)
    end
  end

  describe "prompts" do
    alias TdAi.Completion.Prompt

    @invalid_attrs %{
      active: nil,
      name: nil,
      language: nil,
      resource_type: nil,
      system_prompt: nil,
      user_prompt_template: nil
    }

    test "list_prompts/0 returns all prompts" do
      prompt = insert(:prompt)
      assert Completion.list_prompts() ||| [prompt]
    end

    test "get_prompt!/1 returns the prompt with given id" do
      prompt = insert(:prompt)
      assert prompt <~> Completion.get_prompt!(prompt.id)
    end

    test "create_prompt/1 with valid data creates a prompt" do
      %{id: provider_id} = insert(:provider)

      valid_attrs = %{
        name: "some name",
        language: "some language",
        resource_type: "some resource_type",
        system_prompt: "some system_prompt",
        user_prompt_template: "some user_prompt_template",
        provider_id: provider_id
      }

      assert {:ok, %Prompt{} = prompt} = Completion.create_prompt(valid_attrs)
      assert prompt.name == "some name"
      assert prompt.language == "some language"
      assert prompt.resource_type == "some resource_type"
      assert prompt.system_prompt == "some system_prompt"
      assert prompt.user_prompt_template == "some user_prompt_template"
      assert prompt.provider_id == provider_id
    end

    test "create_prompt/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Completion.create_prompt(@invalid_attrs)
    end

    test "update_prompt/2 with valid data updates the prompt" do
      %{id: provider_id} = insert(:provider)
      prompt = insert(:prompt)

      update_attrs = %{
        name: "some updated name",
        language: "some updated language",
        resource_type: "some updated resource_type",
        system_prompt: "some updated system_prompt",
        user_prompt_template: "some updated user_prompt_template",
        provider_id: provider_id
      }

      assert {:ok, %Prompt{} = prompt} = Completion.update_prompt(prompt, update_attrs)
      assert prompt.name == "some updated name"
      assert prompt.language == "some updated language"
      assert prompt.resource_type == "some updated resource_type"
      assert prompt.system_prompt == "some updated system_prompt"
      assert prompt.user_prompt_template == "some updated user_prompt_template"
      assert prompt.provider_id == provider_id
    end

    test "update_prompt/2 with invalid data returns error changeset" do
      prompt = insert(:prompt)
      assert {:error, %Ecto.Changeset{}} = Completion.update_prompt(prompt, @invalid_attrs)
      assert prompt <~> Completion.get_prompt!(prompt.id)
    end

    test "delete_prompt/1 deletes the prompt" do
      prompt = insert(:prompt)
      assert {:ok, %Prompt{}} = Completion.delete_prompt(prompt)
      assert_raise Ecto.NoResultsError, fn -> Completion.get_prompt!(prompt.id) end
    end

    test "change_prompt/1 returns a prompt changeset" do
      prompt = insert(:prompt)
      assert %Ecto.Changeset{} = Completion.change_prompt(prompt)
    end

    test "get_prompt_by_resource_and_language/1 returns a prompt" do
      insert(:prompt, name: "resource1", resource_type: "foo", language: "bar", active: true)
      insert(:prompt, name: "resource2", resource_type: "foo", language: "bar", active: false)

      assert %Prompt{name: "resource1"} =
               Completion.get_prompt_by_resource_and_language("foo", "bar")
    end

    test "get_prompt_by_resource_and_language/1 enriches provider and secret" do
      model = "model1"
      api_key = "secret"

      insert(:prompt,
        resource_type: "foo",
        language: "bar",
        active: true,
        provider:
          build(:provider,
            properties:
              build(:provider_properties,
                mock: build(:provider_properties_mock, model: model, api_key: api_key)
              )
          )
      )

      assert %Prompt{
               provider: %{
                 properties: %{
                   mock: %{
                     model: ^model,
                     api_key: ^api_key
                   }
                 }
               }
             } =
               Completion.get_prompt_by_resource_and_language("foo", "bar")
    end

    test "get_prompt_by_resource_and_language/1 returns nil if does not exist" do
      assert is_nil(Completion.get_prompt_by_resource_and_language("foo", "bar"))
    end
  end

  describe "suggestions" do
    alias TdAi.Completion.Suggestion

    @invalid_attrs %{
      response: nil,
      resource_id: nil,
      generated_prompt: nil,
      request_time: nil,
      requested_by: nil
    }

    test "list_suggestions/0 returns all suggestions" do
      suggestion = insert(:suggestion)
      assert Completion.list_suggestions() ||| [suggestion]
    end

    test "get_suggestion!/1 returns the suggestion with given id" do
      suggestion = insert(:suggestion)
      assert Completion.get_suggestion!(suggestion.id) <~> suggestion
    end

    test "create_suggestion/1 with valid data creates a suggestion" do
      %{id: prompt_id} = insert(:prompt)
      %{id: resource_mapping_id} = insert(:resource_mapping)

      valid_attrs = %{
        response: %{},
        resource_id: 42,
        generated_prompt: "some generated_prompt",
        status: "ok",
        request_time: 42,
        requested_by: 42,
        prompt_id: prompt_id,
        resource_mapping_id: resource_mapping_id
      }

      assert {:ok, %Suggestion{} = suggestion} = Completion.create_suggestion(valid_attrs)
      assert suggestion.response == %{}
      assert suggestion.resource_id == 42
      assert suggestion.generated_prompt == "some generated_prompt"
      assert suggestion.status == "ok"
      assert suggestion.request_time == 42
      assert suggestion.requested_by == 42
      assert suggestion.prompt_id == prompt_id
      assert suggestion.resource_mapping_id == resource_mapping_id
    end

    test "create_suggestion/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Completion.create_suggestion(@invalid_attrs)
    end

    test "update_suggestion/2 with valid data updates the suggestion" do
      suggestion = insert(:suggestion)

      update_attrs = %{
        response: %{},
        resource_id: 43,
        generated_prompt: "some updated generated_prompt",
        status: "error",
        request_time: 43,
        requested_by: 43
      }

      assert {:ok, %Suggestion{} = suggestion} =
               Completion.update_suggestion(suggestion, update_attrs)

      assert suggestion.response == %{}
      assert suggestion.resource_id == 43
      assert suggestion.generated_prompt == "some updated generated_prompt"
      assert suggestion.status == "error"
      assert suggestion.request_time == 43
      assert suggestion.requested_by == 43
    end

    test "update_suggestion/2 with invalid data returns error changeset" do
      suggestion = insert(:suggestion)

      assert {:error, %Ecto.Changeset{}} =
               Completion.update_suggestion(suggestion, @invalid_attrs)

      assert suggestion <~> Completion.get_suggestion!(suggestion.id)
    end

    test "delete_suggestion/1 deletes the suggestion" do
      suggestion = insert(:suggestion)
      assert {:ok, %Suggestion{}} = Completion.delete_suggestion(suggestion)
      assert_raise Ecto.NoResultsError, fn -> Completion.get_suggestion!(suggestion.id) end
    end

    test "change_suggestion/1 returns a suggestion changeset" do
      suggestion = insert(:suggestion)
      assert %Ecto.Changeset{} = Completion.change_suggestion(suggestion)
    end
  end

  describe "providers" do
    alias TdAi.Completion.Provider
    alias TdAi.Completion.ProviderProperties
    alias TdAi.Vault

    @valid_attrs %{
      name: "some name",
      type: "mock",
      properties: %{
        model: "model",
        api_key: "secret"
      }
    }

    @invalid_attrs %{name: nil, type: nil, properties: nil}

    test "list_providers/0 returns all providers" do
      provider = insert(:provider)
      assert Completion.list_providers() == [provider]
    end

    test "get_provider!/1 returns the provider with given id" do
      provider = insert(:provider)
      assert Completion.get_provider!(provider.id) == provider
    end

    test "create_provider/1 with valid data creates a provider and write secrets" do
      assert {:ok, %Provider{} = provider} = Completion.create_provider(@valid_attrs)
      assert provider.name == "some name"
      assert provider.type == "mock"

      assert %{mock: %{} = properties} = provider.properties
      assert properties == %ProviderProperties.Mock{model: "model", api_key: nil}

      secrets =
        provider
        |> Provider.vault_key()
        |> Vault.read_secrets()

      assert secrets == %{"api_key" => "secret"}
    end

    test "create_provider/1 secrets are not written in the database" do
      assert {:ok, %Provider{id: id} = provider} = Completion.create_provider(@valid_attrs)
      assert provider.name == "some name"
      assert provider.type == "mock"

      assert %{mock: %{} = properties} = provider.properties
      assert properties == %ProviderProperties.Mock{model: "model", api_key: nil}

      assert %Provider{properties: %{mock: %{model: "model", api_key: nil}}} =
               Repo.get(Provider, id)
    end

    test "create_provider/1 fails with invalid provider type" do
      invalid_type_attrs = %{
        name: "some name",
        type: "invalid",
        properties: %{}
      }

      assert {:error,
              %{
                errors: [
                  type: {"is invalid", _}
                ],
                valid?: false
              }} =
               Completion.create_provider(invalid_type_attrs)
    end

    test "create_provider/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Completion.create_provider(@invalid_attrs)
    end

    test "update_provider/2 with valid data updates the provider" do
      provider = insert(:provider)

      update_attrs = %{
        name: "some updated name",
        type: "openai",
        properties: %{
          model: "new_model",
          organization_key: "organization_key"
        }
      }

      assert {:ok, %Provider{} = provider} = Completion.update_provider(provider, update_attrs)
      assert provider.name == "some updated name"
      assert provider.type == "openai"

      assert %{
               openai: %{
                 model: "new_model",
                 organization_key: "organization_key"
               }
             } =
               provider.properties
    end

    test "update_provider/2 updates secrets only with non-empty value" do
      assert {:ok, %Provider{} = provider} = Completion.create_provider(@valid_attrs)
      provider_vault_key = Provider.vault_key(provider)

      assert Vault.read_secrets(provider_vault_key) == %{"api_key" => "secret"}

      update_attrs = %{properties: %{model: "model1"}}
      assert {:ok, _} = Completion.update_provider(provider, update_attrs)

      assert Vault.read_secrets(provider_vault_key) == %{"api_key" => "secret"}

      update_attrs = %{properties: %{model: "model1", api_key: nil}}
      assert {:ok, _} = Completion.update_provider(provider, update_attrs)

      assert Vault.read_secrets(provider_vault_key) == %{"api_key" => "secret"}

      update_attrs = %{properties: %{model: "model1", api_key: ""}}
      assert {:ok, _} = Completion.update_provider(provider, update_attrs)

      assert Vault.read_secrets(provider_vault_key) == %{"api_key" => "secret"}

      update_attrs = %{properties: %{model: "model1", api_key: "otro"}}
      assert {:ok, _} = Completion.update_provider(provider, update_attrs)

      assert Vault.read_secrets(provider_vault_key) == %{"api_key" => "otro"}
    end

    test "update_provider/2 with invalid data returns error changeset" do
      provider = insert(:provider)
      assert {:error, %Ecto.Changeset{}} = Completion.update_provider(provider, @invalid_attrs)
      assert provider == Completion.get_provider!(provider.id)
    end

    test "enrich_provider_secrets/1 fills the provider properties secrets" do
      assert {:ok, %Provider{} = provider} = Completion.create_provider(@valid_attrs)

      assert %{
               properties: %{
                 mock: %{
                   model: "model",
                   api_key: "secret"
                 }
               }
             } = Completion.enrich_provider_secrets(provider)
    end

    test "delete_provider/1 deletes the provider" do
      provider = insert(:provider)
      assert {:ok, %Provider{}} = Completion.delete_provider(provider)
      assert_raise Ecto.NoResultsError, fn -> Completion.get_provider!(provider.id) end
    end

    test "change_provider/1 returns a provider changeset" do
      provider = insert(:provider)
      assert %Ecto.Changeset{} = Completion.change_provider(provider)
    end
  end
end
