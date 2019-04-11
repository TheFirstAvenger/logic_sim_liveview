defmodule LogicSimLiveview.ProcessCount do
  use GenServer
  require Logger

  def register_liveview(pid) do
    GenServer.call(__MODULE__, {:register_liveview, pid})
  end

  def register_node(pid) do
    GenServer.call(__MODULE__, {:register_node, pid})
  end

  def start_link(:ok) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    Process.send_after(self(), :timer, 5_000)
    {:ok, %{liveviews: [], liveview_count: 0, nodes: [], node_count: 0}}
  end

  def handle_call(
        {:register_liveview, pid},
        _from,
        %{liveviews: liveviews, liveview_count: liveview_count} = state
      ) do
    state = %{state | liveviews: [pid | liveviews], liveview_count: liveview_count + 1}
    {:reply, {state.liveview_count, state.node_count}, state}
  end

  def handle_call({:register_node, pid}, _from, %{nodes: nodes, node_count: node_count} = state) do
    state = %{state | nodes: [pid | nodes], node_count: node_count + 1}
    {:reply, {state.liveview_count, state.node_count}, state}
  end

  def handle_info(:timer, %{liveviews: liveviews, nodes: nodes} = state) do
    liveviews = cleanup(liveviews, [])
    nodes = cleanup(nodes, [])
    state = %{state | liveviews: liveviews, liveview_count: length(liveviews)}
    state = %{state | nodes: nodes, node_count: length(nodes)}

    liveviews
    |> Enum.map(&send(&1, {:counts, state.liveview_count, state.node_count}))

    Logger.debug(fn ->
      "Counts: liveviews: #{state.liveview_count}, nodes: #{state.node_count}"
    end)

    Process.send_after(self(), :timer, 5_000)
    {:noreply, state}
  end

  def cleanup([], acc), do: acc

  def cleanup([h | t], acc) do
    if Process.alive?(h), do: cleanup(t, [h | acc]), else: cleanup(t, acc)
  end
end
