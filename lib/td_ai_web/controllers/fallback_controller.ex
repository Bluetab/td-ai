defmodule TdAiWeb.FallbackController do
  @moduledoc """
  Translates controller action results into valid `Plug.Conn` responses.

  See `Phoenix.Controller.action_fallback/1` for more details.
  """
  require Logger
  use TdAiWeb, :controller

  # This clause handles errors returned by Ecto's insert/update/delete.
  def call(conn, {:error, %Ecto.Changeset{} = changeset}) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(json: TdAiWeb.ChangesetJSON)
    |> render(:error, changeset: changeset)
  end

  def call(conn, nil) do
    conn
    |> put_status(:not_found)
    |> put_view(json: TdAiWeb.ErrorJSON)
    |> render(:"404")
  end

  def call(conn, {:error, :unprocessable_entity, message}) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(json: TdAiWeb.ErrorJSON)
    |> render(:error, message: message)
  end

  def call(conn, {:error, :forbidden}) do
    conn
    |> put_status(:forbidden)
    |> put_view(json: TdAiWeb.ErrorJSON)
    |> render(:"403")
  end

  # This clause is an example of how to handle resources that cannot be found.
  def call(conn, {:error, :not_found}) do
    conn
    |> put_status(:not_found)
    |> put_view(html: TdAiWeb.ErrorHTML, json: TdAiWeb.ErrorJSON)
    |> render(:"404")
  end

  def call(conn, {:error, :bad_request, %{"error" => %{"message" => message}}}) do
    conn
    |> put_status(:bad_request)
    |> put_view(json: TdAiWeb.ErrorJSON)
    |> render(:error, message: message)
  end

  def call(conn, {:error, :bad_request, message}) do
    conn
    |> put_status(:bad_request)
    |> put_view(json: TdAiWeb.ErrorJSON)
    |> render(:error, message: message)
  end

  def call(conn, {:error, :conflict, message}) do
    conn
    |> put_status(:conflict)
    |> put_view(json: TdAiWeb.ErrorJSON)
    |> render(:error, message: message)
  end

  # This clause is an example of how to handle resources that cannot be found.
  def call(conn, error) do
    Logger.warning("Unhandled controller fallback: " <> inspect(error))

    conn
    |> put_status(:bad_request)
    |> put_view(html: TdAiWeb.ErrorHTML, json: TdAiWeb.ErrorJSON)
    |> render(:"400")
  end
end
