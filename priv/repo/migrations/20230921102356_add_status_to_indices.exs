defmodule TdAi.Repo.Migrations.AddStatusToIndices do
  use Ecto.Migration

  def change do
    alter table("indices") do
      add :status, :string
    end
  end
end
