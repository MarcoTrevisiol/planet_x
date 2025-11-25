defmodule TestDomain do
  @behaviour Domain

  @impl true
  def all_configurations() do
    Enum.to_list(0..3)
  end

  @impl true
  def query_types(), do: [:is?]

  @impl true
  def answer(config, {:is?, [param]}) do
    config == param
  end
end

defmodule EngineTest do
  use ExUnit.Case, async: true

  test "engine starts with 10 configurations" do
    engine = Engine.new(TestDomain)

    # Check counts
    assert length(engine.full_configs) == 4
    assert length(engine.active_configs) == 4

    # Check actual values are 0..9
    assert engine.full_configs == Enum.to_list(0..3)
  end

  test "after a fact, possible configurations are reduced" do
    engine = Engine.new(TestDomain) |> Engine.add_fact({{:is?, [0]}, false})

    assert length(engine.active_configs) == 3
    refute 0 in engine.active_configs

    updated_engine = engine |> Engine.add_fact({{:is?, [1]}, true})

    assert updated_engine.active_configs == [1]
  end

  test "entropy works as expected" do
    engine = TestDomain |> Engine.new()
    |> Engine.add_fact({{:is?, [0]}, false})
    |> Engine.add_fact({{:is?, [1]}, false})

    # after those two facts, only 2 and 3 are possible
    # therefore, a non-trivial query gets exactly 1 bit of information
    assert Engine.entropy(engine, {:is?, [2]}) == 1.0
  end
end

