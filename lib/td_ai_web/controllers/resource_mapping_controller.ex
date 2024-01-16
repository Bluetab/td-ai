defmodule TdAiWeb.ResourceMappingController do
  use TdAiWeb, :controller

  alias TdAi.Completion
  alias TdAi.Completion.ResourceMapping

  action_fallback TdAiWeb.FallbackController

  def index(conn, _params) do
    claims = conn.assigns[:current_resource]

    with :ok <- Bodyguard.permit(Completion, :index, claims) do
      resource_mappings = Completion.list_resource_mappings()
      render(conn, :index, resource_mappings: resource_mappings)
    end
  end

  def create(conn, %{"resource_mapping" => resource_mapping_params}) do
    claims = conn.assigns[:current_resource]

    with :ok <- Bodyguard.permit(Completion, :create, claims),
         {:ok, %ResourceMapping{} = resource_mapping} <-
           Completion.create_resource_mapping(resource_mapping_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", ~p"/api/resource_mappings/#{resource_mapping}")
      |> render(:show, resource_mapping: resource_mapping)
    end
  end

  def show(conn, %{"id" => id}) do
    claims = conn.assigns[:current_resource]

    with :ok <- Bodyguard.permit(Completion, :show, claims) do
      resource_mapping = Completion.get_resource_mapping!(id)
      render(conn, :show, resource_mapping: resource_mapping)
    end
  end

  def update(conn, %{"id" => id, "resource_mapping" => resource_mapping_params}) do
    claims = conn.assigns[:current_resource]
    resource_mapping = Completion.get_resource_mapping!(id)

    with :ok <- Bodyguard.permit(Completion, :update, claims),
         {:ok, %ResourceMapping{} = resource_mapping} <-
           Completion.update_resource_mapping(resource_mapping, resource_mapping_params) do
      render(conn, :show, resource_mapping: resource_mapping)
    end
  end

  def delete(conn, %{"id" => id}) do
    claims = conn.assigns[:current_resource]
    resource_mapping = Completion.get_resource_mapping!(id)

    with :ok <- Bodyguard.permit(Completion, :delete, claims),
         {:ok, %ResourceMapping{}} <- Completion.delete_resource_mapping(resource_mapping) do
      send_resp(conn, :no_content, "")
    end
  end
end
