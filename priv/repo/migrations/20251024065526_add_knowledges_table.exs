defmodule TdAi.Repo.Migrations.AddKnowledgesTable do
  use Ecto.Migration

  def change do
    create table(:knowledges) do
      add :name, :string, null: false
      add :description, :text
      add :filename, :string, null: false
      add :format, :string, null: false
      add :md5, :string, null: false
      add :n_chunks, :integer, default: 0
      add :status, :string, default: "awaiting"

      timestamps(type: :utc_datetime)
    end

    create unique_index(:knowledges, [:md5])
    create index(:knowledges, [:status])
  end
end
