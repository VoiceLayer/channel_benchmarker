{opts, _, _} = System.argv() |> OptionParser.parse()
channel_count = Keyword.get(opts, :channels, "100") |> String.to_integer()
host = Keyword.get(opts, :host, "localhost")
port = Keyword.get(opts, :port, "4000") |> String.to_integer()

{:ok, pid} = ChannelBenchmarker.run(%{channel_count: channel_count, host: host, port: port})
Process.monitor(pid)

if not IEx.started? do
  receive do
    {:DOWN, _, :process, ^pid, _}  -> nil
  end
end
