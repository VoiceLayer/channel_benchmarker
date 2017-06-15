defmodule ChannelBenchmarker.Results do
  def output(results, state) do
    results
    |> group_results(state.channel_count)
    |> output_result()
  end

  defp output_result(results) do
    bands = results.bands

    IO.ANSI.Docs.print_heading("Results")

    """
    | Band (ms)     | Count                   |
    | ------------: | :---------------------- |
    | 0-0.5         | #{bands["0-0.5"]}       |
    | 0.5-1         | #{bands["0.5-1"]}       |
    | 1-2           | #{bands["1-2"]}         |
    | 2-5           | #{bands["2-5"]}         |
    | 5-10          | #{bands["5-10"]}        |
    | 10-20         | #{bands["10-20"]}       |
    | 20-50         | #{bands["20-50"]}       |
    | 50-100        | #{bands["50-100"]}      |
    | 100+          | #{bands["100+"]}        |


        Channels:         #{results.channel_count}
        Total Messages:   #{results.total_messages}

        Min Latency:      #{format_time(results.min_latency)}
        Average Latency:  #{format_time(results.average_latency)}
        95th Percentile:  #{format_time(results.percentile_95)}
        Max Latency:      #{format_time(results.max_latency)}

    """
    |> IO.ANSI.Docs.print()

  end

  defp group_results(results, channel_count) do
    results =
      results
      |> Enum.flat_map(fn {_, results} ->
        Enum.map(results, fn %{sent: sent, received: received} -> received - sent end)
      end)
      |> Enum.sort()

    total_messages = length(results)
    average_latency = Enum.sum(results) / total_messages
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
      total_messages: total_messages,
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

  defp format_time(time) do
    "#{Float.round(time / 1000, 2)}ms"
  end
end
