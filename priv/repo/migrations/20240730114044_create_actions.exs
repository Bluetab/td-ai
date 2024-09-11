defmodule TdAi.Repo.Migrations.CreateActions do
  use Ecto.Migration

  def change do
    create table(:actions) do
      add(:name, :string, null: false)
      add(:user_id, :bigint, null: false)
      add(:type, :string, null: false)
      add(:dynamic_content, :map, default: %{})
      add(:is_enabled, :boolean, default: true, null: false)
      add(:deleted_at, :utc_datetime_usec, null: true)

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index("actions", [:name, :type])
  end
end
