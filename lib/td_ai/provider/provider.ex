defmodule TdAi.Provider do
  @moduledoc """
  Providers for ai models
  """

  @callback chat_completion(String.t(), String.t(), String.t()) ::
              {:ok, term} | {:error, atom}

  def chat_completion(provider, model, system_prompt, user_prompt),
    do: impl(provider).chat_completion(model, system_prompt, user_prompt)

  defp impl("openai"), do: TdAi.Provider.OpenAI
  defp impl("mock"), do: TdAi.Provider.Mock
  defp impl(_), do: :invalid_provider
end
