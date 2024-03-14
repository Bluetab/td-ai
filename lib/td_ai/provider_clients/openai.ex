defmodule TdAi.ProviderClients.Openai do
  @moduledoc """
  Provider implementation for OpenAi
  """

  @behaviour TdAi.ProviderClient

  alias TdAi.Completion.Messages

  @impl true
  def chat_completion(
        %{model: model, api_key: api_key, organization_key: organization_key},
        %Messages{} = messages
      ) do
    OpenAI.chat_completion(
      [
        model: model,
        messages: Messages.json(messages)
      ],
      %{
        api_key: api_key,
        organization_key: organization_key,
        http_options: [recv_timeout: 30_000],
        beta: "v1"
      }
    )
    |> case do
      {:ok, %{choices: [%{"message" => %{"content" => response}}]}} -> {:ok, response}
      error -> error
    end
  end
end
