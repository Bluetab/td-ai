defmodule TdAi.Repo.Migrations.CreateTranslations do
  use Ecto.Migration

  def change do
    create table(:translations) do
      add :resource_id, :integer
      add :generated_prompt, :text
      add :response, :map
      add :request_time, :integer
      add :requested_by, :integer
      add :prompt_id, references(:prompts, on_delete: :nothing)
      add :status, :string

      timestamps(type: :utc_datetime_usec)
    end

    create index(:translations, [:prompt_id])
  end
end
