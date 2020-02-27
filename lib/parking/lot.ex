defmodule Parking.Lot do
  use GenServer

  require Logger

  alias Parking.ParkingKv

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

    # Set vehicles from CRDT if present
    vehicles = crdt_state |> Map.get(:vehicle, []) |> Map.new()
    state = Map.put(state, :vehicles, vehicles)

    {:ok, state}
  end

  def track_entry(license, gate_number) do
    GenServer.cast(__MODULE__, {:track_entry, license, gate_number})
    :telemetry.execute([:lot_supervisor, :lot_status, :car_entry], %{}, %{})
  end

  def track_exit(license, gate_number) do
    GenServer.cast(__MODULE__, {:track_exit, license, gate_number})
    :telemetry.execute([:lot_supervisor, :lot_status, :car_exit], %{}, %{})
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

    time = %{time: DateTime.utc_now()}

    ParkingKv.put({:parking_kv, Node.self()}, license, time)
    vehicles = state |> Map.get(:vehicles) |> Map.put(license, time)

    {:noreply, %{state | vehicles: vehicles}}
  end

  def handle_cast({:track_exit, license, gate_number}, state) do
    Logger.info("===> Vehicle '#{license}' exited through gate #{gate_number}")

    # Update CRDT and state

    ParkingKv.delete({:parking_kv, Node.self()}, license)
    vehicles = state |> Map.get(:vehicles) |> Map.delete(license)

    {:noreply, %{state | vehicles: vehicles}}
  end

  def handle_cast({:track_parked, license, stall_number}, state) do
    Logger.info("===> Vehicle '#{license}' parked in stall #{stall_number}")

    # Update CRDT and state

    :ra.process_command(Node.self(), {:update, license, update = %{stall_number: stall_number}})
    vehicles = state |> Map.get(:vehicles) |> Map.merge(license, update)

    {:noreply, %{state | vehicles: vehicles}}
  end

  def handle_info(:update_state, state) do
    # Read CRDT state and group by key type
    crdt_state =
      DeltaCrdt.read(@crdt)
      |> Enum.group_by(fn {{k, _}, _} -> k end, fn {{_, kv}, v} -> {kv, v} end)

    # Set vehicles from CRDT if present
    vehicles = crdt_state |> Map.get(:vehicle, []) |> Map.new()
    state = Map.put(state, :vehicles, vehicles)

    {:noreply, state}
  end
end
