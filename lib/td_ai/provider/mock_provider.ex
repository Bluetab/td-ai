defmodule TdAi.Nada do
  @moduledoc """
  Provider calls
  """

  def chat_completion(provider, model, system_prompt, user_prompt) do
    case Application.get_env(:td_ai, :env) do
      :test -> mock_chat_completion(provider, model, system_prompt, user_prompt)
      _ -> do_chat_completion(provider, model, system_prompt, user_prompt)
    end
  end

  def do_chat_completion("openai", model, system_prompt, user_prompt) do
    OpenAI.chat_completion(
      model: model,
      messages: [
        %{role: "system", content: system_prompt},
        %{role: "user", content: user_prompt}
      ]
    )
    |> case do
      {:ok, %{choices: [%{"message" => %{"content" => response}}]}} -> {:ok, response}
      error -> error
    end
  end

  def do_chat_completion(_, _, _, _), do: {:error, :invalid_provider}

  def mock_chat_completion(
        provider,
        model,
        system_prompt,
        user_prompt
      ) do
    response =
      Jason.encode!(%{
        provider: provider,
        model: model,
        system_prompt: system_prompt,
        user_prompt: user_prompt
      })

    {:ok, response}
  end
end
