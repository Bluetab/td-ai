defmodule TdAi.Completion.ProviderProperties.Gemini do
  @moduledoc """
  Ecto Schema module for Gemini ProviderProperties embed
  """

  use TdAi.Completion.ProviderProperties.Schema,
    required_fields: [{:model, :string}],
    optional_fields: [{:temperature, :float}, {:top_p, :float}],
    secret_fields: [{:api_key, :string}]
end
