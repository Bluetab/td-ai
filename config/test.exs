import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :td_ai, TdAi.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "postgres",
  database: "td_ai_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :td_ai, TdAiWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "f+UdlJ/JnU73cIL5riKC+FQ6JYN1Qsxei5XBj+J5vgHo1tfnTulOk+TwH3QzrqkP",
  server: false

config :td_cluster, TdCluster.ClusterHandler, MockClusterHandler

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

config :td_cache, redis_host: "redis", port: 6380

config :td_ai, :gen_ai_module, TdAi.GenAiMock
config :td_ai, :embeddings, TdAi.Embeddings.Mock

config :td_ai, TdAi.Vault,
  token: "vault_secret_token1234",
  secrets_path: "secret/data/ai/"

config :vaultex, vault_addr: "http://vault:8200"
