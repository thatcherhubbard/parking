# Parking

A simple example of running clustered processes and sharing state across them using a 𝛿-CRDT mechanism based on [this series of articles](https://metasyntactic.info/distributing-phoenix-part-1/) by Erik Reedstrom.

It seems he originally planned on writing a longer series on the subject, but even with just the two articles it's a concise and valuable run through the nuts-and-bolts of exploiting Elixir/BEAM clustering in Kubernetes, and also a nice introduction to CRDT mechanisms. Finally, it also is a decent example of how to use the runtime `Config` module in place of the compile-time `Mix.Config` and the Elixir 1.9+ release facility.

## Requirements

No DB or anything required, it's basically:

- Elixir (1.9.4 was the version developed against)

If you want to actually build a release and deploy it to a Kubernetes cluster:

- Minikube (1.6.2 running K8S 1.16.0 was the version developed against)

## Configuration

Basically, the number of gates to run and the number of spaces in the lot, both of which are simply set as constants in the `lib/parking/application.ex` file.  

There is also the cluster discovery method, which is set in the `config/` directory.  The `dev` environment uses the EPMD method (cookie-based), whereas the `prod` environment uses Kubernetes DNS to discover all the other members of the named service.

## Running It

For actual development workflow, it's easiest to just start up *n* terminal windows and launch as many Elixir interpreters as you need from the root project directory, e.g.

```bash
iex --sname larry --cookie limozeen -S mix
iex --sname gary --cookie limozeen -S mix
iex --sname harry --cookie limozeen -S mix
```

The first process to finish launching will indicate that it has all of the gates running on it.
The demonstration of basic functionality is as simple as running a `track_entry` command in one iex session and then dumping the CRDT state on another and seeing that they're in synch:

```elixir
# On larry
Parking.Lot.track_entry("ABC 123", 1)
```

```elixir
# On gary or harry
DeltaCrdt.read(Parking.Lot.Crdt)
Parking.Lot.track_exit("ABC 123", 1)
Parking.Lot.track_entry("2FAST4U", 3)
```

```elixir
# Back on larry
DeltaCrdt.read(Parking.Lot.Crdt)
```

All four gate GenServers are running on `larry`, so running the `track_exit` and `track_entry` commands on another node demonstrates the distributed nature of the app.

If `larry` is killed at this point, the gates will distribute over the remaining two nodes.  The `read` command should be repeated to demonstrate that state was in fact shared across all the nodes.

## Features

Since it's supposed to be a sandbox for developing good production-ready patterns and explaining the what and why, there's a specific documentation file for each:

- [Telemetry](https://github.com/thatcherhubbard/parking/docs/TELEMETRY.md)

## Interesting things to add

- Use `Config` to get the values for the number of gates and the number at runtime
- Try replacing `Config` with `Vapor`
- Write actual tests
- Write a Helm chart
- ~~Add a `Telemetry` implementation~~ Write useful telemetry instrumenters
- Replace the eventually-consistent CRDT implementation with something based on [Raft](https://github.com/rabbitmq/ra) that won't return a value until there is consensus inside the cluster
- Write a load-testing/benchmarking suite and corresponding telemetry updates (e.g [Benchfella](https://github.com/alco/benchfella))
- Implement a fanout mechanism (e.g [Manifold](https://github.com/discordapp/manifold))

