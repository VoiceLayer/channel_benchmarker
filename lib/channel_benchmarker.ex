defmodule ChannelBenchmarker do
  def run(opts) do
    :ets.new(:gen_socket_client_message_refs, [:public, :set, :named_table])
    ChannelBenchmarker.ControllerSupervisor.start_child(opts)
  end
end
