defmodule TdAi.Completion.Prompt do
  @moduledoc """
    This modules defines the Prompt schema
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias TdAi.Completion.Provider

  schema "prompts" do
    field :active, :boolean, default: false
    field :name, :string
    field :language, :string
    field :resource_type, :string
    field :system_prompt, :string
    field :user_prompt_template, :string

    belongs_to :provider, Provider

    timestamps()
  end

  @doc false
  def changeset(prompt, attrs) do
    all_fields = [
      :name,
      :resource_type,
      :language,
      :system_prompt,
      :user_prompt_template,
      :provider_id
    ]

    prompt
    |> cast(attrs, all_fields)
    |> validate_required(all_fields)
  end

  @doc false
  def active_changeset(prompt, active) do
    cast(prompt, %{active: active}, [:active])
  end
end
