defmodule TwilixirBot.Repo do
  use Ecto.Repo,
    otp_app: :twilixir_bot,
    adapter: Ecto.Adapters.Postgres
end
