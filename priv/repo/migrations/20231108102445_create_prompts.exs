defmodule TdAi.Repo.Migrations.CreatePrompts do
  use Ecto.Migration

  def change do
    create table(:prompts) do
      add :name, :string
      add :resource_type, :string
      add :language, :string
      add :system_prompt, :text
      add :user_prompt_template, :text
      add :active, :boolean, default: false, null: false

      add :model, :string
      add :provider, :string

      timestamps()
    end
  end
end
