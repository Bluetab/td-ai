defmodule TdAi.Completion.ResourceMapping do
  @moduledoc """
    This modules defines the ResourceMapping schema
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias TdAi.Completion.ResourceMapping.Field

  schema "resource_mappings" do
    field :name, :string

    embeds_many(:fields, Field, on_replace: :delete)

    timestamps()
  end

  @doc false
  def changeset(resource_mapping, attrs) do
    resource_mapping
    |> cast(attrs, [:name])
    |> validate_required([:name])
    |> cast_embed(:fields, with: &Field.changeset/2, required: true)
  end
end

defmodule TdAi.Completion.ResourceMapping.Field do
  @moduledoc """
    This modules defines the ResourceMapping Field embedded schema
  """
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field :source, :string
    field :target, :string
  end

  @doc false
  def changeset(field, attrs) do
    field
    |> cast(attrs, [:source, :target])
    |> validate_required([:source])
  end
end
