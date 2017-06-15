defmodule ChannelBenchmarker.Formatter.Map do
  def output(results, _grouped, _state) do
    results
    |> Enum.reduce(%{}, fn ({id, result_set}, acc) ->
      Map.put(acc, id, Enum.reduce(result_set, %{}, fn ({pid, results}, acc2) ->
          Map.put(acc2, pid, Enum.map(results, fn %{sent: sent, received: received} ->
            received - sent
          end))
       end))
    end) |> IO.inspect(limit: :infinity)
  end
end
