{opts, _, _} = System.argv() |> OptionParser.parse()
channel_count = Keyword.get(opts, :channels, "100") |> String.to_integer()
message_count = Keyword.get(opts, :messages, "100") |> String.to_integer()
users_per_channel = Keyword.get(opts, :users_per_channel, "2") |> String.to_integer()
format = Keyword.get(opts, :format, "terminal")
host = Keyword.get(opts, :host, "localhost")
port = Keyword.get(opts, :port, "4000") |> String.to_integer()

formatter =
  case format do
    "raw" -> ChannelBenchmarker.Formatter.Raw
    "map" -> ChannelBenchmarker.Formatter.Map
    _ -> ChannelBenchmarker.Formatter.Terminal
  end

{:ok, pid} = ChannelBenchmarker.run(%{channel_count: channel_count,
                                      message_count: message_count,
                                      formatter: formatter,
                                      users_per_channel: users_per_channel,
                                      host: host,
                                      port: port})
Process.monitor(pid)

if not IEx.started? do
  receive do
    {:DOWN, _, :process, ^pid, _}  -> nil
  end
end
