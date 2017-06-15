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
    pid_state = %{client_pids: [], sender_pids: []}

    state.pairs
    |> Enum.map(fn pair ->
      opts = %{port: state.port, host: state.host, channel_id: pair["channel_id"],
               message_count: state.message_count, controller: self()}
      {:ok, sender_pid} =
        Sender.start_link(Map.merge(opts, %{mode: :sender}))

      {:ok, client_pid} =
      Client.start_link(Map.merge(opts, %{sender: sender_pid, mode: :client}))
      Process.monitor(sender_pid)
      Process.monitor(client_pid)
    end)


    {:noreply, Map.merge(state, pid_state)}
  end

  def handle_info({:client_joined, mode, pid},
  %{pairs: pairs, sender_pids: senders, client_pids: clients} = state)
  when (length(senders) == length(pairs) and length(clients) == length(pairs) - 1)
  or (length(senders) == length(pairs) -1 and length(clients) == length(pairs))
  do
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

    {_, state} = Map.split(state, [:client_pids, :sender_pids])
    {:noreply, state}
  end

  def handle_info({:client_joined, :client, pid}, state) do
    state = %{state | client_pids: [pid | state.client_pids]}
    {:noreply, state}
  end

  def handle_info({:client_joined, :sender, pid}, state) do
    state = %{state | sender_pids: [pid | state.sender_pids]}
    {:noreply, state}
  end

  def handle_info({:result, id, time}, state) do
    state = update_in(state.results, &Map.update(&1, id, [time], fn acc -> [time | acc] end))
    {:noreply, state}
  end

  def handle_info({:DOWN, _, _, _, _}, state) do
    state = %{state | disconnected_count: state.disconnected_count + 1}
    if state.disconnected_count >= (length(state.pairs) * 2) do
      ChannelBenchmarker.Results.output(state.results,
        %{channel_count: length(state.pairs)})
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
