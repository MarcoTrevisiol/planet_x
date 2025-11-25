defmodule PlanetXTest do
  use ExUnit.Case
  doctest PlanetX

  test "greets the world" do
    assert PlanetX.hello() == :world
  end
end
