defmodule TdAi.Knowledges.KnowledgeTest do
  use TdAi.DataCase

  alias TdAi.Knowledges.Knowledge

  describe "Knowledge.changeset/2" do
    test "validates required fields" do
      assert %{errors: errors} = Knowledge.changeset(%Knowledge{}, %{})
      assert {"can't be blank", [validation: :required]} = errors[:name]
      assert {"can't be blank", [validation: :required]} = errors[:filename]
      assert {"can't be blank", [validation: :required]} = errors[:format]
      assert {"can't be blank", [validation: :required]} = errors[:md5]
    end

    test "validates fields types" do
      assert %{errors: errors} =
               Knowledge.changeset(%Knowledge{}, %{
                 name: 123,
                 filename: 123,
                 format: 123,
                 md5: 123,
                 n_chunks: "foo"
               })

      assert {"is invalid", [{:type, :string}, {:validation, :cast}]} = errors[:name]
      assert {"is invalid", [{:type, :string}, {:validation, :cast}]} = errors[:filename]
      assert {"is invalid", [{:type, :string}, {:validation, :cast}]} = errors[:format]
      assert {"is invalid", [{:type, :string}, {:validation, :cast}]} = errors[:md5]
      assert {"is invalid", [{:type, :integer}, {:validation, :cast}]} = errors[:n_chunks]
    end

    test "validates invalid md5 field" do
      assert %{
               errors: [
                 md5:
                   {"must be exactly 32 characters",
                    [{:count, 32}, {:validation, :length}, {:kind, :is}, {:type, :string}]}
               ]
             } =
               Knowledge.changeset(%Knowledge{}, %{
                 name: "Knowledge Name",
                 filename: "knowledge.txt",
                 format: "txt",
                 md5: "foo"
               })
    end

    test "validation with valid md5 field" do
      assert %{errors: []} =
               Knowledge.changeset(%Knowledge{}, %{
                 name: "Knowledge Name",
                 filename: "knowledge.txt",
                 format: "txt",
                 md5: "C0C2C04071B0C12AFE9745F6F9E83E9A"
               })
    end

    test "validates unique md5" do
      params = %{
        name: "Knowledge Name",
        filename: "knowledge.txt",
        format: "txt",
        md5: "C0C2C04071B0C12AFE9745F6F9E83E9A"
      }

      %Knowledge{}
      |> Knowledge.changeset(params)
      |> Repo.insert()

      assert {:error, changeset} =
               %Knowledge{}
               |> Knowledge.changeset(params)
               |> Repo.insert()

      assert changeset.errors == [
               md5:
                 {"has already been taken",
                  [constraint: :unique, constraint_name: "knowledges_md5_index"]}
             ]
    end

    test "validates status field" do
      params = %{
        name: "Knowledge Name",
        filename: "knowledge.txt",
        format: "txt",
        md5: "C0C2C04071B0C12AFE9745F6F9E83E9A",
        status: nil
      }

      assert %{errors: []} = Knowledge.changeset(%Knowledge{}, %{params | status: "awaiting"})
      assert %{errors: []} = Knowledge.changeset(%Knowledge{}, %{params | status: "processing"})
      assert %{errors: []} = Knowledge.changeset(%Knowledge{}, %{params | status: "completed"})
      assert %{errors: []} = Knowledge.changeset(%Knowledge{}, %{params | status: "failed"})

      assert %{
               errors: [
                 status:
                   {"must be awaiting, processing, completed, or failed",
                    [
                      {:validation, :inclusion},
                      {:enum, ["awaiting", "processing", "completed", "failed"]}
                    ]}
               ]
             } = Knowledge.changeset(%Knowledge{}, %{params | status: "foo"})
    end
  end
end
