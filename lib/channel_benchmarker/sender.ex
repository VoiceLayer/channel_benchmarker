defmodule ChannelBenchmarker.Sender do
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

  def handle_call(_, _, _, state) do
    {:ok, state}
  end

  def handle_connected(transport, state) do
    GenSocketClient.join(transport, "rooms:#{state.channel_id}")
    {:ok, state}
  end

  def handle_disconnected(_transport, state) do
    {:ok, state}
  end

  def handle_joined(_topic, _payload, _transport, state) do
    send(state.controller, {:client_joined, state.mode, self()})
    {:ok, state}
  end

  def handle_join_error(_topic, _payload, _transport, state) do
    {:ok, state}
  end

  def handle_channel_closed(_topic, _payload, _transport, state) do
    {:ok, state}
  end

  def handle_message(_topic, _message, _payload, _transport, state) do
    {:ok, state}
  end


  def handle_reply(_topic, _ref, _payload, _transport, state) do
    case state.message_count do
      1 -> {:stop, :normal, state}
      count -> {:ok, %{state | message_count: count - 1}}
    end
  end

  def handle_info(:next, transport, state) do
    GenSocketClient.push(transport, "rooms:#{state.channel_id}",
      "new:msg", %{sent_at: System.system_time(:microseconds)})
    {:ok, state}
  end
  def handle_info(_message, _transport, state) do
    {:ok, state}
  end
end
