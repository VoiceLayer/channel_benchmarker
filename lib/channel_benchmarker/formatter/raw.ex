defmodule ChannelBenchmarker.Formatter.Raw do
  def output(results, _grouped, _state) do
    IO.inspect(results, limit: :infinity)
  end
end
