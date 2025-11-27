defmodule TdAiWeb.KnowledgeController do
  use TdAiWeb, :controller

  alias TdAi.Indices
  alias TdAi.Knowledges

  action_fallback TdAiWeb.FallbackController

  def index(conn, _params) do
    claims = conn.assigns[:current_resource]

    with :ok <- Bodyguard.permit(Knowledges, :list, claims),
         knowledges <- Knowledges.list_knowledges() do
      render(conn, :index, knowledges: knowledges)
    end
  end

  def create(conn, params) do
    claims = conn.assigns[:current_resource]

    %{"files" => files, "names" => names, "descriptions" => descriptions} =
      ensure_list_params(params)

    with :ok <- Bodyguard.permit(Knowledges, :upload, claims),
         {:exists_enabled, true} <-
           {:exists_enabled, Indices.exists_enabled?(%{index_type: "rag"})},
         {:ok, knowledges_jobs} <-
           Knowledges.create_knowledges(Enum.zip([files, names, descriptions])) do
      conn
      |> put_status(:accepted)
      |> render(:index_jobs, knowledges_jobs: knowledges_jobs)
    else
      {:exists_enabled, false} -> {:error, :unprocessable_entity, "No indices enabled"}
      error -> error
    end
  end

  def show(conn, %{"id" => id}) do
    claims = conn.assigns[:current_resource]

    with :ok <- Bodyguard.permit(Knowledges, :show, claims),
         knowledge <- Knowledges.get_knowledge!(id) do
      render(conn, :show, knowledge: knowledge)
    end
  end

  def update(conn, %{"id" => id} = params) do
    claims = conn.assigns[:current_resource]

    with :ok <- Bodyguard.permit(Knowledges, :update, claims),
         knowledge <- Knowledges.get_knowledge!(id),
         {:ok, updated_knowledge} <- Knowledges.update_knowledge(knowledge, params) do
      render(conn, :show, knowledge: updated_knowledge)
    end
  end

  def update_file(conn, %{"knowledge_id" => id, "file" => file}) do
    claims = conn.assigns[:current_resource]

    with :ok <- Bodyguard.permit(Knowledges, :update, claims),
         {:exists_enabled, true} <-
           {:exists_enabled, Indices.exists_enabled?(%{index_type: "rag"})},
         knowledge <- Knowledges.get_knowledge!(id),
         {:ok, knowledges_job} <- Knowledges.update_knowledge_file(knowledge, file) do
      conn
      |> put_status(:accepted)
      |> render(:show, knowledges_job: knowledges_job)
    else
      {:exists_enabled, false} -> {:error, :unprocessable_entity, "No indices enabled"}
      error -> error
    end
  end

  def delete(conn, %{"id" => id}) do
    claims = conn.assigns[:current_resource]

    with :ok <- Bodyguard.permit(Knowledges, :delete, claims),
         knowledge <- Knowledges.get_knowledge!(id),
         :ok <- Knowledges.delete_knowledge(knowledge) do
      send_resp(conn, :no_content, "")
    end
  end

  defp ensure_list_params(%{"files" => files, "names" => names, "descriptions" => descriptions}) do
    %{
      "files" => ensure_list(files),
      "names" => ensure_list(names),
      "descriptions" => ensure_list(descriptions)
    }
  end

  defp ensure_list(value) when is_list(value), do: value
  defp ensure_list(value), do: [value]
end
