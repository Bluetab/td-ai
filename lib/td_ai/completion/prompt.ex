defmodule TdAi.Completion.Prompt do
  @moduledoc """
    This modules defines the Prompt schema
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "prompts" do
    field :active, :boolean, default: false
    field :name, :string
    field :language, :string
    field :resource_type, :string
    field :system_prompt, :string
    field :user_prompt_template, :string

    field :model, :string
    field :provider, :string
    timestamps()
  end

  @doc false
  def changeset(prompt, attrs) do
    prompt
    |> cast(attrs, [
      :name,
      :resource_type,
      :language,
      :system_prompt,
      :user_prompt_template,
      :model,
      :provider
    ])
    |> validate_required([
      :name,
      :resource_type,
      :language,
      :system_prompt,
      :user_prompt_template,
      :model,
      :provider
    ])
  end

  @doc false
  def active_changeset(prompt, active) do
    cast(prompt, %{active: active}, [:active])
  end
end
