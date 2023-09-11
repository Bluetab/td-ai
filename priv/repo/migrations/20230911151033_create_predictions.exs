defmodule TdAi.Repo.Migrations.CreatePredictions do
  use Ecto.Migration

  def change do
    create table(:predictions) do
      add :mapping, {:array, :string}
      add :result, {:array, :map}
      add :data_structure_id, :integer
      add :index_id, references(:indices, on_delete: :nothing)

      timestamps()
    end

    create index(:predictions, [:index_id])
  end
end
