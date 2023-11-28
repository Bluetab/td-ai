defmodule TdAi.Repo.Migrations.CreateResourceMappings do
  use Ecto.Migration

  def change do
    create table(:resource_mappings) do
      add :name, :string
      add :fields, {:array, :map}
      add :resource_type, :string
      add :selector, :map, null: false, default: %{}

      timestamps()
    end

    create unique_index(:resource_mappings, [:resource_type, :selector])
  end
end
