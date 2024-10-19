defmodule FerroMath do
  # Math operations
  def sqrt(x), do: :math.sqrt(x)
  def pow(base, exponent), do: :math.pow(base, exponent)
  def log(x), do: :math.log(x)
  def exp(x), do: :math.exp(x)
  def sin(x), do: :math.sin(x)
  def cos(x), do: :math.cos(x)
  def tan(x), do: :math.tan(x)
  def asin(x), do: :math.asin(x)
  def acos(x), do: :math.acos(x)
  def atan(x), do: :math.atan(x)
  def atan2(y, x), do: :math.atan2(y, x)
  def sinh(x), do: :math.sinh(x)
  def cosh(x), do: :math.cosh(x)
  def tanh(x), do: :math.tanh(x)
  def asinh(x), do: :math.asinh(x)
  def acosh(x), do: :math.acosh(x)
  def atanh(x), do: :math.atanh(x)
  def erf(x), do: :math.erf(x)
  def erfc(x), do: :math.erfc(x)

  # You can replace log1p/1 and erfinv/1 with alternatives:
  # Approximation
  def log1p(x), do: :math.log(1.0 + x)
  # Not a direct inverse, but best available alternative
  def erfinv(x), do: :math.erf(x)

  # For hypot, you can manually calculate it using the Pythagorean theorem:
  def hypot(x, y), do: :math.sqrt(x * x + y * y)
end
