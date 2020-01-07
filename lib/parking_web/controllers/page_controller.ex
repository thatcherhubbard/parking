defmodule ParkingWeb.PageController do
  use ParkingWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
