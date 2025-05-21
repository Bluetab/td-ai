defmodule TdAi.Repo.Migrations.AddEnabledAtToIndices do
  use Ecto.Migration

  def change do
    alter table(:indices) do
      add :enabled_at, :utc_datetime_usec
    end
  end
end
