defmodule TdAi.ProviderClient do
  @moduledoc """
  Providers for ai models
  """

  @callback chat_completion(map(), any()) ::
              {:ok, term} | {:error, atom}

  def chat_completion(
        %{
          type: provider,
          properties: provider_properties
        },
        messages
      ),
      do:
        impl(provider).chat_completion(
          Map.get(provider_properties, String.to_existing_atom(provider)),
          messages
        )

  defp impl("azure_openai"), do: TdAi.ProviderClients.AzureOpenai
  defp impl("bedrock_claude"), do: TdAi.ProviderClients.BedrockClaude
  defp impl("openai"), do: TdAi.ProviderClients.Openai
  defp impl("mock"), do: TdAi.ProviderClients.Mock
  defp impl(_), do: :invalid_provider
end
