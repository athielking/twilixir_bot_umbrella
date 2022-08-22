import Config

# Only in tests, remove the complexity from the password hashing algorithm
config :bcrypt_elixir, :log_rounds, 1

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :twilixir_bot, TwilixirBot.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "twilixir_bot_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :twilixir_bot_web, TwilixirBotWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "6yuLpY4eHhCZBaMshPbJ3uNaRPr8eJtfoHcEBG2iPgnPaDjOebnruowp45IIKemR",
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

# In test we don't send emails.
config :twilixir_bot, TwilixirBot.Mailer, adapter: Swoosh.Adapters.Test

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
