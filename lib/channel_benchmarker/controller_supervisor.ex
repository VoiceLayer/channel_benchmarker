defmodule ChannelBenchmarker.ControllerSupervisor do
  # Automatically imports Supervisor.Spec
  use Supervisor

  def start_link(_) do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init([]) do
    children = [
      worker(ChannelBenchmarker.Controller, [], restart: :temporary)
    ]

    supervise(children, strategy: :simple_one_for_one)
  end

  def start_child(opts) do
    Supervisor.start_child(__MODULE__, [opts])
  end
end
