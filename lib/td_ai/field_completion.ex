defmodule TdAi.FieldCompletion do
  @moduledoc """
  GenServer for Field Completion tasks
  """

  use GenServer

  alias TdAi.Completion
  alias TdAi.PromptParser
  alias TdAi.Provider
  alias TdCore.Utils.Timer

  def start_link(_) do
    case Application.get_env(:td_ai, :env) do
      :test -> :ok
      _ -> GenServer.start_link(__MODULE__, nil, name: __MODULE__)
    end
  end

  def resource_field_completion(resource_type, resource_id, fields, opts \\ []) do
    case Application.get_env(:td_ai, :env) do
      :test -> %{}
      _ -> GenServer.call(__MODULE__, {resource_type, resource_id, fields, opts}, 30_000)
    end
  end

  @impl GenServer
  def init(_) do
    {:ok, nil}
  end

  def run_completion(resource_type, resource_id, fields, opts) do
    language = Keyword.get(opts, :language, "en")
    requested_by = Keyword.get(opts, :requested_by)

    with {:prompt,
          %{
            resource_mapping: resource_mapping,
            system_prompt: system_prompt,
            model: model,
            provider: provider
          } =
            prompt} <-
           {:prompt, Completion.get_prompt_by_resource_and_language(resource_type, language)},
         {:resource, resource} when is_map(resource) <-
           {:resource, PromptParser.parse(resource_mapping, resource_type, resource_id)},
         {:user_prompt, user_prompt} when is_binary(user_prompt) <-
           {:user_prompt, PromptParser.generate_user_prompt(prompt, fields, resource)} do
      Timer.time(
        fn ->
          provider
          |> Provider.chat_completion(model, system_prompt, user_prompt)
          |> case do
            {:ok, response} -> {:ok, Jason.decode!(response)}
            error -> error
          end
        end,
        fn
          ms, {:ok, response} ->
            Completion.create_suggestion(%{
              response: response,
              resource_id: resource_id,
              generated_prompt: user_prompt,
              request_time: ms,
              requested_by: requested_by,
              prompt_id: prompt.id
            })

          _, _ ->
            nil
        end
      )
    else
      {:prompt, _} -> {:error, :invalid_prompt}
      {:resource, _} -> {:error, :unable_to_parse_resource}
      {:user_prompt, _} -> {:error, :unable_to_generate_user_prompt}
    end
  end

  @impl GenServer
  def handle_call(
        {resource_type, resource_id, fields, opts},
        _from,
        state
      ) do
    result = run_completion(resource_type, resource_id, fields, opts)

    {:reply, result, state}
  end

  @impl GenServer
  def handle_call(_, _from, state) do
    {:reply, nil, state}
  end
end
