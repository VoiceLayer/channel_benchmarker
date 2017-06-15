defmodule ChannelBenchmarker.Formatter.Raw do
  def output(results, grouped, state) do
    IO.inspect(results, limit: :infinity)
  end
end
