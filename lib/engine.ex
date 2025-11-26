defmodule Engine do
  @moduledoc """
  Pure engine: filters configs by facts, computes distributions and entropy.
  """

  @type config :: Domain.config()
  @type query :: Domain.query()
  @type output :: Domain.output()
  @type fact :: {query(), output()}
  @type dist :: %{output() => float()}

  defstruct [
    :domain,
    :full_configs,
    :active_configs,
    :facts
  ]

  @type t :: %__MODULE__{
          domain: module(),
          full_configs: [config()],
          active_configs: [config()],
          facts: [fact()]
        }

  # --- construction ---

  @spec new(module()) :: t()
  def new(domain_mod) do
    full = domain_mod.all_configurations()

    %__MODULE__{
      domain: domain_mod,
      full_configs: full,
      active_configs: full,
      facts: []
    }
  end

  # --- persistence helpers ---

  @spec dump(t()) :: [binary()]
  def dump(%__MODULE__{domain: domain, active_configs: configs}) do
    Stream.map(configs, &domain.serialize/1)
    |> Enum.intersperse("\n")
  end

  @spec load(module(), binary()) :: {:ok, t()} | {:invalid_config_errors, [binary()]}
  def load(domain_mod, serialized_binary) do
    serialized_list = String.split(serialized_binary, "\n")

    {oks, errors} =
      serialized_list
      |> Enum.reduce({[], []}, fn bin, {ok_acc, err_acc} ->
        case domain_mod.deserialize(bin) do
          {:ok, cfg} ->
            {[cfg | ok_acc], err_acc}

          :invalid_config_error ->
            {ok_acc, [bin | err_acc]}
        end
      end)

    case errors do
      [] ->
        full = Enum.reverse(oks)

        {:ok,
         %__MODULE__{
           domain: domain_mod,
           full_configs: full,
           active_configs: full,
           facts: []
         }}

      _ ->
        {:invalid_config_errors, Enum.reverse(errors)}
    end
  end

  # --- facts management ---

  @spec facts(t()) :: [fact()]
  def facts(%__MODULE__{facts: facts}), do: facts

  @spec add_fact(t(), fact()) :: t()
  def add_fact(
        %__MODULE__{domain: domain, active_configs: active, facts: facts} = st,
        {query, observed} = fact
      ) do
    updated_cfgs =
      active
      |> Enum.filter(fn cfg -> domain.answer(cfg, query) == observed end)

    updated_facts = facts ++ [fact]

    %__MODULE__{st | active_configs: updated_cfgs, facts: updated_facts}
  end

  @spec set_facts(t(), [fact()]) :: t()
  def set_facts(state, facts) do
    facts
    |> Enum.reduce(state, fn fact, acc -> add_fact(acc, fact) end)
  end

  # --- queries: distributions and entropy ---

  defp frequencies(%__MODULE__{domain: domain, active_configs: configs}, query) do
    configs
    |> Stream.map(&domain.answer(&1, query))
    |> Enum.frequencies()
  end

  @spec distribution(t(), query()) :: dist()
  def distribution(%__MODULE__{} = st, query) do
    freqs = frequencies(st, query)
    count = freqs |> Map.values() |> Enum.sum()

    freqs
    |> Enum.map(fn {key, val} -> {key, val / count} end)
    |> Enum.into(%{})
  end

  @spec entropy(t(), query()) :: float()
  def entropy(%__MODULE__{} = st, query) do
    freqs = frequencies(st, query)
    count = freqs |> Map.values() |> Enum.sum()

    freqs
    |> Enum.map(fn {_key, c} -> if c <= 0, do: 0, else: -c / count * :math.log2(c / count) end)
    |> Enum.sum()
  end
end
