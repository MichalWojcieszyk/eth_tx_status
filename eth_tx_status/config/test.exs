import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :eth_tx_status_web, EthTxStatusWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "jI/0xzTg6jP/JB8OYenGQV2ei3fBJoXHKquzLZc92W+ORr4iv/R0qoYB05fvoZu/",
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
