defmodule TdAi.Predictions.Prediction do
  use Ecto.Schema
  import Ecto.Changeset

  alias TdAi.Indices.Index

  schema "predictions" do
    field(:result, {:array, :map})
    field(:mapping, {:array, :string})
    field(:data_structure_id, :integer)

    belongs_to(:index, Index)

    timestamps()
  end

  @doc false
  def changeset(prediction, attrs) do
    prediction
    |> cast(attrs, [:index_id, :mapping, :result, :data_structure_id])
    |> validate_required([:mapping, :result, :data_structure_id])
  end
end
