defmodule TdAi.FieldCompletionTest do
  alias TdAi.Completion
  use TdAi.DataCase

  alias TdAi.Completion.Suggestion
  alias TdAi.FieldCompletion
  alias TdCluster.TestHelpers.TdDdMock

  describe "run_completion/4" do
    test "runs completion and writes suggestion" do
      resource_id = 2
      requested_by = 8
      language = "en"
      resource_type = "data_structure"
      provider = "openai"
      model = "test_model"

      %{id: prompt_id} =
        insert(:prompt,
          language: language,
          resource_type: resource_type,
          active: true,
          provider: provider,
          model: model,
          user_prompt_template: "Structure: {resource} - Fields: {fields}",
          resource_mapping: build(:resource_mapping, fields: [%{source: "name"}])
        )

      TdDdMock.get_latest_structure_version(
        &Mox.expect/4,
        resource_id,
        {:ok, %{data_structure_id: resource_id, name: "ds_name"}}
      )

      assert {:ok,
              %{
                "model" => "test_model",
                "provider" => "openai",
                "system_prompt" => "some system_prompt",
                "user_prompt" =>
                  "Structure: {\"name\":\"ds_name\"} - Fields: [{\"name\":\"field\"}]"
              }} =
               FieldCompletion.run_completion(resource_type, resource_id, [%{name: "field"}],
                 language: language,
                 requested_by: requested_by
               )

      assert [
               %Suggestion{
                 response: %{
                   "model" => "test_model",
                   "provider" => "openai",
                   "system_prompt" => "some system_prompt",
                   "user_prompt" =>
                     "Structure: {\"name\":\"ds_name\"} - Fields: [{\"name\":\"field\"}]"
                 },
                 resource_id: ^resource_id,
                 generated_prompt:
                   "Structure: {\"name\":\"ds_name\"} - Fields: [{\"name\":\"field\"}]",
                 requested_by: ^requested_by,
                 prompt_id: ^prompt_id
               }
             ] = Completion.list_suggestions()
    end
  end
end
