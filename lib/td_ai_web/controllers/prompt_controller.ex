defmodule TdAiWeb.PromptController do
  use TdAiWeb, :controller

  alias TdAi.Completion
  alias TdAi.Completion.Prompt

  action_fallback TdAiWeb.FallbackController

  def index(conn, _params) do
    claims = conn.assigns[:current_resource]

    with :ok <- Bodyguard.permit(Completion, :index, claims) do
      prompts = Completion.list_prompts()
      render(conn, :index, prompts: prompts)
    end
  end

  def create(conn, %{"prompt" => prompt_params}) do
    claims = conn.assigns[:current_resource]

    with :ok <- Bodyguard.permit(Completion, :create, claims),
         {:ok, %Prompt{} = prompt} <- Completion.create_prompt(prompt_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", ~p"/api/prompts/#{prompt}")
      |> render(:show, prompt: prompt)
    end
  end

  def show(conn, %{"id" => id}) do
    claims = conn.assigns[:current_resource]

    with :ok <- Bodyguard.permit(Completion, :show, claims) do
      prompt = Completion.get_prompt!(id)
      render(conn, :show, prompt: prompt)
    end
  end

  def update(conn, %{"id" => id, "prompt" => prompt_params}) do
    claims = conn.assigns[:current_resource]
    prompt = Completion.get_prompt!(id)

    with :ok <- Bodyguard.permit(Completion, :update, claims),
         {:ok, %Prompt{} = prompt} <- Completion.update_prompt(prompt, prompt_params) do
      render(conn, :show, prompt: prompt)
    end
  end

  def set_active(conn, %{"prompt_id" => id}) do
    claims = conn.assigns[:current_resource]
    prompt = Completion.get_prompt!(id)

    with :ok <- Bodyguard.permit(Completion, :set_active, claims),
         {:ok, %Prompt{} = prompt} <- Completion.set_prompt_active(prompt) do
      render(conn, :show, prompt: prompt)
    end
  end

  def delete(conn, %{"id" => id}) do
    claims = conn.assigns[:current_resource]
    prompt = Completion.get_prompt!(id)

    with :ok <- Bodyguard.permit(Completion, :delete, claims),
         {:ok, %Prompt{}} <- Completion.delete_prompt(prompt) do
      send_resp(conn, :no_content, "")
    end
  end
end
