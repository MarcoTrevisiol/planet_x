defmodule PlanetXTest do
  use ExUnit.Case, async: true

  @sky "AADD--DDAAX-CG-GC-"

  test "deserialize correctly" do
    {:ok, sky} = PlanetX.deserialize(@sky)

    assert PlanetX.answer(sky, {:sector, [11]}) == "X"
  end

  test "distance works" do
    {:ok, sky} = PlanetX.deserialize(@sky)

    assert PlanetX.distance(sky, "X", "A") == MapSet.new([1, 2, 8, 9])
  end
end
