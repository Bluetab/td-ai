defmodule TdAi.Completion.ProviderProperties.Mock do
  @moduledoc """
  Ecto Schema module for Mock ProviderProperties embed
  """

  use TdAi.Completion.ProviderProperties.Schema,
    required_fields: [{:model, :string}],
    secret_fields: [{:api_key, :string}]
end
