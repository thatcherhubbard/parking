use Mix.Config

# For production, don't forget to configure the url host
# to something meaningful, Phoenix uses this information
# when generating URLs.
#
# Note we also include the path to a cache manifest
# containing the digested version of static files. This
# manifest is generated by the `mix phx.digest` task,
# which you should run after static files are built and
# before starting your production server.
config :parking, ParkingWeb.Endpoint,
  url: [host: "example.com", port: 80],
  cache_static_manifest: "priv/static/cache_manifest.json"

# Configure libcluster
config :libcluster,
  topologies: [
    k8s: [
      strategy: Elixir.Cluster.Strategy.Kubernetes.DNS,
      config: [
        service: "parking-service-headless",
        application_name: "parking",
        polling_interval: 3_000
      ]
    ]
  ]

# Do not print debug messages in production
config :logger, level: :info

config :phoenix, :serve_endpoints, true
