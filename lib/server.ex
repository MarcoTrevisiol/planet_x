defmodule Server do
  use GenServer

  @type state :: Engine.t() | nil
  @timeout 10_000

  # --- Public API (used by Remote wrapper) ---

  @doc """
  Start a new engine with a fresh state for domain_mod
  """
  def new(domain_mod) do
    GenServer.call(__MODULE__, {:new, domain_mod})
  end

  @doc """
  Load engine state from file for a given domain module.

  The file is expected to contain a term: a list of serialized configs (binaries).
  """
  def load(domain_mod) do
    GenServer.call(__MODULE__, {:load, domain_mod})
  end

  @doc """
  Load engine state from a list of facts
  """
  def load_facts(domain_mod) do
    GenServer.call(__MODULE__, {:load_facts, domain_mod})
  end

  @doc """
  Dump current active configs to file.

  The file will contain a term: list of binaries.
  """
  def dump() do
    GenServer.call(__MODULE__, :dump, @timeout)
  end

  @doc """
  Add a fact (query, result) to the engine.
  """
  def add(query, result) do
    GenServer.call(__MODULE__, {:add, query, result}, @timeout)
  end

  @doc """
  Run a query against the current engine.

  Returns %{distribution: map, entropy: float}.
  """
  def query(query) do
    GenServer.call(__MODULE__, {:query, query}, @timeout)
  end

  @doc """
  Retrieve list of included facts
  """
  def facts() do
    GenServer.call(__MODULE__, :facts)
  end

  # --- GenServer callbacks ---

  def start_link(_opts) do
    # Registered name ensures a single global instance
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @impl true
  def init(:ok) do
    {:ok, nil}
  end

  @impl true
  def handle_call({:load, domain_mod}, _from, state) do
    filename = Atom.to_string(domain_mod) <> ".configurations"

    case File.read(filename) do
      {:ok, content} ->
        case Engine.load(domain_mod, content) do
          {:ok, engine} ->
            {:reply, :ok, engine}

          error ->
            {:reply, {:error, error}, state}
        end

      {:error, reason} ->
        {:reply, {:error, {:file_error, reason}}, state}
    end
  end

  def handle_call({:load_facts, domain_mod}, _from, state) do
    filename = Atom.to_string(domain_mod) <> ".facts"

    case File.read(filename) do
      {:ok, content} ->
        facts = FactSerialization.deserialize!(content)
        engine = Engine.new(domain_mod) |> Engine.set_facts(facts)
        {:reply, :ok, engine}
      {:error, reason} ->
        {:reply, {:error, {:file_error, reason}}, state}
    end
  end

  def handle_call({:new, domain_mod}, _from, _state) do
    {:reply, :ok, Engine.new(domain_mod)}
  end

  def handle_call(:dump, _from, nil = state) do
    {:reply, {:error, :no_engine_loaded}, state}
  end

  def handle_call(:dump, _from, engine = state) do
    serialized = Engine.dump(engine)

    filename = Atom.to_string(engine.domain) <> ".configurations"
    reply = File.write(filename, serialized)
    {:reply, reply, state}
  end

  def handle_call({:add, _query, _result}, _from, nil = state) do
    {:reply, {:error, :no_engine_loaded}, state}
  end

  def handle_call({:add, query, result}, _from, engine) do
    updated = Engine.add_fact(engine, {query, result})
    facts = updated.facts |> FactSerialization.serialize
    filename = Atom.to_string(engine.domain) <> ".facts"
    File.write!(filename, facts)
    {:reply, :ok, updated}
  end

  def handle_call({:query, _query}, _from, nil = state) do
    {:reply, {:error, :no_engine_loaded}, state}
  end

  def handle_call({:query, query}, _from, engine = state) do
    dist = Engine.distribution(engine, query)
    entropy = Engine.entropy(engine, query)
    {:reply, %{distribution: dist, entropy: entropy}, state}
  end

  def handle_call(:facts, _from, nil = state) do
    {:reply, {:error, :no_engine_loaded}, state}
  end

  def handle_call(:facts, _from, engine) do
    {:reply, engine.facts, engine}
  end
end
