defmodule ChannelBenchmarker.Client do
  require Logger

  alias Phoenix.Channels.GenSocketClient
  @behaviour GenSocketClient

  def start_link(%{host: host, port: port} = opts) do
    GenSocketClient.start_link(
          __MODULE__,
          Phoenix.Channels.GenSocketClient.Transport.WebSocketClient,
          ["ws://#{host}:#{port}/socket/websocket", opts]
        )
  end

  def init([url, opts]) do
    {:connect, url, opts}
  end

  def handle_connected(transport, state) do
    GenSocketClient.join(transport, "rooms:#{state.channel_id}")
    {:ok, state}
  end

  def handle_disconnected(_transport, state) do
    {:ok, state}
  end

  def handle_call(_, _, _, state) do
    {:ok, state}
  end

  def handle_joined(_topic, _payload, _transport, state) do
    send(state.controller, {:client_joined, state.mode, self()})
    {:ok, state}
  end

  def handle_join_error(topic, payload, _transport, state) do
    Logger.error("join error on the topic #{topic}: #{inspect payload}")
    {:ok, state}
  end

  def handle_channel_closed(topic, payload, _transport, state) do
    Logger.error("disconnected from the topic #{topic}: #{inspect payload}")
    {:ok, state}
  end

  def handle_message(_topic, "new:msg", %{"sent_at" => sent_at}, _transport, state) do
    result = %{sent: sent_at, received: System.system_time(:microseconds)}
    send(state.controller, {:result, state.channel_id, result})
    {:stop, :normal, state}
  end

  def handle_reply(_topic, _ref, _payload, _transport, state) do
    {:ok, state}
  end

  def handle_info(:next, _transport, state) do
    send(state.sender, :next)
    {:ok, state}
  end

  def handle_info(_message, _transport, state) do
    {:ok, state}
  end
end
