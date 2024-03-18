defmodule TdAi.Completion.ProviderProperties.BedrockClaude do
  @moduledoc """
  Ecto Schema module for Bedrock Claude ProviderProperties embed
  """

  use TdAi.Completion.ProviderProperties.Schema,
    required_fields: [{:model, :string}, {:aws_region, :string}],
    optional_fields: [{:temperature, :float}, {:top_p, :float}],
    secret_fields: [{:access_key_id, :string}, {:secret_access_key, :string}]
end
