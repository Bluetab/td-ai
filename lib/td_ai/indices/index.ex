defmodule TdAi.Indices.Index do
  use Ecto.Schema
  import Ecto.Changeset

  schema "indices" do
    field :collection_name, :string
    field :embedding, :string
    field :mapping, {:array, :string}

    timestamps()
  end

  @doc false
  def changeset(index, attrs) do
    index
    |> cast(attrs, [:collection_name, :embedding, :mapping])
    |> validate_required([:collection_name, :embedding, :mapping])
  end
end
