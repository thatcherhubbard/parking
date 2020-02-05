import Config

metrics_port = String.to_integer(System.fetch_env!("METRICS_PORT"))
url = System.fetch_env!("APPLICATION_HOST")

config :parking, ParkingWeb.Endpoint,
  http: [:inet6, port: System.fetch_env!("PORT")],
  secret_key_base: System.fetch_env!("SECRET_KEY_BASE")

config :parking, Parking.Telemetry.Endpoint,
  url: [host: url],
  http: [port: metrics_port],
  secret_key_base: secret_key_base,
  debug_errors: false,
  server: true,
  check_origin: false
