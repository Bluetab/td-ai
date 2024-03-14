defmodule TdAi.FieldCompletion do
  @moduledoc """
  Field Completion tasks
  """

  alias TdAi.Completion
  alias TdAi.Completion.Messages
  alias TdAi.PromptParser
  alias TdAi.ProviderClient
  alias TdCore.Utils.Timer

  def resource_field_completion(resource_type, resource, fields, opts \\ [])

  def resource_field_completion(resource_type, %{} = resource, fields, opts) do
    language = Keyword.get(opts, :language, "en")
    requested_by = Keyword.get(opts, :requested_by)

    resource_id = Map.get(resource, "id", 0)

    with {:prompt,
          %{
            system_prompt: system_prompt,
            provider: provider
          } = prompt} <-
           {:prompt, Completion.get_prompt_by_resource_and_language(resource_type, language)},
         {:user_prompt, user_prompt} when is_binary(user_prompt) <-
           {:user_prompt, PromptParser.generate_user_prompt(prompt, fields, resource)} do
      Timer.time(
        fn ->
          messages = Messages.simple_prompt(system_prompt, user_prompt)

          provider
          |> ProviderClient.chat_completion(messages)
          |> parse_completion()
        end,
        fn
          ms, {:error, error} ->
            Completion.create_suggestion(%{
              response: %{message: error},
              resource_id: resource_id,
              generated_prompt: user_prompt,
              request_time: ms,
              requested_by: requested_by,
              prompt_id: prompt.id,
              status: "error"
            })

          ms, response ->
            Completion.create_suggestion(%{
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
      {:resource_mapping, _} -> {:error, :invalid_resource_mapping}
      {:prompt, _} -> {:error, :invalid_prompt}
      {:resource, _} -> {:error, :unable_to_parse_resource}
      {:user_prompt, _} -> {:error, :unable_to_generate_user_prompt}
    end
  end

  def resource_field_completion(resource_type, resource_id, fields, opts) do
    language = Keyword.get(opts, :language, "en")
    requested_by = Keyword.get(opts, :requested_by)
    selector = Keyword.get(opts, :selector, %{})

    with {:resource_mapping, %{} = resource_mapping} <-
           {:resource_mapping,
            Completion.get_resource_mapping_by_selector(resource_type, selector)},
         {:prompt,
          %{
            system_prompt: system_prompt,
            provider: provider
          } = prompt} <-
           {:prompt, Completion.get_prompt_by_resource_and_language(resource_type, language)},
         {:resource, %{} = resource} <-
           {:resource, PromptParser.parse(resource_mapping, resource_type, resource_id)},
         {:user_prompt, user_prompt} when is_binary(user_prompt) <-
           {:user_prompt, PromptParser.generate_user_prompt(prompt, fields, resource)} do
      Timer.time(
        fn ->
          messages = Messages.simple_prompt(system_prompt, user_prompt)

          provider
          |> ProviderClient.chat_completion(messages)
          |> parse_completion()
        end,
        fn
          ms, {:error, error} ->
            Completion.create_suggestion(%{
              response: %{message: error},
              resource_id: resource_id,
              generated_prompt: user_prompt,
              request_time: ms,
              requested_by: requested_by,
              prompt_id: prompt.id,
              resource_mapping_id: resource_mapping.id,
              status: "error"
            })

          ms, response ->
            Completion.create_suggestion(%{
              response: response,
              resource_id: resource_id,
              generated_prompt: user_prompt,
              request_time: ms,
              requested_by: requested_by,
              prompt_id: prompt.id,
              resource_mapping_id: resource_mapping.id,
              status: "ok"
            })
        end
      )
    else
      {:resource_mapping, _} -> {:error, :invalid_resource_mapping}
      {:prompt, _} -> {:error, :invalid_prompt}
      {:resource, _} -> {:error, :unable_to_parse_resource}
      {:user_prompt, _} -> {:error, :unable_to_generate_user_prompt}
    end
  end

  def available_resource_mapping(resource_type, selector) do
    resource_type
    |> Completion.get_resource_mapping_by_selector(selector)
    |> is_struct()
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
