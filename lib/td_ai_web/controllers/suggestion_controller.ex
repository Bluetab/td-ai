defmodule TdAiWeb.SuggestionController do
  use TdAiWeb, :controller

  alias TdAi.Completion
  alias TdAi.Completion.Suggestion

  action_fallback TdAiWeb.FallbackController

  def index(conn, _params) do
    suggestions = Completion.list_suggestions()
    render(conn, :index, suggestions: suggestions)
  end

  def create(conn, %{"suggestion" => suggestion_params}) do
    with {:ok, %Suggestion{} = suggestion} <- Completion.create_suggestion(suggestion_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", ~p"/api/suggestions/#{suggestion}")
      |> render(:show, suggestion: suggestion)
    end
  end

  def show(conn, %{"id" => id}) do
    suggestion = Completion.get_suggestion!(id)
    render(conn, :show, suggestion: suggestion)
  end

  def update(conn, %{"id" => id, "suggestion" => suggestion_params}) do
    suggestion = Completion.get_suggestion!(id)

    with {:ok, %Suggestion{} = suggestion} <- Completion.update_suggestion(suggestion, suggestion_params) do
      render(conn, :show, suggestion: suggestion)
    end
  end

  def delete(conn, %{"id" => id}) do
    suggestion = Completion.get_suggestion!(id)

    with {:ok, %Suggestion{}} <- Completion.delete_suggestion(suggestion) do
      send_resp(conn, :no_content, "")
    end
  end
end
