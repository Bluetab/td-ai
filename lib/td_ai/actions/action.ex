defmodule TdAi.Actions.Action do
  @moduledoc """
    Ecto Schema module for ai actions
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "actions" do
    field(:name, :string)
    field(:user_id, :integer)
    field(:type, :string)
    field(:dynamic_content, :map, default: %{})
    field(:is_enabled, :boolean, default: true)
    field(:deleted_at, :utc_datetime_usec)

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(attrs), do: changeset(%__MODULE__{}, attrs)

  def changeset(%__MODULE__{} = action, attrs) do
    action
    |> cast(attrs, [
      :name,
      :user_id,
      :type,
      :dynamic_content,
      :is_enabled,
      :deleted_at
    ])
    |> validate_required([:name, :user_id, :type])
    |> update_change(:name, &String.trim/1)
    |> validate_length(:name, max: 255)
    |> unique_constraint([:name, :type])
  end
end
