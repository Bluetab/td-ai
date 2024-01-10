defmodule TdAiWeb.SuggestionController do
  use TdAiWeb, :controller

  alias TdAi.Completion
  alias TdAi.Completion.Suggestion

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

  def delete(conn, %{"id" => id}) do
    claims = conn.assigns[:current_resource]
    suggestion = Completion.get_suggestion!(id)

    with :ok <- Bodyguard.permit(Completion, :delete, claims),
         {:ok, %Suggestion{}} <- Completion.delete_suggestion(suggestion) do
      send_resp(conn, :no_content, "")
    end
  end
end
