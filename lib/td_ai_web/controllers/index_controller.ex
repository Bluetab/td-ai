defmodule TdAiWeb.IndexController do
  use TdAiWeb, :controller

  alias TdAi.Indices
  alias TdAi.Indices.Index

  action_fallback(TdAiWeb.FallbackController)

  def index(conn, _params) do
    indices = Indices.list_indices()
    render(conn, :index, indices: indices)
  end

  def create(conn, %{"index" => index_params}) do
    gen_ai = Application.get_env(:td_ai, :gen_ai_module)

    index_params = Map.put(index_params, "status", "Created")

    with {:ok, %Index{} = index} <- Indices.create_index(index_params) do
      gen_ai.load_collection(index)

      conn
      |> put_status(:created)
      |> put_resp_header("location", ~p"/api/indices/#{index}")
      |> render(:show, index: index)
    end
  end

  def show(conn, %{"id" => id}) do
    index = Indices.get_index!(id)
    render(conn, :show, index: index)
  end

  def update(conn, %{"id" => id, "index" => index_params}) do
    index = Indices.get_index!(id)

    with {:ok, %Index{} = index} <- Indices.update_index(index, index_params) do
      render(conn, :show, index: index)
    end
  end

  def delete(conn, %{"id" => id}) do
    index = Indices.get_index!(id)

    with {:ok, %Index{}} <- Indices.delete_index(index) do
      send_resp(conn, :no_content, "")
    end
  end
end
