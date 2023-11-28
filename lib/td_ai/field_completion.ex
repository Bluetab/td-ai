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

  def available_resource_mapping(resource_type, selector) do
    case Application.get_env(:td_ai, :env) do
      :test ->
        %{}

      _ ->
        GenServer.call(__MODULE__, {:available_resource_mapping, resource_type, selector}, 30_000)
    end
  end

  @impl GenServer
  def init(_) do
    {:ok, nil}
  end

  defp parse_completion({:ok, response}) do
    case Jason.decode(response) do
      {:ok, response} ->
        response

      {:error, %Jason.DecodeError{data: data}} ->
        {:error, "Invalid JSON response from AI Provider: " <> data}

      {:error, error} ->
        {:error, inspect(error)}
    end
  end

  defp parse_completion({:error, error}), do: {:error, inspect(error)}

  def run_completion(resource_type, resource_id, fields, opts) do
    language = Keyword.get(opts, :language, "en")
    requested_by = Keyword.get(opts, :requested_by)
    selector = Keyword.get(opts, :selector, %{})

    with {:resource_mapping, %{} = resource_mapping} <-
           {:resource_mapping,
            Completion.get_resource_mapping_by_selector(resource_type, selector)},
         {:prompt,
          %{system_prompt: system_prompt, model: model, provider: provider} =
            prompt} <-
           {:prompt, Completion.get_prompt_by_resource_and_language(resource_type, language)},
         {:resource, %{} = resource} <-
           {:resource, PromptParser.parse(resource_mapping, resource_type, resource_id)},
         {:user_prompt, user_prompt} when is_binary(user_prompt) <-
           {:user_prompt, PromptParser.generate_user_prompt(prompt, fields, resource)} do
      Timer.time(
        fn ->
          provider
          |> Provider.chat_completion(model, system_prompt, user_prompt)
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

  def run_available_resource_mapping(resource_type, selector) do
    resource_type
    |> Completion.get_resource_mapping_by_selector(selector)
    |> is_struct()
  end

  @impl GenServer
  def handle_call({:available_resource_mapping, resource_type, selector}, _from, state) do
    result = run_available_resource_mapping(resource_type, selector)

    {:reply, result, state}
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
