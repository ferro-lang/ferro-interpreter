defmodule FerroMath do
  def sqrt(x) when x < 0, do: nil
  def sqrt(x), do: :math.sqrt(x)
end
