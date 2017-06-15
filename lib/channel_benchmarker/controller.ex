defmodule ChannelBenchmarker.Controller do
  require Logger
  use GenServer
  alias ChannelBenchmarker.{Client, Sender}

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, [name: __MODULE__])
  end

  def init(%{channel_count: channel_count} = opts) do
    opts = Map.delete(opts, :channel_count)
    pairs =
      for i <- 1..channel_count do
        %{"channel_id" => i}
      end
    send(self(), :connect_clients)
    {:ok, Map.merge(opts, %{pairs: pairs, results: %{}, disconnected_count: 0})}
  end

  def handle_info({:DOWN, _, :process, pid, _}, %{gatherer_pid: pid} = state) do
    {:stop, :normal, state}
  end

  def handle_info(:connect_clients, state) do
    expected_size = length(state.pairs) * state.users_per_channel

    pid_state = %{client_pids: [], expected_clients: expected_size, connected_clients: 0}

    state.pairs
    |> Enum.map(fn pair ->
      opts = %{port: state.port, host: state.host, channel_id: pair["channel_id"],
               message_count: state.message_count, controller: self()}

      {:ok, sender_pid} = Sender.start_link(Map.merge(opts, %{mode: :sender}))
      Process.monitor(sender_pid)

      # 2 because the sender is already in the channel
      for i <- 2..state.users_per_channel do
        {:ok, client_pid} = Client.start_link(Map.merge(opts,
              %{sender: sender_pid, mode: :client, user_id: (i - 1)}))
        Process.monitor(client_pid)
      end
    end)

    {:noreply, Map.merge(state, pid_state)}
  end

  def handle_info({:client_joined, mode, pid},
  %{expected_clients: expected, connected_clients: connected} = state)
  when (connected + 1) == expected do
    pids =
      if mode == :client do
        [pid | state.client_pids]
      else
        state.client_pids
      end

    pids
    |> Enum.map(fn client_pid ->
      send(client_pid, :next)
    end)

    {_, state} = Map.split(state, [:client_pids])
    {:noreply, state}
  end

  def handle_info({:client_joined, :client, pid}, state) do
    state = %{state | client_pids: [pid | state.client_pids],
                      connected_clients: state.connected_clients + 1}
    {:noreply, state}
  end

  def handle_info({:client_joined, :sender, _pid}, state) do
    state = %{state | connected_clients: state.connected_clients + 1}
    {:noreply, state}
  end

  def handle_info({:result, channel_id, user_id, time}, state) do
    channel_id = "channel_#{channel_id}"
    user_id = "user_#{user_id}"
    state = %{state | results: Map.put_new(state.results, channel_id, %{})}
    state = update_in(state.results[channel_id],
      &Map.update(&1, user_id, [time], fn acc -> [time | acc] end))
    {:noreply, state}
  end

  def handle_info({:DOWN, _, _, _, _}, state) do
    state = %{state | disconnected_count: state.disconnected_count + 1}
    if state.disconnected_count >= (length(state.pairs) * state.users_per_channel) do
      ChannelBenchmarker.Results.output(state.formatter, state.results,
        %{channel_count: length(state.pairs), message_count: state.message_count,
          users_per_channel: state.users_per_channel})
      {:stop, :normal, state}
    else
      {:noreply, state}
    end
  end

  def handle_info(message, state) do
    Logger.warn("Unhandled controller message #{inspect message}")
    {:noreply, state}
  end
end
