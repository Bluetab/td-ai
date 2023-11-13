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

    test "create_resource_mapping/1 with valid data creates a resource_mapping" do
      valid_attrs = %{name: "some name", fields: [%{source: "some source"}]}

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
      %{id: resource_mapping_id} = insert(:resource_mapping)

      valid_attrs = %{
        name: "some name",
        language: "some language",
        resource_type: "some resource_type",
        system_prompt: "some system_prompt",
        user_prompt_template: "some user_prompt_template",
        model: "some model",
        provider: "some provider",
        resource_mapping_id: resource_mapping_id
      }

      assert {:ok, %Prompt{} = prompt} = Completion.create_prompt(valid_attrs)
      assert prompt.name == "some name"
      assert prompt.language == "some language"
      assert prompt.resource_type == "some resource_type"
      assert prompt.system_prompt == "some system_prompt"
      assert prompt.user_prompt_template == "some user_prompt_template"
      assert prompt.model == "some model"
      assert prompt.provider == "some provider"
      assert prompt.resource_mapping_id == resource_mapping_id
    end

    test "create_prompt/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Completion.create_prompt(@invalid_attrs)
    end

    test "update_prompt/2 with valid data updates the prompt" do
      prompt = insert(:prompt)

      update_attrs = %{
        name: "some updated name",
        language: "some updated language",
        resource_type: "some updated resource_type",
        system_prompt: "some updated system_prompt",
        user_prompt_template: "some updated user_prompt_template",
        model: "some updated model",
        provider: "some updated provider"
      }

      assert {:ok, %Prompt{} = prompt} = Completion.update_prompt(prompt, update_attrs)
      assert prompt.name == "some updated name"
      assert prompt.language == "some updated language"
      assert prompt.resource_type == "some updated resource_type"
      assert prompt.system_prompt == "some updated system_prompt"
      assert prompt.user_prompt_template == "some updated user_prompt_template"
      assert prompt.model == "some updated model"
      assert prompt.provider == "some updated provider"
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

    test "get_prompt_by_resource_and_language/1 returns nil if does not exist" do
      assert is_nil(Completion.get_prompt_by_resource_and_language("foo", "bar"))
    end

    test "get_prompt_by_resource_and_language/1 preloads resource_mapping" do
      insert(:prompt,
        name: "resource1",
        resource_type: "foo",
        language: "bar",
        active: true,
        resource_mapping: build(:resource_mapping, name: "rm1")
      )

      assert %Prompt{name: "resource1", resource_mapping: %{name: "rm1"}} =
               Completion.get_prompt_by_resource_and_language("foo", "bar")
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

      valid_attrs = %{
        response: %{},
        resource_id: 42,
        generated_prompt: "some generated_prompt",
        request_time: 42,
        requested_by: 42,
        prompt_id: prompt_id
      }

      assert {:ok, %Suggestion{} = suggestion} = Completion.create_suggestion(valid_attrs)
      assert suggestion.response == %{}
      assert suggestion.resource_id == 42
      assert suggestion.generated_prompt == "some generated_prompt"
      assert suggestion.request_time == 42
      assert suggestion.requested_by == 42
      assert suggestion.prompt_id == prompt_id
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
        request_time: 43,
        requested_by: 43
      }

      assert {:ok, %Suggestion{} = suggestion} =
               Completion.update_suggestion(suggestion, update_attrs)

      assert suggestion.response == %{}
      assert suggestion.resource_id == 43
      assert suggestion.generated_prompt == "some updated generated_prompt"
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
end
