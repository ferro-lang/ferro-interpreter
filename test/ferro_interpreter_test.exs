defmodule FerroInterpreterTest do
  use ExUnit.Case
  doctest FerroInterpreter

  test "greets the world" do
    assert FerroInterpreter.hello() == :world
  end
end
