defmodule TdAi.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    env = Application.get_env(:td_ai, :env)

    children =
      [
        # Start the Telemetry supervisor
        TdAiWeb.Telemetry,
        # Start the Ecto repository
        TdAi.Repo,
        # Start the PubSub system
        {Phoenix.PubSub, name: TdAi.PubSub},
        # Start Finch
        {Finch, name: TdAi.Finch},
        # Start the Endpoint (http/https)
        TdAiWeb.Endpoint
        # Start a worker by calling: TdAi.Worker.start_link(arg)
        # {TdAi.Worker, arg}
      ] ++ workers(env)

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: TdAi.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp workers(:test), do: []

  defp workers(_env) do
    [
      TdAi.Milvus,
      TdAi.NxServings,
      TdAi.GenAi,
      TdAi.FieldCompletion
    ]
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    TdAiWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
