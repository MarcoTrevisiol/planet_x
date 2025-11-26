defmodule FactSerialization do
  @spec serialize(term()) :: binary()
  def serialize(term) do
    inspect(term,
      pretty: true,
      limit: :infinity,
      printable_limit: :infinity
    )
  end

  @max_size 2048

  @spec deserialize!(binary()) :: term()
  def deserialize!(term) when not is_binary(term), do: raise("invalid term")
  def deserialize!(term) when byte_size(term) > @max_size, do: raise("term is too big")

  def deserialize!(string) do
    case Code.string_to_quoted(string, existing_atoms_only: true) do
      {:ok, ast} ->
        ensure_literals_only!(ast)
        {value, _binding} = Code.eval_quoted(ast)
        value

      {:error, reason} ->
        raise "invalid term string: #{inspect(reason)}"
    end
  end

  defp ensure_literals_only!(ast) do
    case only_literals?(ast) do
      true -> :ok
      false -> raise "non-literal code detected: #{inspect(ast)}"
    end
  end

  defp only_literals?(term)
       when is_integer(term)
       when is_float(term)
       when is_binary(term)
       when is_atom(term),
       do: true

  defp only_literals?([]), do: true
  defp only_literals?([head|tail]), do: only_literals?(head) and only_literals?(tail)

  defp only_literals?({a, b}), do: only_literals?(a) and only_literals?(b)
  defp only_literals?({:{}, _, content}), do: only_literals?(content)

  defp only_literals?(_), do: false
end
