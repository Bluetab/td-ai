defmodule TdAi.Completion.ProviderProperties do
  @moduledoc """
  Ecto Schema module for Completion Provider Properties embed
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias TdAi.Completion.ProviderProperties.AzureOpenai
  alias TdAi.Completion.ProviderProperties.BedrockClaude
  alias TdAi.Completion.ProviderProperties.Mock
  alias TdAi.Completion.ProviderProperties.Openai

  @embeds %{
    azure_openai: AzureOpenai,
    bedrock_claude: BedrockClaude,
    mock: Mock,
    openai: Openai
  }

  @primary_key false
  embedded_schema do
    for {key, mod} <- @embeds do
      embeds_one(key, mod, on_replace: :update)
    end
  end

  def changeset(%__MODULE__{} = struct, %{} = params, type) do
    prop_params = %{type => params}

    struct
    |> cast(prop_params, [])
    |> cast_embed(type)
  end

  def secrets_changeset(%__MODULE__{} = struct, %{} = params, type) do
    prop_params = %{type => params}

    struct
    |> cast(prop_params, [])
    |> cast_embed(type, with: &@embeds[type].secrets_changeset/2)
  end

  def all_fields_changeset(%__MODULE__{} = struct, %{} = params, type) do
    prop_params = %{type => params}

    struct
    |> cast(prop_params, [])
    |> cast_embed(type, with: &@embeds[type].all_fields_changeset/2)
  end

  def extract_secrets(%{valid?: true} = changeset) do
    type =
      changeset
      |> get_field(:type)
      |> String.to_existing_atom()

    changeset
    |> get_field(:properties)
    |> Map.get(type)
    |> @embeds[type].take_secrets()
  end

  def extract_secrets(_), do: %{}

  def json(%__MODULE__{} = struct, type) do
    type = String.to_existing_atom(type)

    struct
    |> Map.get(type)
    |> @embeds[type].json()
  end
end
