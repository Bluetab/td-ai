defmodule TdAi.Actions.ActionTest do
  use TdAi.DataCase

  alias Ecto.Changeset
  alias TdAi.Actions.Action

  describe "changeset/2" do
    test "validate required fields" do
      assert %{errors: errors} = Action.changeset(%{})
      assert {"can't be blank", [validation: :required]} = errors[:name]
      assert {"can't be blank", [validation: :required]} = errors[:user_id]
      assert {"can't be blank", [validation: :required]} = errors[:type]
    end

    test "validate fields types" do
      invalid_data = %{
        name: 123,
        user_id: "Alpha",
        type: false,
        dynamic_content: "Bravo",
        is_enabled: "Charlie",
        deleted_at: "Delta"
      }

      assert %{errors: errors} = Action.changeset(invalid_data)

      assert {"is invalid", [{:type, :string}, {:validation, :cast}]} = errors[:name]
      assert {"is invalid", [{:type, :integer}, {:validation, :cast}]} = errors[:user_id]
      assert {"is invalid", [{:type, :string}, {:validation, :cast}]} = errors[:type]
      assert {"is invalid", [{:type, :map}, {:validation, :cast}]} = errors[:dynamic_content]
      assert {"is invalid", [{:type, :boolean}, {:validation, :cast}]} = errors[:is_enabled]

      assert {"is invalid", [{:type, :utc_datetime_usec}, {:validation, :cast}]} =
               errors[:deleted_at]
    end

    test "validate valid fields" do
      valid_data = %{
        name: "AI Action Name",
        user_id: 1,
        type: "Bravo",
        dynamic_content: %{"foo" => "bar"},
        is_enabled: true,
        deleted_at: "2024-01-01 00:00"
      }

      assert %{errors: []} = Action.changeset(valid_data)
    end

    test "trims name" do
      data = %{
        name: "  foo   ",
        user_id: 1,
        type: "Bravo",
        dynamic_content: %{"foo" => "bar"},
        is_enabled: true,
        deleted_at: "2024-01-01 00:00"
      }

      changeset = Action.changeset(data)
      assert changeset.valid?
      assert Changeset.get_change(changeset, :name) == "foo"
    end
  end
end
