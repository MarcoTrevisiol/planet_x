defmodule ServerApplication do
  @moduledoc false
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # start a single RemoteServer with a registered name
      {Server, []}
    ]

    opts = [strategy: :one_for_one, name: ServerSupervisor]
    Supervisor.start_link(children, opts)
  end
end
