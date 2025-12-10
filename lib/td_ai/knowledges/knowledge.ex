defmodule TdAi.Knowledges.Knowledge do
  @moduledoc """
  Schema for knowledge.
  """

  use Ecto.Schema
  import Ecto.Changeset

  schema "knowledges" do
    field :name, :string
    field :description, :string
    field :filename, :string
    field :format, :string
    field :md5, :string
    field :n_chunks, :integer, default: 0
    field :status, :string, default: "awaiting"

    timestamps(type: :utc_datetime_usec)
  end

  @doc false
  def changeset(knowledge, attrs) do
    knowledge
    |> cast(attrs, [:name, :description, :filename, :format, :md5, :n_chunks, :status])
    |> validate_required([:name, :filename, :format, :md5])
    |> validate_format(:format, ~r/^[a-zA-Z0-9]+$/, message: "must be alphanumeric")
    |> validate_length(:md5, is: 32, message: "must be exactly 32 characters")
    |> validate_inclusion(:status, ["awaiting", "processing", "completed", "failed"],
      message: "must be awaiting, processing, completed, or failed"
    )
    |> validate_number(:n_chunks, greater_than_or_equal_to: 0)
    |> unique_constraint(:md5, name: :knowledges_md5_index)
  end
end
