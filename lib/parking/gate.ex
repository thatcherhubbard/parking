defmodule Parking.Gate do
  use GenServer

  require Logger

  ## Client API

  def child_spec(number),
    do: %{id: id(number), start: {__MODULE__, :start_link, [number]}}

  def start_link(number) do
    state = %{number: number}

    # Register with gate number as unique ID
    {:ok, _pid} = GenServer.start_link(__MODULE__, state, name: via_registry(number))
  end

  def init(%{number: number} = state) do
    Logger.warn("===> Gate No. #{number} running on #{inspect(Node.self())}")
    Logger.debug(inspect(state, pretty: true))
    {:ok, state}
  end

  def id(number), do: String.to_atom("gate-" <> to_string(number))

  # Vehicle enters the lot
  def enter(number, license) do
    GenServer.cast(via_registry(number), {:enter, license})
  end

  # Vehicle exits the lot
  def exit(number, license) do
    GenServer.cast(via_registry(number), {:exit, license})
  end

  ## Private functions

  defp via_registry(number) do
    {:via, Horde.Registry, {Parking.Registry, id(number)}}
  end

  ## Server callbacks

  def handle_cast({:enter, license}, %{number: number} = state) do
    if Parking.Lot.available_spaces() >= 0 do
      Parking.Lot.track_entry(license, number)
    else
      Logger.warn("===> Gate number #{number} reporting lot full.")
    end

    {:noreply, state}
  end

  def handle_cast({:exit, license}, %{number: number} = state) do
    Parking.Lot.track_exit(license, number)
    {:noreply, state}
  end
end
