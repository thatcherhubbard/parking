defmodule Parking.Telemetry.PageController do
  use ParkingWeb, :controller

  def index(conn, _params) do
    json(conn, %{status: "ok"})
  end
end
