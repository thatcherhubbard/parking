# Parking Telemetry

This of course uses the Elixir `Telemetry` package, but there are a couple of differences from most of the examples of its use available online.  This is mainly in the interest of keeping the code clean and also running a separate endpoint for telemetry so it's easier to configure and secure in the contenxt of a K8S cluster.

The `Telemetry` package doesn't prescribe any specific method of exposing the telemetry data collected.  For the purposes of this project, the assumption is an endpoint that will get scraped by [Prometheus](https://prometheus.io/).  The K8S deployment resources will include annotations that tell a cluster-resident Prometheus to scrape the application containers and what port to scrape them on.

## Directory structure

What's in the repo is "experimental" as in, "I'm seeing if it makes any sense".  The `telemetry` directory is under `lib`, parallel to `parking` and `parking_web`.  It's a Phoenix endpoint of it's own, though it only has one page.

The idea is to try this out versus having the telemetry code distributed around in the application directory.

## Setup

The first step is to make sure the dependecies are included in the project configuration.  So add the following to `deps` function in `mix.exs`:

```elixir
      {:prometheus, "~> 4.5"},
      {:prometheus_ex, "~> 3.0"},
      {:prometheus_phoenix, "~> 1.3"},
      {:prometheus_plugs, "~> 1.1.5"},
      {:prometheus_process_collector, "~> 1.4"},
      {:telemetry, "~> 0.4.1"}
```

## Endpoint

Because it has it's own endpoint, it needs a minimal set of files for Phoenix:

- `endpoint.ex`
- `router.ex`
- `page_controller.ex`

The router and page controller files are pretty self-explanatory. The endpoint file is straigtforward, but there are a few `plug` calls at the bottom that implement that actual `/metrics` endpoint.

## Config

Because it's a separate endpoint, there are entries in the Elixir config directory that need to be made. The important bit is the configuration of the `Parking.Telemetry.Endpoint` module.   This follows the normal pattern of static config values in the `dev.exs` file, with environment variable substitution set up in the `releases.exs` file.

The main `application.ex` file also needs changes to start the metrics endpoint along with the main app.  The lines that accomplish this are pretty clearly commented.

## Instrumenters

This is where the actual implementation of specific measurements is done.  For the Phoenix metrics, it's a simple `use` command because Phoenix already has intruments built into it.  You'll need to wrap whatever event(s) you want to respond to in the proper function spec, but aside from matching a signature, you can do whatever you want.

