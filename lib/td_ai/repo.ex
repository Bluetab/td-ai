defmodule TdAi.Repo do
  use Ecto.Repo,
    otp_app: :td_ai,
    adapter: Ecto.Adapters.Postgres
end
