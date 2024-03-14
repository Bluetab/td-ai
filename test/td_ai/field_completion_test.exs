defmodule TdAi.FieldCompletionTest do
  alias TdAi.Completion
  use TdAi.DataCase

  alias TdAi.Completion.Suggestion
  alias TdAi.FieldCompletion
  alias TdAi.ProviderClients.MockImpl
  alias TdCluster.TestHelpers.TdDdMock

  describe "resource_field_completion/4" do
    test "runs completion and writes suggestion" do
      resource_id = 2
      requested_by = 8
      language = "en"
      resource_type = "data_structure"
      model = "test_model"
      api_key = "secret"

      %{id: prompt_id} =
        insert(:prompt,
          language: language,
          resource_type: resource_type,
          active: true,
          user_prompt_template: "Structure: {resource} - Fields: {fields}",
          provider:
            build(:provider,
              properties:
                build(:provider_properties,
                  mock: build(:provider_properties_mock, model: model, api_key: api_key)
                )
            )
        )

      %{id: resource_mapping_id} =
        insert(:resource_mapping, fields: [%{source: "name"}], resource_type: resource_type)

      TdDdMock.get_latest_structure_version(
        &Mox.expect/4,
        resource_id,
        {:ok, %{data_structure_id: resource_id, name: "ds_name"}}
      )

      Mox.expect(
        TdAi.ProviderClients.Mock,
        :chat_completion,
        1,
        &MockImpl.chat_completion/2
      )

      assert %{
               "provider_properties" => %{"api_key" => "secret", "model" => "test_model"},
               "messages" => [
                 %{"content" => "some system_prompt", "role" => "system"},
                 %{
                   "content" =>
                     "Structure: {\"name\":\"ds_name\"} - Fields: [{\"name\":\"field\"}]",
                   "role" => "user"
                 }
               ]
             } =
               FieldCompletion.resource_field_completion(
                 resource_type,
                 resource_id,
                 [%{name: "field"}],
                 language: language,
                 requested_by: requested_by
               )

      assert [
               %Suggestion{
                 response: %{
                   "provider_properties" => %{"model" => "test_model", "api_key" => "secret"},
                   "messages" => [
                     %{"content" => "some system_prompt", "role" => "system"},
                     %{
                       "content" =>
                         "Structure: {\"name\":\"ds_name\"} - Fields: [{\"name\":\"field\"}]",
                       "role" => "user"
                     }
                   ]
                 },
                 resource_id: ^resource_id,
                 generated_prompt:
                   "Structure: {\"name\":\"ds_name\"} - Fields: [{\"name\":\"field\"}]",
                 requested_by: ^requested_by,
                 prompt_id: ^prompt_id,
                 resource_mapping_id: ^resource_mapping_id,
                 status: "ok"
               }
             ] = Completion.list_suggestions()
    end

    test "ignores json markdown on response" do
      resource_id = 2
      requested_by = 8
      language = "en"
      resource_type = "data_structure"
      model = "test_model"

      %{id: prompt_id} =
        insert(:prompt,
          language: language,
          resource_type: resource_type,
          active: true,
          user_prompt_template: "Structure: {resource} - Fields: {fields}",
          provider:
            build(:provider,
              properties:
                build(:provider_properties, mock: build(:provider_properties_mock, model: model))
            )
        )

      %{id: resource_mapping_id} =
        insert(:resource_mapping, fields: [%{source: "name"}], resource_type: resource_type)

      TdDdMock.get_latest_structure_version(
        &Mox.expect/4,
        resource_id,
        {:ok, %{data_structure_id: resource_id, name: "ds_name"}}
      )

      Mox.expect(
        TdAi.ProviderClients.Mock,
        :chat_completion,
        1,
        &MockImpl.chat_completion/2
      )

      assert %{
               "provider_properties" => %{"model" => "test_model", "api_key" => nil},
               "messages" => [
                 %{"content" => "some system_prompt", "role" => "system"},
                 %{
                   "content" =>
                     "Structure: {\"name\":\"ds_name\"} - Fields: [{\"name\":\"field\"}]",
                   "role" => "user"
                 }
               ]
             } =
               FieldCompletion.resource_field_completion(
                 resource_type,
                 resource_id,
                 [%{name: "field"}],
                 language: language,
                 requested_by: requested_by
               )

      assert [
               %Suggestion{
                 response: %{
                   "provider_properties" => %{"model" => "test_model", "api_key" => nil},
                   "messages" => [
                     %{"content" => "some system_prompt", "role" => "system"},
                     %{
                       "content" =>
                         "Structure: {\"name\":\"ds_name\"} - Fields: [{\"name\":\"field\"}]",
                       "role" => "user"
                     }
                   ]
                 },
                 resource_id: ^resource_id,
                 generated_prompt:
                   "Structure: {\"name\":\"ds_name\"} - Fields: [{\"name\":\"field\"}]",
                 requested_by: ^requested_by,
                 prompt_id: ^prompt_id,
                 resource_mapping_id: ^resource_mapping_id,
                 status: "ok"
               }
             ] = Completion.list_suggestions()
    end

    test "writes error suggestion if response is not parseable" do
      resource_id = 2
      requested_by = 8
      language = "en"
      resource_type = "data_structure"
      model = "test_model"

      %{id: prompt_id} =
        insert(:prompt,
          language: language,
          resource_type: resource_type,
          active: true,
          user_prompt_template: "Structure: {resource} - Fields: {fields}",
          provider:
            build(:provider,
              properties:
                build(:provider_properties, mock: build(:provider_properties_mock, model: model))
            )
        )

      %{id: resource_mapping_id} =
        insert(:resource_mapping, fields: [%{source: "name"}], resource_type: resource_type)

      TdDdMock.get_latest_structure_version(
        &Mox.expect/4,
        resource_id,
        {:ok, %{data_structure_id: resource_id, name: "ds_name"}}
      )

      Mox.expect(TdAi.ProviderClients.Mock, :chat_completion, 1, fn _, _ ->
        response = "invalid json"
        {:ok, response}
      end)

      assert {:error, _} =
               FieldCompletion.resource_field_completion(
                 resource_type,
                 resource_id,
                 [%{name: "field"}],
                 language: language,
                 requested_by: requested_by
               )

      assert [
               %Suggestion{
                 response: %{"message" => "Invalid JSON response from AI Provider: invalid json"},
                 resource_id: ^resource_id,
                 generated_prompt:
                   "Structure: {\"name\":\"ds_name\"} - Fields: [{\"name\":\"field\"}]",
                 requested_by: ^requested_by,
                 prompt_id: ^prompt_id,
                 resource_mapping_id: ^resource_mapping_id,
                 status: "error"
               }
             ] = Completion.list_suggestions()
    end
  end

  describe "available_resource_mapping/2" do
    test "returns true if resource_mapping is available" do
      resource_type = "data_structure"
      selector = %{"selector" => "foo"}

      insert(:resource_mapping, selector: selector, resource_type: resource_type)

      assert FieldCompletion.available_resource_mapping(resource_type, selector)
    end

    test "returns false if resource_mapping is not available" do
      resource_type = "data_structure"
      selector = %{"selector" => "foo"}

      refute FieldCompletion.available_resource_mapping(resource_type, selector)
    end
  end
end
