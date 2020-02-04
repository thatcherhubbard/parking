# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

# Configures the endpoint
config :parking, ParkingWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "+/HFldTy36M07tnanhg7LqKv75Pj3KVqwdLoR7BHUrvhcB+ZX4O0nGDQ9cwVvfvr",
  render_errors: [view: ParkingWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Parking.PubSub, adapter: Phoenix.PubSub.PG2]

# Configures the telemetry endpoint
config :parking, Parking.Telemetry.Endpoint,
  http: [port: 9102],
  debug_errors: true,
  code_reloader: true,
  check_origin: false

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
