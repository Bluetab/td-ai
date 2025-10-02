# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :td_ai,
  ecto_repos: [TdAi.Repo]

config :td_ai, :env, Mix.env()
config :td_cluster, :env, Mix.env()
config :td_cluster, groups: [:ai]

# Configures the endpoint
config :td_ai, TdAiWeb.Endpoint,
  http: [port: 4015],
  url: [host: "localhost"],
  render_errors: [
    formats: [html: TdAiWeb.ErrorHTML, json: TdAiWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: TdAi.PubSub,
  live_view: [signing_salt: "2NyyFJ97"]

config :td_core, TdCore.Auth.Guardian,
  allowed_algos: ["HS512"],
  issuer: "tdauth",
  aud: "truedat",
  ttl: {1, :hours},
  secret_key: "SuperSecretTruedat"

config :td_df_lib, :templates_module, TdCluster.Cluster.TdDf.Templates

config :bodyguard, default_error: :forbidden

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :td_ai, :gen_ai_module, TdAi.GenAi

config :td_ai, :model_path, "priv/models"

config :td_cache, :audit,
  service: "td_ai",
  stream: "audit:events"

config :td_cache, :event_stream,
  consumer_id: "default",
  consumer_group: "ai",
  streams: []

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
