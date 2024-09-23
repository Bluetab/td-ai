defmodule TdAi.Actions.ActionsTest do
  use TdAi.DataCase
  import TdAi.TestOperators

  alias TdAi.Actions.Actions

  describe "create/1" do
    test "insert valid data" do
      attrs = %{
        "name" => "AI Action Name",
        "user_id" => 1,
        "type" => "template_name",
        "dynamic_content" => %{"foo" => "bar"},
        "is_enabled" => true
      }

      assert {:ok, action} = Actions.create(attrs)

      assert %{
               id: _,
               name: "AI Action Name",
               user_id: 1,
               type: "template_name",
               dynamic_content: %{"foo" => "bar"},
               is_enabled: true,
               deleted_at: nil,
               inserted_at: _,
               updated_at: _
             } = action
    end

    test "with duplicated name and type return an error" do
      %{name: name, type: type} = insert(:action)

      attrs = %{
        "name" => name,
        "user_id" => 1,
        "type" => type,
        "dynamic_content" => %{"foo" => "bar"},
        "is_enabled" => true
      }

      assert {:error, %{errors: errors}} = Actions.create(attrs)

      assert errors == [
               name:
                 {"has already been taken",
                  [constraint: :unique, constraint_name: "actions_name_type_index"]}
             ]
    end

    test "error for invalid data" do
      attrs = %{
        "name" => 123,
        "user_id" => true,
        "type" => false,
        "dynamic_content" => "Bravo",
        "is_enabled" => "Charlie"
      }

      assert {:error, _} = Actions.create(attrs)
    end

    test "default values" do
      attrs = %{
        "name" => "AI Action Name",
        "user_id" => 1,
        "type" => "template_name"
      }

      assert {:ok, action} = Actions.create(attrs)

      assert %{
               dynamic_content: %{},
               is_enabled: true,
               deleted_at: nil
             } = action
    end
  end

  describe "list/1" do
    test "return all actions when no params" do
      action_1 = insert(:action)
      action_2 = insert(:action)

      assert [action_1, action_2] ||| Actions.list()
    end

    test "return all actions by params" do
      %{id: id} =
        action_1 = insert(:action, user_id: 1, is_enabled: false)

      action_2 = insert(:action, user_id: 2)
      action_3 = insert(:action, user_id: 1)

      assert [action_1, action_3] ||| Actions.list(%{"user_id" => 1})
      assert [action_2, action_3] ||| Actions.list(%{"is_enabled" => true})

      assert [action_1] ||| Actions.list(%{"is_enabled" => false, "user_id" => 1})
      assert [action_1] ||| Actions.list(%{"id" => id})
    end
  end

  describe "get/1" do
    test "return action by id" do
      %{id: id} = action = insert(:action)
      insert(:action)

      assert action == Actions.get(id)
    end
  end

  describe "update/2" do
    test "updates action" do
      %{id: id} = action = insert(:action)
      assert action == Actions.get(id)

      update_data = %{
        name: "Updated Ai Action Name",
        type: "updated_template_name",
        dynamic_content: %{"updated_foo" => "updated_bar"}
      }

      assert {:ok,
              %{
                name: "Updated Ai Action Name",
                type: "updated_template_name",
                dynamic_content: %{"updated_foo" => "updated_bar"}
              }} = Actions.update(action, update_data)
    end
  end

  describe "delete/2" do
    test "delete with no opts" do
      %{id: id} = action = insert(:action)
      assert {:ok, _} = Actions.delete(action)
      assert nil == Actions.get(id)
    end

    test "delete with opts" do
      %{id: id} = action = insert(:action)
      assert {:ok, _} = Actions.delete(action, logical: false)
      assert nil == Actions.get(id)
    end

    test "logical delete with opts" do
      %{id: id} = action = insert(:action)
      assert {:ok, _} = Actions.delete(action, logical: true)
      assert %{id: ^id, deleted_at: deleted_at, is_enabled: false} = Actions.get(id)
      refute is_nil(deleted_at)
    end
  end
end
