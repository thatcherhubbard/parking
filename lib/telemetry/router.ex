defmodule Parking.Telemetry.Router do
  use ParkingWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", Parking.Telemetry do
    # Use the default browser stack
    pipe_through :api

    get "/", PageController, :index
  end
end
