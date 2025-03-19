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

  def get_proxy_opt(nil), do: []

  def get_proxy_opt(proxy_opt) do
    case Keyword.get(proxy_opt, :address) do
      nil ->
        []

      address ->
        options =
          case Keyword.get(proxy_opt, :options) do
            nil -> []
            options -> options
          end

        [
          proxy: {proxy_opt[:schema], address, proxy_opt[:port], options}
        ]
    end
  end

  defp impl("azure_openai"), do: TdAi.ProviderClients.AzureOpenai
  defp impl("bedrock_claude"), do: TdAi.ProviderClients.BedrockClaude
  defp impl("openai"), do: TdAi.ProviderClients.Openai
  defp impl("gemini"), do: TdAi.ProviderClients.Gemini
  defp impl("mock"), do: TdAi.ProviderClients.Mock
  defp impl(_), do: TdAi.ProviderClients.InvalidProvider
end
