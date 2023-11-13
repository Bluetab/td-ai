defmodule TdAi.Completion.Suggestion do
  @moduledoc """
    This modules defines the Suggestion schema
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias TdAi.Completion.Prompt

  schema "suggestions" do
    field :response, :map
    field :resource_id, :integer
    field :generated_prompt, :string
    field :request_time, :integer
    field :requested_by, :integer
    belongs_to :prompt, Prompt

    timestamps()
  end

  @doc false
  def changeset(suggestion, attrs) do
    suggestion
    |> cast(attrs, [
      :resource_id,
      :generated_prompt,
      :response,
      :request_time,
      :requested_by,
      :prompt_id
    ])
    |> validate_required([
      :resource_id,
      :generated_prompt,
      :response,
      :request_time,
      :prompt_id
    ])
  end
end
