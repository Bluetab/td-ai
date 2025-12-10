defmodule TdAi.TranslationCompletion do
  @moduledoc """
  Field Completion tasks
  """

  alias TdAi.Completion
  alias TdAi.Completion.Messages
  alias TdAi.PromptParser
  alias TdAi.ProviderClient
  alias TdCache.I18nCache
  alias TdCore.Utils.Timer

  def resource_translation_completion(params, opts \\ [])

  def resource_translation_completion(
        %{
          "translation_body" => translation_body
        } = params,
        opts
      ) do
    {:ok, default_locale} = I18nCache.get_default_locale()
    language = Keyword.get(opts, :language, default_locale)

    resource_id = Map.get(params, "resource_id", 0)
    requested_by = Keyword.get(opts, :requested_by)

    with {:prompt,
          %{
            system_prompt: system_prompt,
            provider: provider
          } = prompt} <-
           {:prompt, Completion.get_prompt_by_resource_and_language("translation", language)},
         {:user_prompt, user_prompt} when is_binary(user_prompt) <-
           {:user_prompt,
            PromptParser.generate_user_prompt(prompt, translation_body, %{}, [], opts)} do
      Timer.time(
        fn ->
          messages = Messages.simple_prompt(system_prompt, user_prompt)

          provider
          |> ProviderClient.chat_completion(messages)
          |> parse_completion()
        end,
        fn
          ms, {:error, error} ->
            Completion.create_translation(%{
              response: %{message: error},
              resource_id: resource_id,
              generated_prompt: user_prompt,
              request_time: ms,
              requested_by: requested_by,
              prompt_id: prompt.id,
              status: "error"
            })

          ms, response ->
            Completion.create_translation(%{
              response: response,
              resource_id: resource_id,
              generated_prompt: user_prompt,
              request_time: ms,
              requested_by: requested_by,
              prompt_id: prompt.id,
              status: "ok"
            })
        end
      )
    else
      {:prompt, _} -> {:error, :invalid_prompt}
    end
  end

  defp parse_completion({:ok, response}) do
    ~r/(?:```json)?([^`]*)(?:```)?/
    |> Regex.run(response)
    |> parse_regex_group()
    |> build_parse_response(response)
  end

  defp parse_completion({:error, error}), do: {:error, inspect(error)}

  defp parse_regex_group([_, json]), do: Jason.decode(json)
  defp parse_regex_group(_), do: :invalid

  defp build_parse_response({:ok, response}, _), do: response

  defp build_parse_response(_, data),
    do: {:error, "Invalid JSON response from AI Provider: " <> data}
end
