defmodule PlanetX.Utils do
  def pairs(enum), do: enum |> Enum.to_list() |> p
  def p([]), do: []

  def p([head | tail]) do
    pair(head, tail)
    |> Enum.concat(p(tail))
  end

  defp pair(left, rights), do: Enum.map(rights, fn x -> [left, x] end)
end

defmodule PlanetX do
  @moduledoc """
  Documentation for `PlanetX`.
  """
  @behaviour Domain

  @sectors 1..18

  def query_all_sectors(), do: @sectors |> Enum.map(fn s -> {:sector, [s]} end)

  def query_all_scans(from, object) do
    to = add(from, 8)

    interval =
      if to >= from,
        do: from..to,
        else: Stream.concat(from..18, 1..to)

    interval
    |> PlanetX.Utils.pairs()
    |> Enum.map(fn [l, r] -> {:scan, [object, l, r]} end)
  end

  @impl true
  def all_configurations() do
    generate()
  end

  @impl true
  def query_types(), do: [:scan, :target, :is?, :dist]

  @impl true
  def answer(sky, {:scan, [object, from, to]}) do
    interval =
      if to >= from,
        do: from..to,
        else: Stream.concat(from..18, 1..to)

    interval
    |> Stream.filter(fn s -> sky |> Map.get(s, "-") == object end)
    |> Enum.count()
  end

  def answer(sky, {:target, [sector]}) do
    object = sky |> Map.get(sector, "-")
    if object != "X", do: object, else: "-"
  end

  def answer(sky, {:is?, [sector, object]}) do
    object == sky |> Map.get(sector, "-")
  end

  def answer(sky, {:dist, [min_max_from, from_object, min_max_to, to_object, dist]}) do
    from_sectors = sectors_of(sky, from_object)
    to_sectors = sectors_of(sky, to_object)

    min_or_max(min_max_from).(
      from_sectors
      |> Enum.map(fn fs ->
        min_or_max(min_max_to).(to_sectors |> Enum.map(fn ts -> distance(fs, ts) end))
      end)
    ) <= dist
  end

  def answer(sky, {:sector, [sector]}), do: sky |> Map.get(sector, "-")

  def answer(sky, {:object, [object]}) do
    sectors_of(sky, object)
  end

  defp sectors_of(sky, object) do
    sky
    |> Enum.filter(fn {_key, val} -> val == object end)
    |> Enum.map(fn {key, _val} -> key end)
    |> Enum.sort()
  end

  defp distance(from, to) do
    l_dist = abs(from - to)
    r_dist = abs(18 - from + to)
    min(l_dist, r_dist)
  end

  defp min_or_max(:min), do: &Enum.min/1
  defp min_or_max(:max), do: &Enum.max/1

  @impl true
  def serialize(sky) do
    @sectors
    |> Enum.map(fn i -> sky |> Map.get(i, "-") end)
    |> Enum.join()
  end

  @impl true
  def deserialize(binary) do
    sky =
      binary
      |> String.codepoints()
      |> Enum.with_index()
      |> Enum.map(fn {c, i} -> {i + 1, c} end)
      |> Enum.into(%{})

    {:ok, sky}
  end

  # list all configurations
  alias PlanetX.Utils
  @comet_pairs [2, 3, 5, 7, 11, 13, 17] |> Utils.pairs()
  @dwarf_sectors @sectors
  @dwarf_other 1..4 |> Utils.pairs()
  @x_offsets (6 + 1)..(18 - 2)

  defp generate() do
    [%{}]
    |> Stream.flat_map(&add_dwarf_sector/1)
    |> Stream.flat_map(&add_dwarf_other/1)
    |> Stream.flat_map(&add_x/1)
    |> Stream.flat_map(&add_comets/1)
    |> Stream.flat_map(&add_asteroid_pair/1)
    |> Stream.flat_map(&add_asteroid_pair/1)
    |> Stream.flat_map(&add_gas/1)
    |> Stream.flat_map(&add_gas/1)
  end

  defp add_comets(sky) do
    @comet_pairs
    |> Stream.reject(fn [a, b] -> Map.has_key?(sky, a) or Map.has_key?(sky, b) end)
    |> Stream.map(fn [a, b] -> sky |> Map.put(a, "C") |> Map.put(b, "C") end)
  end

  defp add_dwarf_sector(sky) do
    @dwarf_sectors
    |> Stream.reject(fn s -> Map.has_key?(sky, s) or Map.has_key?(sky, add(s, 5)) end)
    |> Stream.map(fn s -> sky |> Map.put(s, "D") |> Map.put(add(s, 5), "D") |> Map.put(:d, s) end)
  end

  defp add_dwarf_other(sky = %{d: d}) do
    @dwarf_other
    |> Stream.reject(fn [a, b] ->
      Map.has_key?(sky, add(d, a)) or Map.has_key?(sky, add(d, b))
    end)
    |> Stream.map(fn [a, b] -> sky |> Map.put(add(d, a), "D") |> Map.put(add(d, b), "D") end)
  end

  defp add_x(sky = %{d: d}) do
    @x_offsets
    |> Stream.reject(fn s -> Map.has_key?(sky, add(d, s)) end)
    |> Stream.map(fn s -> sky |> Map.put(add(d, s), "X") end)
  end

  @inexisting -18
  defp add_asteroid_pair(sky) do
    existing_asteroid = Map.get(sky, :a, @inexisting)

    @sectors
    |> Stream.reject(fn s -> s <= existing_asteroid end)
    |> Stream.reject(fn s -> Map.has_key?(sky, s) or Map.has_key?(sky, add(s, 1)) end)
    |> Stream.map(fn s -> sky |> Map.put(s, "A") |> Map.put(add(s, 1), "A") |> Map.put(:a, s) end)
  end

  defp add_gas(sky) do
    existing_gas = Map.get(sky, :g, @inexisting)

    @sectors
    |> Stream.reject(fn s -> s <= existing_gas end)
    |> Stream.reject(fn s -> Map.has_key?(sky, s) end)
    |> Stream.reject(fn s -> Map.has_key?(sky, add(s, 1)) and Map.has_key?(sky, add(s, 17)) end)
    |> Stream.map(fn s -> sky |> Map.put(s, "G") |> Map.put(:g, s) end)
    |> Stream.reject(fn sk ->
      Map.has_key?(sk, add(existing_gas, 1)) and Map.has_key?(sk, add(existing_gas, 17))
    end)
  end

  defp add(a, b) do
    s = a + b
    if s > 18, do: s - 18, else: s
  end
end
