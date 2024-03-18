defmodule TdAi.Completion.Provider do
  @moduledoc """
    This modules defines the Provider schema
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias TdAi.Completion.ProviderProperties

  @valid_types ["mock", "openai", "azure_openai", "bedrock_claude"]

  schema "providers" do
    field :name, :string
    field :type, :string

    embeds_one(:properties, ProviderProperties, on_replace: :update)

    timestamps(type: :utc_datetime_usec)
  end

  @doc false
  def changeset(provider, attrs) do
    provider
    |> cast(attrs, [:name, :type])
    |> validate_required([:name, :type])
    |> validate_inclusion(:type, @valid_types)
    |> maybe_cast_properties(&ProviderProperties.changeset/3)
  end

  @doc false
  def secret_properties(provider, attrs) do
    provider
    |> cast(attrs, [:type])
    |> validate_inclusion(:type, @valid_types)
    |> maybe_cast_properties(&ProviderProperties.secrets_changeset/3)
    |> ProviderProperties.extract_secrets()
    |> then(&{:ok, &1})
  end

  def vault_key(%__MODULE__{id: id}), do: "providers/#{id}"

  def apply_secrets(nil, provider), do: provider

  def apply_secrets(secrets, %__MODULE__{} = provider) do
    provider
    |> cast(%{"properties" => secrets}, [])
    |> maybe_cast_properties(&ProviderProperties.all_fields_changeset/3)
    |> apply_changes()
    |> Map.get(:properties)
    |> then(&Map.put(provider, :properties, &1))
  end

  defp maybe_cast_properties(%{valid?: true} = changeset, cast_with) do
    type =
      changeset
      |> get_field(:type)
      |> String.to_existing_atom()

    cast_embed(changeset, :properties, with: &cast_with.(&1, &2, type), required: true)
  end

  defp maybe_cast_properties(changeset, _), do: changeset
end
