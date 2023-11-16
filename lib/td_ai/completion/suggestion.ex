defmodule TdAi.Completion.Suggestion do
  @moduledoc """
    This modules defines the Suggestion schema
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias TdAi.Completion.Prompt
  alias TdAi.Completion.ResourceMapping

  schema "suggestions" do
    field :response, :map
    field :resource_id, :integer
    field :generated_prompt, :string
    field :request_time, :integer
    field :requested_by, :integer
    field :status, :string
    belongs_to :prompt, Prompt
    belongs_to :resource_mapping, ResourceMapping

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
      :prompt_id,
      :resource_mapping_id,
      :status
    ])
    |> validate_required([
      :resource_id,
      :generated_prompt,
      :response,
      :request_time,
      :prompt_id,
      :resource_mapping_id,
      :status
    ])
  end
end
