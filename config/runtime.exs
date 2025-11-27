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

config :td_ai,
       :python,
       System.get_env("PYTHON_BINARY", Path.absname("priv/python/.venv/td_ai/bin/python"))

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

  config :td_ai, :python, System.get_env("PYTHON_BINARY", "python")

  config :td_core, TdCore.Search.Cluster, url: System.fetch_env!("ES_URL")

  with username when not is_nil(username) <- System.get_env("ES_USERNAME"),
       password when not is_nil(password) <- System.get_env("ES_PASSWORD") do
    config :td_core, TdCore.Search.Cluster,
      username: username,
      password: password
  end

  with api_key when not is_nil(api_key) <- System.get_env("ES_API_KEY") do
    config :td_core, TdCore.Search.Cluster,
      default_headers: [{"Authorization", "ApiKey #{api_key}"}]
  end
end

# Semantic search configuration from environment variables
config :td_ai, :semantic_search,
  num_candidates: System.get_env("SEMANTIC_SEARCH_NUM_CANDIDATES", "200") |> String.to_integer(),
  k: System.get_env("SEMANTIC_SEARCH_K", "20") |> String.to_integer(),
  similarity: System.get_env("SEMANTIC_SEARCH_SIMILARITY", "0.30") |> String.to_float(),
  boost: System.get_env("SEMANTIC_SEARCH_BOOST", "1.0") |> String.to_float()

# Oban configuration
config :td_ai, Oban,
  prefix: System.get_env("OBAN_DB_SCHEMA", "private"),
  plugins: [{Oban.Plugins.Pruner, max_age: 2 * 24 * 60 * 60}],
  engine: Oban.Engines.Basic,
  notifier: Oban.Notifiers.Postgres,
  queues: [
    knowledge_queue: System.get_env("OBAN_KNOWLEDGE_QUEUE_WORKERS", "5") |> String.to_integer(),
    delete_units: 1
  ],
  repo: TdAi.Repo

config :td_ai, oban_create_schema: System.get_env("OBAN_CREATE_SCHEMA", "true") == "true"

optional_ssl_options =
  case System.get_env("ES_SSL") do
    "true" ->
      cacertfile =
        case System.get_env("ES_SSL_CACERTFILE", "generated") do
          "generated" -> :certifi.cacertfile()
          file -> file
        end

      [
        ssl: [
          cacertfile: cacertfile,
          verify:
            System.get_env("ES_SSL_VERIFY", "verify_none")
            |> String.downcase()
            |> String.to_atom()
        ]
      ]

    _ ->
      []
  end

elastic_default_options =
  [
    timeout: System.get_env("ES_TIMEOUT", "5000") |> String.to_integer(),
    recv_timeout: System.get_env("ES_RECV_TIMEOUT", "40000") |> String.to_integer()
  ] ++ optional_ssl_options

config :td_core, TdCore.Search.Cluster,
  delete_existing_index: System.get_env("DELETE_EXISTING_INDEX", "true") |> String.to_atom(),
  forcemerge_options: [
    wait_for_completion: System.get_env("ES_WAIT_FOR_COMPLETION", "nil") |> String.to_atom(),
    max_num_segments: System.get_env("ES_MAX_NUM_SEGMENTS", "5") |> String.to_integer()
  ],
  default_options: elastic_default_options,
  default_settings: %{
    "number_of_shards" => System.get_env("ES_SHARDS", "1") |> String.to_integer(),
    "number_of_replicas" => System.get_env("ES_REPLICAS", "1") |> String.to_integer(),
    "refresh_interval" => System.get_env("ES_REFRESH_INTERVAL", "5s"),
    "max_result_window" => System.get_env("ES_MAX_RESULT_WINDOW", "10000") |> String.to_integer(),
    "index.indexing.slowlog.threshold.index.warn" =>
      System.get_env("ES_INDEXING_SLOWLOG_THRESHOLD_WARN", "10s"),
    "index.indexing.slowlog.threshold.index.info" =>
      System.get_env("ES_INDEXING_SLOWLOG_THRESHOLD_INFO", "5s"),
    "index.indexing.slowlog.threshold.index.debug" =>
      System.get_env("ES_INDEXING_SLOWLOG_THRESHOLD_DEBUG", "2s"),
    "index.indexing.slowlog.threshold.index.trace" =>
      System.get_env("ES_INDEXING_SLOWLOG_THRESHOLD_TRACE", "500ms"),
    # "index.indexing.slowlog.level" => System.get_env("ES_INDEXING_SLOWLOG_LEVEL", "info"),
    "index.indexing.slowlog.source" => System.get_env("ES_INDEXING_SLOWLOG_SOURCE", "1000"),
    "index.mapping.total_fields.limit" => System.get_env("ES_MAPPING_TOTAL_FIELDS_LIMIT", "3000")
  }

config :td_core, TdCore.Search.Cluster,
  indexes: [
    knowledge: [
      # Controls the data ingestion rate by raising or lowering the number
      # of items to send in each bulk request.
      bulk_page_size: System.get_env("BULK_PAGE_SIZE_KNOWLEDGE", "1000") |> String.to_integer()
    ]
  ]
