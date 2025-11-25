defmodule PlanetX do
  @moduledoc """
  Documentation for `PlanetX`.
  """

  @behaviour Domain
  @impl true
  def all_configurations() do
  end

  @impl true
  def query_types(), do: [:scan]

  @impl true
  def answer(config, {:scan, [type, from, to]}) do
    0
  end
end
