defmodule TdAi.Repo.Migrations.CreateSuggestions do
  use Ecto.Migration

  def change do
    create table(:suggestions) do
      add :resource_id, :integer
      add :generated_prompt, :text
      add :response, :map
      add :request_time, :integer
      add :requested_by, :integer
      add :prompt_id, references(:prompts, on_delete: :nothing)
      add :resource_mapping_id, references(:resource_mappings, on_delete: :nothing)
      add :status, :string

      timestamps()
    end

    create index(:suggestions, [:prompt_id])
    create index(:suggestions, [:resource_mapping_id])
  end
end
