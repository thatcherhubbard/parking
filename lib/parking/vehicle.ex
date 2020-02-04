defmodule Parking.Vehicle do
  def generate() do
    :crypto.strong_rand_bytes(7) |> Base.encode32() |> binary_part(0, 7)
  end
end
