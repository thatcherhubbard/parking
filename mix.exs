defmodule Parking.MixProject do
  use Mix.Project

  def project do
    [
      app: :parking,
      version: "0.1.0",
      elixir: "~> 1.5",
      releases: [
        parking: [
          applications: [parking: :permanent],
          include_executables_for: [:unix]
        ]
      ],
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix, :gettext] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Parking.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:horde, "~> 0.7.1"},
      {:libcluster, "~> 3.1"},
      {:phoenix, "~> 1.4.11"},
      {:phoenix_pubsub, "~> 1.1"},
      {:phoenix_html, "~> 2.11"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:gettext, "~> 0.11"},
      {:jason, "~> 1.0"},
      {:plug_cowboy, "~> 2.0"},
      {:prometheus, "~> 4.5"},
      {:prometheus_ex, "~> 3.0"},
      {:prometheus_phoenix, "~> 1.3"},
      {:prometheus_plugs, "~> 1.1.5"},
      {:prometheus_process_collector, "~> 1.4"},
      {:telemetry, "~> 0.4.1"}
    ]
  end
end
