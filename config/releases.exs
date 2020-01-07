import Config

config :parking, ParkingWeb.Endpoint,
  http: [:inet6, port: System.fetch_env!("PORT")],
  secret_key_base: System.fetch_env!("SECRET_KEY_BASE")
