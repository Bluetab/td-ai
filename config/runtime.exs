import Config

# config/runtime.exs is executed for all environments, including
# during releases. It is executed after compilation and before the
# system starts, so it is typically used to load production configuration
# and secrets from environment variables or elsewhere. Do not define
# any compile-time configuration in here, as it won't be applied.
# The block below contains prod specific runtime configuration.

# ## Using releases
#
# If you use `mix release`, you need to explicitly enable the server
# by passing the PHX_SERVER=true when you start it:
#
#     PHX_SERVER=true bin/td_ai start
#
# Alternatively, you can use `mix phx.gen.release` to generate a `bin/server`
# script that automatically sets the env var above.
if System.get_env("PHX_SERVER") do
  config :td_ai, TdAiWeb.Endpoint, server: true
end

config :openai,
  api_key: System.get_env("TD_OPENAI_API_KEY"),
  http_options: [recv_timeout: 30_000]

# config :td_ai, TdAi.FieldCompletion,
#   system_prompt:
#     System.get_env(
#       "TD_AI_COMP_SYSTEM_PROMPT",
#       "You are a system that completes the value for various fields. You will receive some information about a Data Structure and the list of fields with their name and description. You need to return a JSON object with the values for each field and only the fields. Be very aware of each field description."
#     ),
#   model: System.get_env("TD_AI_COMP_MODEL", "gpt-3.5-turbo")

if config_env() == :prod do
  maybe_ipv6 = if System.get_env("ECTO_IPV6") in ~w(true 1), do: [:inet6], else: []

  config :td_ai, TdAi.Repo,
    username: System.fetch_env!("DB_USER"),
    password: System.fetch_env!("DB_PASSWORD"),
    database: System.fetch_env!("DB_NAME"),
    hostname: System.fetch_env!("DB_HOST"),
    port: System.get_env("DB_PORT", "5432") |> String.to_integer(),
    pool_size: System.get_env("DB_POOL_SIZE", "4") |> String.to_integer(),
    timeout: System.get_env("DB_TIMEOUT_MILLIS", "15000") |> String.to_integer(),
    ssl: System.get_env("DB_SSL", "") |> String.downcase() == "true",
    socket_options: maybe_ipv6

  config :td_core, TdCore.Auth.Guardian, secret_key: System.fetch_env!("GUARDIAN_SECRET_KEY")

  config :td_ai, :milvus, %{
    host: System.fetch_env!("MILVUS_HOST"),
    port: System.fetch_env!("MILVUS_PORT")
  }

  config :td_cache,
    redis_host: System.fetch_env!("REDIS_HOST"),
    port: System.get_env("REDIS_PORT", "6379") |> String.to_integer(),
    password: System.get_env("REDIS_PASSWORD")
end
