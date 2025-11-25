defmodule Domain do
  @moduledoc """
  Problem-specific logic: configs, queries, outputs.
  """

  @type config :: term()
  @type query_type :: atom()
  @type query_param :: term()
  @type query :: {query_type(), [query_param()]}
  @type output :: non_neg_integer()

  @callback all_configurations() :: [config()]
  @callback query_types() :: [query_type()]

  # Given a configuration and a query, compute the output.
  @callback answer(config(), query()) :: output()
end
