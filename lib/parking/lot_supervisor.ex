defmodule Parking.LotSupervisor do
  use Supervisor

  require Logger

  def start_link([args, opts]) do
    Supervisor.start_link(__MODULE__, args, opts)
  end

  def init(args) do
    children = [
      # Manages distributed state
      {
        DeltaCrdt,
        on_diffs: fn _diffs -> send(Parking.Lot, :update_state) end,
        sync_interval: 300,
        max_sync_size: :infinite,
        shutdown: 30_000,
        crdt: DeltaCrdt.AWLWWMap,
        name: Parking.Lot.Crdt
      },
      # Interface for tracking state of cars through gates
      {Parking.Lot, args}
    ]

    Supervisor.init(children, strategy: :one_for_all)
  end

  @doc """
  Wires up the CRDT.  Note that the spelling of 'neighbourhood'.  It's used
  everywhere, even in the docs, because that's how the function name is spelled
  in the CRDT library, which was apprently written by someone from the UK
  """
  def join_neighbourhood(nodes) do
    # Map all nodes to the CRDT process for that node
    crdts =
      Enum.map(nodes, fn node ->
        :rpc.call(node, Process, :whereis, [Parking.Lot.Crdt])
      end)

    # Creates combinations of all possible node sets in the neighbourhood
    # i.e. for a set [1, 2, 3] -> [{1, [2, 3]}, {2, [1, 3]}, {3, [1, 2]}]
    combos = for crdt <- crdts, do: {crdt, List.delete(crdts, crdt)}

    # Enumerate the list wire up the neighbors
    Enum.each(combos, fn {crdt, crdts} ->
      :ok = DeltaCrdt.set_neighbours(crdt, crdts)
    end)
  end

  def start_raft(_args) do
    # the initial cluster members
    members = Enum.map([Node.list()] ++ Node.self(), fn node -> {:parking, node} end)
    # an arbitrary cluster name
    clusterName = <<"ra_kv">>
    # the config passed to `init/1`, must be a `map`
    config = %{}
    # the machine configuration
    machine = {:module, Parking.Raft.Machine, config}
    # ensure ra is started
    Application.ensure_all_started(:ra)
    # start a cluster instance running the `ra_kv` machine
    :ra.start_cluster(clusterName, machine, members)
  end
end
