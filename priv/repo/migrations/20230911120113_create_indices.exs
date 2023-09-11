defmodule TdAi.Repo.Migrations.CreateIndices do
  use Ecto.Migration

  def change do
    create table(:indices) do
      add(:collection_name, :string)
      add(:embedding, :string)
      add(:mapping, {:array, :string})
      add(:metric_type, :string)
      add(:index_type, :string)
      add(:index_params, :map)

      timestamps()
    end
  end
end
