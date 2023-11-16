defmodule TdAi.Provider.OpenAI do
  @moduledoc """
  Provider implementation for OpenAi
  """

  @behaviour TdAi.Provider

  @impl true
  def chat_completion(model, system_prompt, user_prompt) do
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
end
