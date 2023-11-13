defmodule TdAi.Repo.Migrations.CreateResourceMappings do
  use Ecto.Migration

  def change do
    create table(:resource_mappings) do
      add :name, :string
      add :fields, {:array, :map}

      timestamps()
    end
  end
end
