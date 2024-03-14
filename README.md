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