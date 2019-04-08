use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :logic_sim_liveview, LogicSimLiveviewWeb.Endpoint,
  http: [port: 4002],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

# Configure your database
config :logic_sim_liveview, LogicSimLiveview.Repo,
  username: "postgres",
  password: "postgres",
  database: "logic_sim_liveview_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox
