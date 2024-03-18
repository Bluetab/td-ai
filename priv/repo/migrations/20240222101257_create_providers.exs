defmodule TdAi.Repo.Migrations.CreateProviders do
  use Ecto.Migration

  import Ecto.Query

  alias TdAi.Repo

  def up do
    create table(:providers) do
      add :name, :string
      add :type, :string
      add :properties, :map

      timestamps(type: :utc_datetime_usec)
    end

    flush()

    ts = DateTime.utc_now()

    providers =
      "prompts"
      |> select([p], p.model)
      |> Repo.all()
      |> Enum.uniq()
      |> Enum.map(
        &%{
          name: &1,
          type: "openai",
          properties: %{
            openai: %{
              model: &1
            }
          },
          inserted_at: ts,
          updated_at: ts
        }
      )

    Repo.insert_all("providers", providers)

    alter table(:prompts) do
      add :provider_id, references(:providers, on_delete: :nothing)
    end

    execute("""
      UPDATE prompts
      SET provider_id = providers.id
      FROM providers
      WHERE prompts.model = providers.name
    """)

    alter table(:prompts) do
      remove :model
      remove :provider
    end
  end

  def down do
    alter table(:prompts) do
      add :model, :string
      add :provider, :string
    end

    execute("""
      UPDATE prompts
      SET
        model = providers.name,
        provider = 'openai'
      FROM providers
      WHERE providers.id = prompts.provider_id
    """)

    alter table(:prompts) do
      remove :provider_id
    end

    drop table(:providers)
  end
end
