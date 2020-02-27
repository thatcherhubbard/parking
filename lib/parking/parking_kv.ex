defmodule Parking.ParkingKv do
  require Logger

  def start(_args) do
    # the initial cluster members
    members = Enum.map([Node.self()] ++ Node.list(), fn node -> {:parking_kv, node} end)
    # an arbitrary cluster name
    clusterName = <<"parking_kv">>
    # the config passed to `init/1`, must be a `map`
    config = %{}
    # the machine configuration
    machine = {:module, Parking.Raft.Machine, config}
    # ensure ra is started
    Application.ensure_all_started(:ra)
    # start a cluster instance running the `ra_kv` machine
    :ra.start_cluster(clusterName, machine, members)
  end

  def put(serverid, key, value) do
    :ra.process_command(serverid, {:put, key, value})
  end

  def get(serverid, key) do
    :ra.process_command(serverid, {:get, key})
  end

  def delete(serverid, key) do
    case :ra.process_command(serverid, {:pop, key}) do
      {_state, :deleted} ->
        Logger.info("Deleted #{key} @ " <> DateTime.utc_now())

      _ ->
        Logger.error("Failed to delete #{key} from store.")
    end
  end
end
