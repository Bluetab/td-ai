defmodule TdAi.ProviderClients.Gemini do
  @moduledoc """
  Provider implementation for Gemini
  """

  @behaviour TdAi.ProviderClient

  alias TdAi.Completion.Messages

  @impl true
  def chat_completion(
        %{
          model: model,
          api_key: api_key
        } = props,
        %Messages{} = messages
      ) do
    temperature = Map.get(props, :temperature) || 0.5
    top_p = Map.get(props, :top_p) || 0.9

    headers = [{"Content-Type", "application/json"}]

    text = messages_to_prompt(messages)

    body =
      %{
        "contents" => [
          %{
            "parts" => [%{"text" => text}]
          }
        ],
        "safetySettings" => [
          %{
            "category" => "HARM_CATEGORY_DANGEROUS_CONTENT",
            "threshold" => "BLOCK_ONLY_HIGH"
          }
        ],
        "generationConfig" => %{
          "temperature" => temperature,
          "topP" => top_p
        }
      }
      |> Jason.encode!()

    url =
      "https://generativelanguage.googleapis.com/v1beta/models/#{model}:generateContent?key=#{api_key}"

    url
    |> Req.post!(headers: headers, body: body)
    |> case do
      %{status: 200, body: %{"candidates" => [%{"content" => %{"parts" => [%{"text" => text}]}}]}} ->
        {:ok, text}

      %{body: error} ->
        {:error, error}
    end
  end

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
