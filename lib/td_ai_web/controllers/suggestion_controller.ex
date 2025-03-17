defmodule TdAiWeb.SuggestionController do
  use TdAiWeb, :controller

  alias TdAi.Completion
  alias TdAi.Completion.Suggestion
  alias TdAi.FieldCompletion
  alias TdCache.I18nCache
  alias TdDfLib.Templates

  action_fallback TdAiWeb.FallbackController

  def index(conn, _params) do
    claims = conn.assigns[:current_resource]

    with :ok <- Bodyguard.permit(Completion, :index, claims) do
      suggestions = Completion.list_suggestions()
      render(conn, :index, suggestions: suggestions)
    end
  end

  def create(conn, %{"suggestion" => suggestion_params}) do
    claims = conn.assigns[:current_resource]

    with :ok <- Bodyguard.permit(Completion, :create, claims),
         {:ok, %Suggestion{} = suggestion} <- Completion.create_suggestion(suggestion_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", ~p"/api/suggestions/#{suggestion}")
      |> render(:show, suggestion: suggestion)
    end
  end

  def show(conn, %{"id" => id}) do
    claims = conn.assigns[:current_resource]

    with :ok <- Bodyguard.permit(Completion, :show, claims) do
      suggestion = Completion.get_suggestion!(id)
      render(conn, :show, suggestion: suggestion)
    end
  end

  def update(conn, %{"id" => id, "suggestion" => suggestion_params}) do
    claims = conn.assigns[:current_resource]
    suggestion = Completion.get_suggestion!(id)

    with :ok <- Bodyguard.permit(Completion, :update, claims),
         {:ok, %Suggestion{} = suggestion} <-
           Completion.update_suggestion(suggestion, suggestion_params) do
      render(conn, :show, suggestion: suggestion)
    end
  end

  def availability_check(
        conn,
        %{
          "resource_type" => resource_type,
          "domain_ids" => domain_ids,
          "template_id" => template_id
        } = params
      ) do
    {:ok, default_locale} = I18nCache.get_default_locale()
    language = Map.get(params, "language", default_locale)
    claims = conn.assigns[:current_resource]

    {status, reason} =
      with :ok <-
             Bodyguard.permit(
               Completion,
               :request_suggestion,
               claims,
               {resource_type, domain_ids}
             ),
           {:template_suggestions, true} <-
             {:template_suggestions, Templates.has_ai_suggestions(template_id)},
           {:prompt, %{}} <-
             {:prompt, Completion.get_prompt_by_resource_and_language(resource_type, language)} do
        {:ok, nil}
      else
        {:template_suggestions, {:error, :template_not_found}} -> {:error, "template not found"}
        {:template_suggestions, false} -> {:error, "template has no ai_suggestion fields"}
        {:prompt, _} -> {:error, "no active prompt"}
        error -> error
      end

    render(conn, :availability_check, response: {status, reason})
  end

  def request(
        conn,
        %{
          "resource_type" => resource_type,
          "resource_body" => resource_body,
          "domain_ids" => domain_ids,
          "template_id" => template_id
        } = params
      ) do
    {:ok, default_locale} = I18nCache.get_default_locale()
    language = Map.get(params, "language", default_locale)
    %{user_id: user_id} = claims = conn.assigns[:current_resource]

    with :ok <-
           Bodyguard.permit(Completion, :request_suggestion, claims, {resource_type, domain_ids}),
         {:ok, fields} <- Templates.suggestion_fields_for_template(template_id) do
      FieldCompletion.resource_field_completion(
        "business_concept",
        resource_body,
        fields,
        language: language,
        requested_by: user_id
      )
      |> case do
        {:error, error} -> {:error, :unprocessable_entity, error}
        suggestion_content -> render(conn, :show_content, suggestion_content: suggestion_content)
      end
    else
      {:error, :template_not_found} ->
        {:error, :unprocessable_entity, "template not found"}

      {:error, :no_ai_suggestion_fields} ->
        {:error, :unprocessable_entity, "template has no ai_suggestion fields"}

      error ->
        error
    end
  end

  def delete(conn, %{"id" => id}) do
    claims = conn.assigns[:current_resource]
    suggestion = Completion.get_suggestion!(id)

    with :ok <- Bodyguard.permit(Completion, :delete, claims),
         {:ok, %Suggestion{}} <- Completion.delete_suggestion(suggestion) do
      send_resp(conn, :no_content, "")
    end
  end
end
