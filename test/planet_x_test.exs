defmodule PlanetXTest do
  use ExUnit.Case, async: true

  @sky "AADD--DDAAX-CG-GC-"

  test "deserialize correctly" do
    {:ok, sky} = PlanetX.deserialize(@sky)

    assert PlanetX.answer(sky, {:sector, [11]}) == "X"
  end

  test "distance works" do
    {:ok, sky} = PlanetX.deserialize(@sky)

    assert PlanetX.answer(sky, {:dist, [:min, "A", :min, "D", 1]})
    assert PlanetX.answer(sky, {:dist, [:max, "A", :min, "D", 2]})
    assert PlanetX.answer(sky, {:dist, [:min, "A", :max, "D", 6]})
    assert PlanetX.answer(sky, {:dist, [:max, "A", :max, "D", 7]})

    assert not PlanetX.answer(sky, {:dist, [:min, "A", :min, "D", 0]})
    assert not PlanetX.answer(sky, {:dist, [:max, "A", :min, "D", 1]})
    assert not PlanetX.answer(sky, {:dist, [:min, "A", :max, "D", 5]})
    assert not PlanetX.answer(sky, {:dist, [:max, "A", :max, "D", 6]})

    assert PlanetX.answer(sky, {:dist, [:max, "G", :max, "G", 2]})
    assert not PlanetX.answer(sky, {:dist, [:max, "G", :max, "G", 1]})
  end

  test "wierd distance" do
    {:ok, sky} = PlanetX.deserialize("ACAADD--DD-XCG--GA")

    assert PlanetX.answer(sky, {:dist, [:max, "A", :max, "A", 15]})
  end
end
