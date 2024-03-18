defmodule TdAi.Completion.ProviderProperties.Openai do
  @moduledoc """
  Ecto Schema module for Openai ProviderProperties embed
  """

  use TdAi.Completion.ProviderProperties.Schema,
    required_fields: [{:model, :string}, {:organization_key, :string}],
    secret_fields: [{:api_key, :string}]
end
