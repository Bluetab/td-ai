defmodule TdAi.Indices.Index do
  @moduledoc """
    This modules defines the Index schema
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "indices" do
    field(:collection_name, :string)
    field(:embedding, :string)
    field(:mapping, {:array, :string})
    field(:metric_type, :string)
    field(:index_type, :string)
    field(:index_params, :map)
    field(:status, :string)

    timestamps()
  end

  @doc false
  def changeset(index, attrs) do
    index
    |> cast(attrs, [
      :collection_name,
      :embedding,
      :mapping,
      :metric_type,
      :index_type,
      :index_params,
      :status
    ])
    |> validate_required([
      :collection_name,
      :embedding,
      :mapping,
      :metric_type,
      :index_type
    ])
  end
end
