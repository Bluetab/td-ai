defmodule TdAi.Completion.ProviderProperties.AzureOpenai do
  @moduledoc """
  Ecto Schema module for Azure Openai ProviderProperties embed
  """

  use TdAi.Completion.ProviderProperties.Schema,
    required_fields: [{:resource_name, :string}, {:deployment, :string}],
    optional_fields: [{:api_version, :string}],
    secret_fields: [{:api_key, :string}]
end
