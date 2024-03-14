defmodule TdAi.ProviderClients.AzureOpenai do
  @moduledoc """
  Provider implementation for OpenAi
  """

  @behaviour TdAi.ProviderClient

  alias TdAi.Completion.Messages

  @default_version "2023-05-15"

  @impl true
  def chat_completion(
        %{resource_name: resource_name, deployment: deployment, api_key: api_key} = props,
        %Messages{} = messages
      ) do
    headers = [{"Content-Type", "application/json"}, {"api-key", api_key}]

    body = Jason.encode!(%{messages: Messages.json(messages)})
    api_version = Map.get(props, :api_version) || @default_version

    "https://#{resource_name}.openai.azure.com/openai/deployments/#{deployment}/chat/completions?api-version=#{api_version}"
    |> Req.post!(headers: headers, body: body)
    |> case do
      %{status: 200, body: %{"choices" => [%{"message" => %{"content" => response}}]}} ->
        {:ok, response}

      %{body: error} ->
        {:error, error}
    end
  end
end
