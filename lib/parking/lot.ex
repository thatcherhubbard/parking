defmodule Parking.Lot do
  use GenServer

  require Logger

  @crdt Parking.Lot.Crdt

  ## Client API

  def child_spec(config) do
    %{id: __MODULE__, start: {__MODULE__, :start_link, [config]}}
  end

  def start_link(config) do
    {:ok, _pid} = GenServer.start_link(__MODULE__, Map.new(config), name: __MODULE__)
  end

  def init(state) do
    Logger.warn("===> Parking.Lot interfaced for #{inspect(Node.self())}")

    crdt_state =
      DeltaCrdt.read(@crdt)
      |> Enum.group_by(fn {{k, _}, _} -> k end, fn {{_, kv}, v} -> {kv, v} end)

    # Set vehicles from CRTD if present
    vehicles = crdt_state |> Map.get(:vehicle, []) |> Map.new()
    state = Map.put(state, :vehicles, vehicles)

    {:ok, state}
  end

  def track_entry(license, gate_number) do
    GenServer.cast(__MODULE__, {:track_entry, license, gate_number})
  end

  def track_exit(license, gate_number) do
    GenServer.cast(__MODULE__, {:track_exit, license, gate_number})
  end

  def available_spaces(), do: GenServer.call(__MODULE__, :available_spaces)

  def vehicles(), do: GenServer.call(__MODULE__, :vehicles)

  ## Server Callbacks

  def handle_call(:available_spaces, _from, %{max_spaces: max_spaces, vehicles: vehicles} = state) do
    {:reply, max_spaces - map_size(vehicles), state}
  end

  def handle_call(:vehicles, _from, %{vehicles: vehicles} = state) do
    {:reply, vehicles, state}
  end

  def handle_cast({:track_entry, license, gate_number}, state) do
    Logger.info("===> Vehicle '#{license}' entered through gate #{gate_number}")

    # Update CRDT and state

    time = System.monotonic_time()

    DeltaCrdt.mutate(@crdt, :add, [{:vehicle, license}, time], :infinity)
    vehicles = state |> Map.get(:vehicles) |> Map.put(license, time)

    {:noreply, %{state | vehicles: vehicles}}
  end

  def handle_cast({:track_exit, license, gate_number}, state) do
    Logger.info("===> Vehicle '#{license}' exited through gate #{gate_number}")

    # Update CRDT and state

    time = System.monotonic_time()

    DeltaCrdt.mutate(@crdt, :remove, [{:vehicle, license}, time], :infinity)
    vehicles = state |> Map.get(:vehicles) |> Map.delete(license)

    {:noreply, %{state | vehicles: vehicles}}
  end

  def handle_info(:update_state, state) do
    # Read CRDT stater and group by key type
    crdt_state =
      DeltaCrdt.read(@crdt)
      |> Enum.group_by(fn {{k, _}, _} -> k end, fn {{_, kv}, v} -> {kv, v} end)

    # Set vehicles from CRDT if present
    vehicles = crdt_state |> Map.get(:vehicle, []) |> Map.new()
    state = Map.put(state, :vehicles, vehicles)

    {:noreply, state}
  end
end
