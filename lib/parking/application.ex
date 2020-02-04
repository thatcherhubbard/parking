defmodule Parking.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  require Logger

  @max_gates 4
  @max_spaces 100

  def start(_type, _args) do
    # Start telemetry instrumenters
    Parking.Telemetry.LotInstrumenter.setup()
    Parking.Telemetry.PrometheusExporter.setup()

    # NOTE: Only for FreeBSD, Linux and OSX (experimental)
    # https://github.com/deadtrickster/prometheus_process_collector
    Prometheus.Registry.register_collector(:prometheus_process_collector)

    # Retrieve the topologies from the config
    topologies = Application.get_env(:libcluster, :topologies)

    # List all child processes to be supervised
    children = [
      # Start the endpoint when the application starts
      ParkingWeb.Endpoint,
      # Start the telemetry endpoint
      Parking.Telemetry.Endpoint,
      # Cluster supervisor
      {Cluster.Supervisor, [topologies, [name: Parking.ClusterSupervisor]]},
      # Horde registry
      {Horde.Registry, keys: :unique, name: Parking.Registry},
      # Parking lot supervisor
      {Parking.LotSupervisor, [[max_spaces: @max_spaces], [name: Parking.LotSupervisor]]},
      # Gate supervisor
      Supervisor.child_spec(
        {Horde.DynamicSupervisor, strategy: :one_for_one, name: Parking.GateSupervisor},
        id: :gate_supervisor
      ),
      # Horde cluster
      %{
        id: Parking.HordeConnector,
        restart: :transient,
        start: {
          Task,
          :start_link,
          [
            fn ->
              # Join nodes to distributed Registry
              Horde.Cluster.set_members(Parking.Registry, membership(Parking.Registry, nodes()))

              Horde.Cluster.set_members(
                Parking.GateSupervisor,
                membership(Parking.GateSupervisor, nodes())
              )

              1..@max_gates |> Enum.map(&init_gate/1)

              # Establish parking lot CRDT network
              Parking.LotSupervisor.join_neighbourhood(nodes())
            end
          ]
        }
      }
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Parking.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    ParkingWeb.Endpoint.config_change(changed, removed)
    Parking.Telemetry.Endpoint.config_change(changed, removed)
    :ok
  end

  defp nodes do
    [Node.self()] ++ Node.list()
  end

  defp membership(horde, nodes) do
    Enum.map(nodes, fn node -> {horde, node} end)
  end

  defp init_gate(number),
    do: Horde.DynamicSupervisor.start_child(Parking.GateSupervisor, {Parking.Gate, number})
end
