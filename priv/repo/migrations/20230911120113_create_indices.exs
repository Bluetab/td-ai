defmodule TdAi.Repo.Migrations.CreateIndices do
  use Ecto.Migration

  def change do
    create table(:indices) do
      add :collection_name, :string
      add :embedding, :string
      add :mapping, {:array, :string}

      timestamps()
    end
  end
end
