defmodule Parking.Raft.Machine do
  @moduledoc """
  Implements a Raft state machine for the purposes of storing:
  - The license plate number -> key
  - A map as the value that includes:
    - Entry time
    - Space identifier
  Additionally, the entry and exit gates will be logged and on exit, the time spent
  in the lot will be calculated, logged and written to DB.
  """
  @behaviour :ra_machine

  @impl :ra_machine
  def init(_args) do
    %{}
  end

  @impl :ra_machine
  def apply(_meta, {:get, key}, state) do
    reply = Map.get(state, key, nil)
    {state, reply}
  end

  @impl :ra_machine
  def apply(_meta, {:put, key, value}, state) do
    {Map.put(state, key, value), :inserted}
  end

  @impl :ra_machine
  def apply(_meta, {:update, key, value}, state) do
    old = Map.fetch!(state, key)
    new = Map.merge(old, value)
    {Map.put(state, key, new), :updated}
  end

  @impl :ra_machine
  def apply(_meta, {:delete, key}, state) do
    {Map.delete(state, key), :deleted}
  end
end
