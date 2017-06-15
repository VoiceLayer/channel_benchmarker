defmodule ChannelBenchmarker.Formatter.Terminal do
  def output(results, grouped, state) do
    output_result(grouped, state)
  end

  defp output_result(results, state) do
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


                    Channels: #{results.channel_count}
        Messages Per Channel: #{state.message_count}
           Users Per Channel: #{state.users_per_channel}
               Total Results: #{results.total_results}

                 Min Latency: #{format_time(results.min_latency)}
             Average Latency: #{format_time(results.average_latency)}
             95th Percentile: #{format_time(results.percentile_95)}
                 Max Latency: #{format_time(results.max_latency)}

    """
    |> IO.ANSI.Docs.print()

  end

  defp format_time(time) do
    "#{Float.round(time / 1000, 2)}ms"
  end
end
