defmodule TdAiWeb.ActionController do
  use TdAiWeb, :controller

  alias TdAi.Actions.Action
  alias TdAi.Actions.Actions

  action_fallback TdAiWeb.FallbackController

  def index(conn, _) do
    claims = conn.assigns[:current_resource]

    with :ok <- Bodyguard.permit(Actions, :index, claims) do
      render(conn, :index, actions: Actions.list())
    end
  end

  def search(conn, params \\ %{}) do
    claims = conn.assigns[:current_resource]

    with :ok <- Bodyguard.permit(Actions, :search, claims) do
      render(conn, :index, actions: Actions.list(params))
    end
  end

  def actions_by_user(conn, params \\ %{}) do
    %{user_id: user_id} =
      claims = conn.assigns[:current_resource]

    params =
      params
      |> Map.put("user_id", user_id)
      |> Map.put("is_enabled", true)
      |> Map.put("deleted", false)

    with :ok <- Bodyguard.permit(Actions, :search, claims) do
      render(conn, :index, actions: Actions.list(params))
    end
  end

  def show(conn, %{"id" => id}) do
    claims = conn.assigns[:current_resource]

    with :ok <- Bodyguard.permit(Actions, :show, claims),
         %Action{} = action <- Actions.get(id) do
      render(conn, :show, action: action)
    end
  end

  def create(conn, params) do
    claims = conn.assigns[:current_resource]

    with :ok <- Bodyguard.permit(Actions, :create, claims),
         {:ok, action} <- Actions.create(params) do
      conn
      |> put_status(:created)
      |> render(:show, action: action)
    end
  end

  def update(conn, %{"id" => id} = params) do
    claims = conn.assigns[:current_resource]

    with :ok <- Bodyguard.permit(Actions, :update, claims),
         %Action{} = action <- Actions.get(id),
         {:ok, updated_action} <- Actions.update(action, params) do
      render(conn, :show, action: updated_action)
    end
  end

  def delete(conn, %{"id" => id} = params) do
    claims = conn.assigns[:current_resource]

    logical =
      params
      |> Map.get("logical", false)
      |> maybe_parse_boolean()

    with :ok <- Bodyguard.permit(Actions, :delete, claims),
         %Action{} = action <- Actions.get(id),
         {:ok, deleted_action} <-
           Actions.delete(action, logical: logical) do
      render(conn, :show, action: deleted_action)
    end
  end

  def set_active(conn, %{"action_id" => id, "active" => active}) do
    claims = conn.assigns[:current_resource]

    update_params = %{
      "is_enabled" => maybe_parse_boolean(active),
      "updated_at" => DateTime.utc_now()
    }

    with :ok <- Bodyguard.permit(Actions, :update, claims),
         %Action{} = action <- Actions.get(id),
         {:ok, updated_action} <- Actions.update(action, update_params) do
      render(conn, :show, action: updated_action)
    end
  end

  defp maybe_parse_boolean("true"), do: true
  defp maybe_parse_boolean("false"), do: false
  defp maybe_parse_boolean(bool), do: bool
end
