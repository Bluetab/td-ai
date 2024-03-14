defmodule TdAi.ProviderClients.BedrockClaude do
  @moduledoc """
  Provider implementation for OpenAi
  """

  @behaviour TdAi.ProviderClient

  alias TdAi.Completion.Messages

  @impl true
  def chat_completion(
        %{
          model: model,
          access_key_id: access_key_id,
          secret_access_key: secret_access_key,
          aws_region: aws_region
        } = props,
        %Messages{} = messages
      ) do
    temperature = Map.get(props, :temperature) || 0.5
    top_p = Map.get(props, :top_p) || 0.9

    prompt = messages_to_prompt(messages)

    input =
      %{
        "prompt" => prompt,
        "temperature" => temperature,
        "top_p" => top_p,
        "stop_sequences" => ["\n\nHuman:"],
        "max_tokens_to_sample" => 2048
      }

    config =
      [
        {:access_key_id, access_key_id},
        {:secret_access_key, secret_access_key},
        {:region, aws_region}
      ]

    try do
      model
      |> ExAws.Bedrock.invoke_model(input)
      |> ExAws.request(config ++ [service_override: :bedrock])
      |> handle_request()
    rescue
      e in RuntimeError ->
        {:error, e.message}

      e ->
        {:error, inspect(e)}
    end
  end

  defp handle_request({:ok, %{"completion" => response}}), do: {:ok, response}

  defp handle_request(
         {:error,
          {:http_error, _,
           %{
             body: message
           }}}
       ) do
    content =
      message
      |> Jason.decode()
      |> case do
        {:ok, %{"message" => message}} -> message
        _ -> message
      end

    {:error, content}
  end

  defp handle_request({:error, message}) when is_binary(message),
    do: {:error, message}

  defp handle_request(error), do: error

  defp messages_to_prompt(%Messages{messages: messages}) do
    messages
    |> Enum.reduce("", fn
      %{role: "system", content: content}, prompt -> prompt <> content
      %{role: "user", content: content}, prompt -> prompt <> "\n\nHuman: " <> content
      %{role: "assistant", content: content}, prompt -> prompt <> "\n\nAssistant: " <> content
      _, prompt -> prompt
    end)
    |> Kernel.<>("\n\nAssistant: ")
  end
end
