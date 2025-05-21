defmodule TdAi.Repo.Migrations.AddUniqueIndexToCollectionNameInInices do
  use Ecto.Migration

  def change do
    create unique_index(:indices, [:collection_name])
  end
end
