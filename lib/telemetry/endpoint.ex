defmodule Parking.Telemetry.Endpoint do
  use Phoenix.Endpoint, otp_app: :parking

  # Serve at "/" the static files from "priv/static" directory.
  #
  # You should set gzip to true if you are running phx.digest
  # when deploying your static files in production.
  plug Plug.Static,
    at: "/",
    from: :parking,
    gzip: false,
    only: ~w(css fonts images js favicon.ico robots.txt)

  plug Plug.RequestId

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Plug.MethodOverride
  plug Plug.Head

  # The session will be stored in the cookie and signed,
  # this means its contents can be read but not tampered with.
  # Set :encryption_salt if you would also like to encrypt it.
  plug Plug.Session,
    store: :cookie,
    key: "_parking_key",
    signing_salt: "1gYzzVR0"

  # Creates the /metrics endpoint for prometheus & collect stats
  plug Parking.Telemetry.PrometheusExporter

  plug Parking.Telemetry.Router
end
