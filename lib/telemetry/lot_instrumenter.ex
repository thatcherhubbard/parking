defmodule Parking.Telemetry.LotInstrumenter do
  require Logger

  use Prometheus.Metric

  def setup do
    events = [
      [:lot_supervisor, :lot_status, :car_entry],
      [:lot_supervisor, :lot_status, :car_exit]
    ]

    Gauge.declare(name: :entry_event_count, help: "Total entry events")
    Gauge.declare(name: :exit_event_count, help: "Total exit events")

    :telemetry.attach_many("lot-instrumenter", events, &handle_event/4, nil)
  end

  @doc """
  Uses a Gauge.inc because the calling function knows neither lot size nor
  the current car count
  """
  def handle_event(
        [:lot_supervisor, :lot_status, :car_entry],
        _measurements,
        _metadata,
        _config
      ) do
    Gauge.inc(name: :entry_event_count)
  end

  def handle_event(
        [:lot_supervisor, :lot_status, :car_exit],
        _measurements,
        _metadata,
        _config
      ) do
    Gauge.inc(name: :exit_event_count)
  end
end
