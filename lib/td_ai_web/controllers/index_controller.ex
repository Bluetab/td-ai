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
    %{
      "collection_name" => collection_name,
      "embedding" => embedding,
      "mapping" => mapping
    } = index_params

    with ~c"ok" <- TdAi.Python.load_collection(collection_name, embedding, mapping),
         {:ok, %Index{} = index} <- Indices.create_index(index_params) do
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
