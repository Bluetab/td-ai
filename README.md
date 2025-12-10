# TdAi

To start your Phoenix server:

- Run `mix setup` to install and setup dependencies
- Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Learn more

- Official website: https://www.phoenixframework.org/
- Guides: https://hexdocs.pm/phoenix/overview.html
- Docs: https://hexdocs.pm/phoenix
- Forum: https://elixirforum.com/c/phoenix-forum
- Source: https://github.com/phoenixframework/phoenix

docker build --build-arg APP_NAME=td_ai --build-arg APP_VERSION=0.0.1 --volume /home/bluetab/Escritorio/Truedat/td-ai:/app .

docker build --build-arg APP_VERSION=0.1.0 .

## Environment variable

- `VAULT_TOKEN` Token for Vault connection
- `VAULT_SECRETS_PATH` Prefix path for vault secrets
- `REDIS_AUDIT_STREAM_MAXLEN` (Optional) Maximum length for Redis audit stream. Default: 100
- `REDIS_STREAM_MAXLEN` (Optional) Maximum length for Redis stream. Default: 100

### Oban configuration

- `OBAN_DB_SCHEMA` (Optional) Schema prefix to use for Oban tables. Default: `private`.
- `OBAN_CREATE_SCHEMA` (Optional) Whether to auto-create the Oban schema at boot. Accepts `"true"`/`"false"`. Default: `true`.
- `OBAN_KNOWLEDGE_QUEUE_WORKERS` (Optional) Number of workers for the knowledge_queue. Default: `1`.

### Semantic Search Configuration

The following environment variables control the behavior of semantic search:

- `SEMANTIC_SEARCH_NUM_CANDIDATES` (Optional) Number of candidates to consider in KNN search. Default: 200
- `SEMANTIC_SEARCH_K` (Optional) Number of top results to return from semantic search. Default: 20
- `SEMANTIC_SEARCH_SIMILARITY` (Optional) Minimum similarity threshold for search results. Default: 0.30
- `SEMANTIC_SEARCH_BOOST` (Optional) Boost factor for KNN search results. Default: 1.0

### Python configuration

To use and develop `knowledges` locally, you need a python virtual enviroment.

You need to create a Python virtual environment. This command creates and configures a
virtual environment with all dependencies:

```sh
mix python.setup
```

You can specify the python binary to use by setting the `PYTHON_BINARY` environment variable.

- `PYTHON_BINARY` (Optional) Absolute path to the python binary. Default: `python`.
  - **Note**: This path must be absolute, not relative.
  - The python binary must have the dependencies listed in `priv/python/requirements.txt` installed.

### SSL conection

- DB_SSL: boolean value, to enable TSL config, by default is false.
- DB_SSL_CACERTFILE: path of the certification authority cert file "/path/to/ca.crt".
- DB_SSL_VERSION: available versions are tlsv1.2, tlsv1.3 by default is tlsv1.2.
- DB_SSL_CLIENT_CERT: Path to the client SSL certificate file.
- DB_SSL_CLIENT_KEY: Path to the client SSL private key file.
- DB_SSL_VERIFY: This option specifies whether certificates are to be verified.

## AI Provider Proxy Environment Variables

To configure the proxy settings for the AI providers (Gemini and Azure OpenAI), you can set the following environment variables:

- `AI_PROVIDER_PROXY_ADDRESS`: The address of the proxy server.
- `AI_PROVIDER_PROXY_SCHEMA`: The schema to use for the proxy connection (default is "http"). This value will be converted to an atom.
- `AI_PROVIDER_PROXY_PORT`: The port number for the proxy server.
- `AI_PROVIDER_PROXY_OPTIONS`: Additional options for the proxy configuration.

Example configuration in your environment:

```sh
export AI_PROVIDER_PROXY_ADDRESS="proxy.example.com"
export AI_PROVIDER_PROXY_SCHEMA="https"
export AI_PROVIDER_PROXY_PORT="8080"
export AI_PROVIDER_PROXY_OPTIONS="some_options"
```
