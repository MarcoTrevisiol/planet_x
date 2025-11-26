defmodule FactSerializationTest do
  use ExUnit.Case, async: true

  import FactSerialization

  test "can serialize simple data structures" do
    serialized = serialize([1, 2])

    assert serialized == "[1, 2]"
  end

  test "can deserialize simple data structures" do
    deserialized_list = deserialize!("[1, 2]")
    deserialized_tuple = deserialize!("{1, 2}")

    assert deserialized_list == [1, 2]
    assert deserialized_tuple == {1, 2}
  end

  test "deserialization fails if data is too much" do
    very_long_term = "{" <> String.duplicate("1,", 2000) <> "1}"

    assert_raise RuntimeError, fn -> deserialize!(very_long_term) end
  end

  test "deserialization fails if new atom is found" do
    new_atom_serialized = ":inexistent_atom"

    assert_raise RuntimeError, fn -> deserialize!(new_atom_serialized) end
  end

  test "deserialization fails if arbitrary code is found" do
    dangerous_def = "fn -> nil end"
    dangerous_call = "is_binary?(\"\")"

    assert_raise RuntimeError, fn -> deserialize!(dangerous_def) end
    assert_raise RuntimeError, fn -> deserialize!(dangerous_call) end
  end
end
