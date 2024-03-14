defmodule TdAiWeb.ProviderController do
  use TdAiWeb, :controller

  alias TdAi.Completion
  alias TdAi.Completion.Messages
  alias TdAi.Completion.Provider
  alias TdAi.ProviderClient

  action_fallback TdAiWeb.FallbackController

  def index(conn, _params) do
    providers = Completion.list_providers()
    render(conn, :index, providers: providers)
  end

  def create(conn, %{"provider" => provider_params}) do
    claims = conn.assigns[:current_resource]

    with :ok <- Bodyguard.permit(Completion, :create, claims),
         {:ok, %Provider{} = provider} <- Completion.create_provider(provider_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", ~p"/api/providers/#{provider}")
      |> render(:show, provider: provider)
    end
  end

  def show(conn, %{"id" => id}) do
    claims = conn.assigns[:current_resource]

    with :ok <- Bodyguard.permit(Completion, :show, claims) do
      provider = Completion.get_provider!(id)
      render(conn, :show, provider: provider)
    end
  end

  def update(conn, %{"id" => id, "provider" => provider_params}) do
    claims = conn.assigns[:current_resource]

    provider = Completion.get_provider!(id)

    with :ok <- Bodyguard.permit(Completion, :update, claims),
         {:ok, %Provider{} = provider} <- Completion.update_provider(provider, provider_params) do
      render(conn, :show, provider: provider)
    end
  end

  def delete(conn, %{"id" => id}) do
    claims = conn.assigns[:current_resource]

    provider = Completion.get_provider!(id)

    with :ok <- Bodyguard.permit(Completion, :delete, claims),
         {:ok, %Provider{}} <- Completion.delete_provider(provider) do
      send_resp(conn, :no_content, "")
    end
  end

  def chat_completion(conn, %{"provider_id" => id, "messages" => messages}) do
    claims = conn.assigns[:current_resource]

    provider =
      id
      |> Completion.get_provider!()
      |> Completion.enrich_provider_secrets()

    with :ok <- Bodyguard.permit(Completion, :delete, claims),
         {:ok, messages} <- Messages.new(messages),
         {:completion, {:ok, data}} <-
           {:completion, ProviderClient.chat_completion(provider, messages)} do
      render(conn, :chat_completion, data: data)
    else
      {:completion, {:error, message}} -> {:error, :bad_request, message}
      error -> error
    end
  end
end
