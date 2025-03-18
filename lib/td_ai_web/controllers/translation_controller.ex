defmodule TdAiWeb.TranslationController do
  use TdAiWeb, :controller

  alias TdAi.Completion
  alias TdAi.Completion.Translation
  alias TdAi.TranslationCompletion
  alias TdCache.I18nCache

  action_fallback TdAiWeb.FallbackController

  def index(conn, _params) do
    claims = conn.assigns[:current_resource]

    with :ok <- Bodyguard.permit(Completion, :index, claims) do
      translations = Completion.list_translations()
      render(conn, :index, translations: translations)
    end
  end

  def create(conn, %{"translation" => translation_params}) do
    claims = conn.assigns[:current_resource]

    with :ok <- Bodyguard.permit(Completion, :create, claims),
         {:ok, %Translation{} = translation} <-
           Completion.create_translation(translation_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", ~p"/api/translations/#{translation}")
      |> render(:show, translation: translation)
    end
  end

  def show(conn, %{"id" => id}) do
    claims = conn.assigns[:current_resource]

    with :ok <- Bodyguard.permit(Completion, :show, claims) do
      translation = Completion.get_translation!(id)
      render(conn, :show, translation: translation)
    end
  end

  def update(conn, %{"id" => id, "translation" => translation_params}) do
    claims = conn.assigns[:current_resource]
    translation = Completion.get_translation!(id)

    with :ok <- Bodyguard.permit(Completion, :update, claims),
         {:ok, %Translation{} = translation} <-
           Completion.update_translation(translation, translation_params) do
      render(conn, :show, translation: translation)
    end
  end

  def availability_check(
        conn,
        %{
          "resource_type" => resource_type,
          "domain_ids" => domain_ids
        }
      ) do
    {:ok, language} = I18nCache.get_default_locale()
    claims = conn.assigns[:current_resource]

    {status, reason} =
      with :ok <-
             Bodyguard.permit(
               Completion,
               :request_suggestion,
               claims,
               {resource_type, domain_ids}
             ),
           {:prompt, %{}} <-
             {:prompt, Completion.get_prompt_by_resource_and_language("translation", language)} do
        {:ok, nil}
      else
        {:prompt, _} -> {:error, "no active prompt"}
        error -> error
      end

    render(conn, :availability_check, response: {status, reason})
  end

  def request(
        conn,
        %{
          "resource_type" => resource_type,
          "translation_body" => translation_body,
          "locales" => locales,
          "domain_ids" => domain_ids
        } = params
      ) do
    {:ok, language} = I18nCache.get_default_locale()
    %{user_id: user_id} = claims = conn.assigns[:current_resource]

    with :ok <-
           Bodyguard.permit(Completion, :request_translation, claims, {resource_type, domain_ids}),
         true <-
           (is_list(locales) and locales != []) or
             {:error, :unprocessable_entity, "locales must be a non-empty list"},
         true <-
           (is_map(translation_body) and translation_body != %{}) or
             {:error, :unprocessable_entity, "translation_body must be a non-empty map"} do
      TranslationCompletion.resource_translation_completion(params,
        locales: locales,
        language: language,
        requested_by: user_id
      )
      |> case do
        {:error, error} ->
          {:error, :unprocessable_entity, error}

        translation_content ->
          render(conn, :show_content, translation_content: translation_content)
      end
    else
      {:error, :template_not_found} ->
        {:error, :unprocessable_entity, "template not found"}

      {:error, :no_ai_translation_fields} ->
        {:error, :unprocessable_entity, "template has no ai_suggestion fields"}

      error ->
        error
    end
  end

  def delete(conn, %{"id" => id}) do
    claims = conn.assigns[:current_resource]
    translation = Completion.get_translation!(id)

    with :ok <- Bodyguard.permit(Completion, :delete, claims),
         {:ok, %Translation{}} <- Completion.delete_translation(translation) do
      send_resp(conn, :no_content, "")
    end
  end
end
