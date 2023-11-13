defmodule TdAi.Repo.Migrations.CreateSuggestions do
  use Ecto.Migration

  def change do
    create table(:suggestions) do
      add :resource_id, :integer
      add :generated_prompt, :string
      add :response, :map
      add :request_time, :integer
      add :requested_by, :integer
      add :prompt_id, references(:prompts, on_delete: :nothing)

      timestamps()
    end

    create index(:suggestions, [:prompt_id])
  end
end
