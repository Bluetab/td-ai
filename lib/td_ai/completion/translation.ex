defmodule TdAi.Completion.Translation do
  @moduledoc """
    This modules defines the Translation schema
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias TdAi.Completion.Prompt

  schema "translations" do
    field :response, :map
    field :resource_id, :integer
    field :generated_prompt, :string
    field :request_time, :integer
    field :requested_by, :integer
    field :status, :string
    belongs_to :prompt, Prompt

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(translation, attrs) do
    translation
    |> cast(attrs, [
      :resource_id,
      :generated_prompt,
      :response,
      :request_time,
      :requested_by,
      :prompt_id,
      :status
    ])
    |> validate_required([
      :resource_id,
      :generated_prompt,
      :response,
      :request_time,
      :prompt_id,
      :status
    ])
  end
end
