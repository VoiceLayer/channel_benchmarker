defmodule ChannelBenchmarker.Results do
  def output(formatter, results, state) do
    grouped = group_results(results, state.channel_count)
    formatter.output(results, grouped, state)
  end


  defp group_results(results, channel_count) do
    results =
      results
      |> Enum.flat_map(fn {_, result_group} ->
        Enum.flat_map(result_group, fn {_, results} ->
          Enum.map(results, fn %{sent: sent, received: received} -> received - sent end)
        end)
      end)
      |> Enum.sort()

    total_results = length(results)
    average_latency = Enum.sum(results) / total_results
    percentile_95 = calculate_percentile(results, 95)
    max_latency = Enum.max(results)
    min_latency = Enum.min(results)

    bands = %{
      "0-0.5" => Enum.count(results, &(&1 < 500)),
      "0.5-1" =>  Enum.count(results, &(&1 >= 500 && &1 < 1000)),
      "1-2" => Enum.count(results, &(&1 >= 1_000 && &1 < 2_000)),
      "2-5" => Enum.count(results, &(&1 >= 2_000 && &1 < 5_000)),
      "5-10" => Enum.count(results, &(&1 >= 5_000 && &1 < 10_000)),
      "10-20" => Enum.count(results, &(&1 >= 10_000 && &1 < 20_000)),
      "20-50" => Enum.count(results, &(&1 >= 20_000 && &1 < 50_000)),
      "50-100" => Enum.count(results, &(&1 >= 50_000 && &1 < 100_000)),
      "100+" => Enum.count(results, &(&1 >= 100_000))
    }

    %{
      channel_count: channel_count,
      total_results: total_results,
      min_latency: min_latency ,
      max_latency: max_latency,
      average_latency: average_latency,
      percentile_95:  percentile_95,
      bands: bands
    }
  end

  defp calculate_percentile(results, percentile) do
    index =
    (length(results) * (percentile / 100))
    |> Float.ceil()
    |> trunc()

    Enum.at(results, index - 1)
  end
end
