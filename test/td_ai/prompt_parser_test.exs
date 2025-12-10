defmodule TdAi.PromptParserTest do
  use TdAi.DataCase

  alias TdAi.PromptParser
  alias TdCluster.TestHelpers.TdDdMock

  describe "translates data_structure resource" do
    test "parses data_structure fields" do
      data_structure_id = 8

      resource_mapping =
        insert(:resource_mapping,
          fields: [
            %{
              source: "name",
              target: "structure_name"
            }
          ]
        )

      TdDdMock.get_latest_structure_version(
        &Mox.expect/4,
        data_structure_id,
        {:ok, %{data_structure_id: data_structure_id, name: "ds_name"}}
      )

      assert %{"structure_name" => "ds_name"} =
               PromptParser.parse(resource_mapping, "data_structure", data_structure_id)
    end

    test "parses data_structure nested field" do
      data_structure_id = 8

      resource_mapping =
        insert(:resource_mapping,
          fields: [
            %{
              source: "metadata.list",
              target: "some_list.nested"
            },
            %{
              source: "metadata.another",
              target: "value"
            },
            %{
              source: "name",
              target: "some_list.name"
            }
          ]
        )

      TdDdMock.get_latest_structure_version(
        &Mox.expect/4,
        data_structure_id,
        {:ok,
         %{
           data_structure_id: data_structure_id,
           name: "ds_name",
           metadata: %{"list" => [1, 2, 3], "another" => "value"}
         }}
      )

      assert %{
               "some_list" => %{
                 "name" => "ds_name",
                 "nested" => [1, 2, 3]
               },
               "value" => "value"
             } = PromptParser.parse(resource_mapping, "data_structure", data_structure_id)
    end

    test "uses source value if target is not provided" do
      data_structure_id = 8

      resource_mapping =
        insert(:resource_mapping,
          fields: [
            %{
              source: "name"
            }
          ]
        )

      TdDdMock.get_latest_structure_version(
        &Mox.expect/4,
        data_structure_id,
        {:ok, %{data_structure_id: data_structure_id, name: "ds_name"}}
      )

      assert %{"name" => "ds_name"} =
               PromptParser.parse(resource_mapping, "data_structure", data_structure_id)
    end

    test "if source field is not available fills with nil" do
      data_structure_id = 8

      resource_mapping =
        insert(:resource_mapping,
          fields: [
            %{
              source: "invalid_field",
              target: "some_field"
            }
          ]
        )

      TdDdMock.get_latest_structure_version(
        &Mox.expect/4,
        data_structure_id,
        {:ok, %{data_structure_id: data_structure_id, name: "ds_name"}}
      )

      assert %{"some_field" => nil} =
               PromptParser.parse(resource_mapping, "data_structure", data_structure_id)
    end

    test "invalid target combination will return controlled error" do
      data_structure_id = 8

      resource_mapping =
        insert(:resource_mapping,
          fields: [
            %{
              source: "name",
              target: "some_field"
            },
            %{
              source: "other_field",
              target: "some_field.nested"
            }
          ]
        )

      TdDdMock.get_latest_structure_version(
        &Mox.expect/4,
        data_structure_id,
        {:ok, %{data_structure_id: data_structure_id, name: "ds_name"}}
      )

      assert :error = PromptParser.parse(resource_mapping, "data_structure", data_structure_id)
    end

    test "invalid resource access" do
      data_structure_id = 8

      resource_mapping =
        insert(:resource_mapping,
          fields: [
            %{
              source: "invalid.nested.field",
              target: "some_field"
            }
          ]
        )

      TdDdMock.get_latest_structure_version(
        &Mox.expect/4,
        data_structure_id,
        {:ok, %{data_structure_id: data_structure_id, name: "ds_name"}}
      )

      assert %{"some_field" => nil} =
               PromptParser.parse(resource_mapping, "data_structure", data_structure_id)
    end
  end

  describe "parsers user prompt" do
    test "fills user prompt with fields and resource values" do
      prompt =
        insert(:prompt,
          user_prompt_template: """
            Data structure: {resource}
            Fields to generate: {fields}
          """
        )

      fields = [
        %{name: "field1", description: "Description"}
      ]

      resource = %{
        "name" => "ds_name",
        "metadata" => %{
          "database" => "value"
        }
      }

      result = PromptParser.generate_user_prompt(prompt, fields, resource, [])

      assert result =~ ~r/Data structure: (.+)\n/
      resource_json = Regex.run(~r/Data structure: (.+)\n/, result) |> List.last()
      assert {:ok, decoded_resource} = Jason.decode(resource_json)
      assert decoded_resource == resource

      assert result =~ ~r/Fields to generate: (.+)\n/
      fields_json = Regex.run(~r/Fields to generate: (.+)\n/, result) |> List.last()
      assert {:ok, decoded_fields} = Jason.decode(fields_json)
      assert decoded_fields == Jason.decode!(Jason.encode!(fields))
    end
  end
end
