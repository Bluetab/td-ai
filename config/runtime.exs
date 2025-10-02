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

config :td_cache, :audit, maxlen: System.get_env("REDIS_AUDIT_STREAM_MAXLEN", "100")

config :td_cache, :event_stream, maxlen: System.get_env("REDIS_STREAM_MAXLEN", "100")

if config_env() == :prod do
  maybe_ipv6 = if System.get_env("ECTO_IPV6") in ~w(true 1), do: [:inet6], else: []

  get_ssl_option = fn env_var, option_key ->
    if System.get_env("DB_SSL", "") |> String.downcase() == "true" do
      case System.get_env(env_var, "") do
        "" -> []
        "nil" -> []
        value -> [{option_key, value}]
      end
    else
      []
    end
  end

  optional_db_ssl_options_cacertfile = get_ssl_option.("DB_SSL_CACERTFILE", :cacertfile)
  optional_db_ssl_options_certfile = get_ssl_option.("DB_SSL_CLIENT_CERT", :certfile)
  optional_db_ssl_options_keyfile = get_ssl_option.("DB_SSL_CLIENT_KEY", :keyfile)

  config :td_ai, TdAi.Repo,
    username: System.fetch_env!("DB_USER"),
    password: System.fetch_env!("DB_PASSWORD"),
    database: System.fetch_env!("DB_NAME"),
    hostname: System.fetch_env!("DB_HOST"),
    port: System.get_env("DB_PORT", "5432") |> String.to_integer(),
    pool_size: System.get_env("DB_POOL_SIZE", "4") |> String.to_integer(),
    timeout: System.get_env("DB_TIMEOUT_MILLIS", "15000") |> String.to_integer(),
    ssl: System.get_env("DB_SSL", "") |> String.downcase() == "true",
    ssl_opts:
      [
        verify:
          System.get_env("DB_SSL_VERIFY", "verify_none") |> String.downcase() |> String.to_atom(),
        server_name_indication: System.get_env("DB_HOST") |> to_charlist(),
        versions: [
          System.get_env("DB_SSL_VERSION", "tlsv1.2") |> String.downcase() |> String.to_atom()
        ]
      ] ++
        optional_db_ssl_options_cacertfile ++
        optional_db_ssl_options_certfile ++
        optional_db_ssl_options_keyfile,
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

  config :td_ai, TdAi.Vault,
    token: System.fetch_env!("VAULT_TOKEN"),
    secrets_path: System.fetch_env!("VAULT_SECRETS_PATH")

  config :td_ai, :proxy_ai_provider,
    address: System.get_env("AI_PROVIDER_PROXY_ADDRESS"),
    schema: System.get_env("AI_PROVIDER_PROXY_SCHEMA", "http") |> String.to_atom(),
    port: System.get_env("AI_PROVIDER_PROXY_PORT", "3128") |> String.to_integer(),
    options: System.get_env("AI_PROVIDER_PROXY_OPTIONS")

  config :td_ai, :model_path, System.get_env("MODEL_PATH", "priv/models")
end
