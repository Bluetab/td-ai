defmodule TdAiWeb.IndexController do
  use TdAiWeb, :controller

  alias TdAi.Indices
  alias TdAi.Indices.Index

  action_fallback(TdAiWeb.FallbackController)

  def index(conn, _params) do
    claims = conn.assigns[:current_resource]

    with :ok <- Bodyguard.permit(Indices, :index, claims) do
      indices = Indices.list_indices()
      render(conn, :index, indices: indices)
    end
  end

  def create(conn, %{"index" => index_params}) do
    claims = conn.assigns[:current_resource]
    gen_ai = Application.get_env(:td_ai, :gen_ai_module)

    index_params = Map.put(index_params, "status", "Created")

    with :ok <- Bodyguard.permit(Indices, :create, claims),
         {:ok, %Index{} = index} <- Indices.create_index(index_params) do
      gen_ai.load_collection(index)

      conn
      |> put_status(:created)
      |> put_resp_header("location", ~p"/api/indices/#{index}")
      |> render(:show, index: index)
    end
  end

  def show(conn, %{"id" => id}) do
    claims = conn.assigns[:current_resource]

    with :ok <- Bodyguard.permit(Indices, :show, claims) do
      index = Indices.get_index!(id)
      render(conn, :show, index: index)
    end
  end

  def update(conn, %{"id" => id, "index" => index_params}) do
    claims = conn.assigns[:current_resource]
    index = Indices.get_index!(id)

    with :ok <- Bodyguard.permit(Indices, :update, claims),
         {:ok, %Index{} = index} <- Indices.update_index(index, index_params) do
      render(conn, :show, index: index)
    end
  end

  def delete(conn, %{"id" => id}) do
    claims = conn.assigns[:current_resource]
    index = Indices.get_index!(id)

    with :ok <- Bodyguard.permit(Indices, :delete, claims),
         {:ok, %Index{}} <- Indices.delete_index(index) do
      send_resp(conn, :no_content, "")
    end
  end
end
