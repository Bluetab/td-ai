defmodule TdAi.Repo.Migrations.CreatePrompts do
  use Ecto.Migration

  def change do
    create table(:prompts) do
      add :name, :string
      add :resource_type, :string
      add :language, :string
      add :system_prompt, :string
      add :user_prompt_template, :string
      add :active, :boolean, default: false, null: false
      add :resource_mapping_id, references(:resource_mappings, on_delete: :nothing)

      add :model, :string
      add :provider, :string

      timestamps()
    end

    create index(:prompts, [:resource_mapping_id])
  end
end
