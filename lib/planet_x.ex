defmodule PlanetX do
  @moduledoc """
  Documentation for `PlanetX`.
  """
  @behaviour Domain

  @sectors 1..18

  
  @impl true
  def all_configurations() do
  end

  @impl true
  def query_types(), do: [:scan]

  @impl true
  def answer(sky, {:scan, [object, from, to]}) do
    interval = if to >= from,
      do: from..to,
      else: Stream.concat(from..18, 1..to)

    interval
    |> Stream.filter(fn s -> sky |> Map.get(s, "-") == object end)
    |> Enum.count
  end

  def answer(sky, {:target, [sector]}) do
    object = sky |> Map.get(sector, "-")
    if object != "X", do: object, else: "-"
  end

  @impl true
  def serialize(sky) do
    @sectors
    |> Enum.map(fn i -> sky |> Map.get(i, "-") end)
    |> Enum.join
  end

  @impl true
  def deserialize(binary) do
    sky = binary
    |> String.codepoints
    |> Enum.with_index
    |> Enum.map(fn {c, i} -> {i, c} end)
    |> Enum.into(%{})

    {:ok, sky}
  end
end
