# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :logic_sim_liveview,
  ecto_repos: [LogicSimLiveview.Repo]

# Configures the endpoint
config :logic_sim_liveview, LogicSimLiveviewWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "AxGntLOTrSCydS4EZp8NiDF8USNaLMpAoprW892j2yVWoDUZIB0eXoLbLb0sB/PU",
  render_errors: [view: LogicSimLiveviewWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: LogicSimLiveview.PubSub, adapter: Phoenix.PubSub.PG2],
  live_view: [
    signing_salt: "NancP11ODVS0pbZhrl/crArW0TwCrdlC"
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix,
  json_library: Jason,
  template_engines: [leex: Phoenix.LiveView.Engine]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
