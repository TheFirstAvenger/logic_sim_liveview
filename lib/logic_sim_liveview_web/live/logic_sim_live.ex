defmodule LogicSimLiveviewWeb.LogicSimLive do
  use Phoenix.LiveView
  use Phoenix.HTML

  alias LogicSim.Node
  alias LogicSim.Node.And
  alias LogicSim.Node.Lightbulb
  alias LogicSim.Node.OnOffSwitch
  alias LogicSim.Node.Or
  alias LogicSimLiveview.ProcessCount
  require Logger

  @width 700
  @height 700

  @node_width 50
  @input_output_width 8
  @image_ratios %{}
                |> Map.put(OnOffSwitch, 1.42)
                |> Map.put(Or, 2.0)
                |> Map.put(Lightbulb, 1.42)
                |> Map.put(And, 1.67)
  @allowed_import_type_strs [
                              OnOffSwitch,
                              Lightbulb,
                              And,
                              Or
                            ]
                            |> Enum.map(&Atom.to_string/1)

  def render(assigns) do
    ~L"""
    <div>
      <%= for button <- render_buttons(assigns) do %><%= button %><% end %>
      <div class="select-input-output-style">
        <%= if @select_input_for_output do %>Select an input to connect this output to<% end %>
        <%= if @select_output_for_input do %>Select an output to connect this input to<% end %>
      </div>

      Server Stats:<br>Liveview Sessions: <%= @liveview_count %>, Nodes: <%= @node_count %>

      <div class="main-div" style="width: <%= @width %>px; height: <%= @height %>px">
      <%= for node <- @nodes do %>
        <%= render_node(node, assigns) %>
      <% end %>
      <%= for node <- @nodes do %>
        <%= render_node_connections(node, @nodes) %>
      <% end %>
      <%= if @selection_mode != nil do %>
        <div class="selection-mode-div" phx-click="selection_mode_div_clicked" phx-send-click-coords="true"></div>
      <% end %>
      <%= if @exporting do %>
        <div class="importing-exporting-div">
          <textarea class="importing-exporting-textarea"><%= @exporting %></textarea>
          <button type="button" class="btn btn-primary btn-sm" phx-click="close_export">Close</button>
        </div>
      <% end %>
      <%= if @importing do %>
        <div class="importing-exporting-div">
          <textarea id="import-textarea" class="importing-exporting-textarea">Paste your export here</textarea>
          <button id="import-button" type="button" class="btn btn-primary btn-sm" phx-click="do_import" onclick="setImportValue(event)">Import</button>
          <button type="button" class="btn btn-primary btn-sm" phx-click="close_import">Close</button>
        </div>
      <% end %>
      </div>
      <br><br><br><br>
    </div>
    """
  end

  @spec render_buttons(any()) :: [Phoenix.LiveView.Rendered.t()]
  def render_buttons(assigns) do
    [
      ~E"""
      Add Node:
      """,
      render_button("add_on_off_switch", "On/Off Switch"),
      render_button("add_lightbulb", "Lightbulb"),
      render_button("add_or", "Or"),
      render_button("add_and", "And"),
      render_button("add_not", "Not"),
      ~E"""
      &nbsp;&nbsp;&nbsp;
      """,
      if !assigns.selection_mode && !assigns.select_for_move do
        render_button("set_select_for_move_true", "Move Node")
      end,
      if assigns.select_for_move do
        render_button("set_select_for_move_false", "Cancel Move Node")
      end,
      if assigns.selection_mode != nil do
        render_button("set_selection_mode_nil", "Cancel")
      end,
      if assigns.select_input_for_output != nil do
        render_button("cancel_select_input_for_output", "Cancel")
      end,
      if assigns.select_output_for_input != nil do
        render_button("cancel_select_output_for_input", "Cancel")
      end,
      if !assigns.importing && !assigns.exporting do
        [render_button("export", "Export"), render_button("import", "Import")]
      end
    ]
    |> Enum.filter(&(&1 != nil))
  end

  def render_button(phx_click, text) do
    ~E"""
    <button type="button" class="btn btn-primary btn-sm" phx-click="<%= phx_click %>"><%= text %></button>
    """
  end

  def render_node(%{uuid: uuid, type: type, top: top, left: left} = node, assigns) do
    inner_height = trunc(@node_width * @image_ratios[type])
    outer_height = inner_height + @input_output_width * 2

    ~E"""
    <div class="node-div" style="top: <%= top %>px; left: <%= left %>px; height: <%= outer_height %>px; width: <%= @node_width %>px">
      <%= draw_node_inputs(node, assigns) %>
      <div id="node-<%= uuid %>" style="height: <%= inner_height %>px" phx-click="node_click_<%= uuid %>"><%= do_render_node(node, assigns) %></div>
      <%= draw_node_outputs(node, assigns) %>
    </div>
    """
  end

  def do_render_node(%{type: OnOffSwitch, node_state: %{on: on}}, assigns) do
    ~E"""
    <img src="/images/nodes/switch-<%= if on, do: "on", else: "off" %>.png" style="width: <%= @node_width %>px; height: <%= trunc(@node_width * @image_ratios[OnOffSwitch]) %>px">
    """
  end

  def do_render_node(%{type: Lightbulb, node_state: %{input_values: %{a: on}}} = _node, assigns) do
    ~E"""
    <img src="/images/nodes/lightbulb-<%= if on, do: "on", else: "off" %>.webp" style="width: <%= @node_width %>px; height: <%= trunc(@node_width * @image_ratios[Lightbulb]) %>px">
    """
  end

  def do_render_node(%{type: Or}, assigns) do
    ~E"""
    <img src="/images/nodes/or.png" style="width: <%= @node_width %>px; height: <%= trunc(@node_width * @image_ratios[Or]) %>px">
    """
  end

  def do_render_node(%{type: And}, assigns) do
    ~E"""
    <img src="/images/nodes/and.png" style="width: <%= @node_width %>px; height: <%= trunc(@node_width * @image_ratios[And]) %>px">
    """
  end

  def render_node_connections(%{node_state: %{outputs: outputs}} = node, all_nodes) do
    outputs
    |> Enum.map(&render_output_connections(node, &1, all_nodes))
  end

  def render_output_connections(%{node_state: %{output_nodes: output_nodes}} = node, output, all_nodes) do
    output_nodes
    |> Map.get(output)
    |> Enum.map(fn {input_node_process, input_input} ->
      render_output_connection(node, output, input_node_process, input_input, all_nodes)
    end)
  end

  def render_output_connection(node, output, input_node_process, input_input, all_nodes) do
    input_node = Enum.find(all_nodes, fn %{node_process: node_process} -> input_node_process == node_process end)
    {output_x, output_y} = output_location(node, output)
    {input_x, input_y} = input_location(input_node, input_input)

    on_off =
      if node.node_state.output_values[output] do
        "on"
      else
        "off"
      end

    ~E"""
    <svg class="connection-svg"><line class="connection-line-<%= on_off %>" x1="<%= output_x %>" y1="<%= output_y %>" x2="<%= input_x %>" y2="<%= input_y %>" /></svg>
    """
  end

  def output_location(%{left: x, top: y, type: type, node_state: %{outputs: [:a]}}, :a) do
    {x + half(@node_width), y + image_height(type) + @input_output_width + half(@input_output_width)}
  end

  def input_location(%{left: x, top: y, node_state: %{inputs: [:a]}}, :a) do
    {x + half(@node_width), y + half(@input_output_width)}
  end

  def input_location(%{left: x, top: y, node_state: %{inputs: [:a, :b]}}, :a) do
    {x + half(@node_width) - @input_output_width, y + half(@input_output_width)}
  end

  def input_location(%{left: x, top: y, node_state: %{inputs: [:a, :b]}}, :b) do
    {x + half(@node_width) + @input_output_width, y + half(@input_output_width)}
  end

  def image_height(type) do
    trunc(@node_width * @image_ratios[type])
  end

  def half(x), do: trunc(x / 2)

  def draw_node_inputs(%{uuid: uuid, node_state: %{inputs: inputs, input_values: input_values}}, assigns) do
    case inputs do
      [] ->
        ~E"""
        <div class="node-inputs-outputs-div" style="height: <%= @input_output_width %>px"></div>
        """

      [input] ->
        value = Map.get(input_values, input)

        ~E"""
        <div class="node-inputs-outputs-div"><%= draw_node_input(uuid, input, value, assigns) %></div>
        """

      [input1, input2] ->
        value1 = Map.get(input_values, input1)
        value2 = Map.get(input_values, input2)

        ~E"""
        <div class="node-inputs-outputs-div">
          <%= draw_node_input(uuid, input1, value1, assigns) %>
          <div style="width: <%= @input_output_width%>px"></div>
          <%= draw_node_input(uuid, input2, value2, assigns) %>
        </div>
        """
    end
  end

  def draw_node_outputs(
        %{
          uuid: uuid,
          node_state: %{outputs: outputs, output_values: output_values}
        },
        assigns
      ) do
    case outputs do
      [] ->
        ""

      [output] ->
        value = Map.get(output_values, output)

        ~E"""
        <div class="node-inputs-outputs-div"><%= draw_node_output(uuid, output, value, assigns) %></div>
        """
    end
  end

  def draw_node_input(uuid, input, value, assigns) do
    ~E"""
    <div class="node-input-output-<%= value %>" style="width: <%= @input_output_width %>px; height: <%= @input_output_width %>px;" phx-click="node_input_clicked_<%= uuid %>_<%= Atom.to_string(input) %>"></div>
    """
  end

  def draw_node_output(uuid, output, value, assigns) do
    ~E"""
    <div class="node-input-output-<%= value %>" style="width: <%= @input_output_width %>px; height: <%= @input_output_width %>px;" phx-click="node_output_clicked_<%= uuid %>_<%= Atom.to_string(output) %>"></div>
    """
  end

  def mount(_session, socket) do
    {liveview_count, node_count} =
      if connected?(socket) do
        ProcessCount.register_liveview(self())
      else
        {0, 0}
      end

    socket =
      socket
      |> assign(:nodes, [])
      |> assign(:selection_mode, nil)
      |> assign(:select_for_move, false)
      |> assign(:selected_node, nil)
      |> assign(:select_input_for_output, nil)
      |> assign(:select_output_for_input, nil)
      |> assign(:width, @width)
      |> assign(:height, @height)
      |> assign(:node_width, @node_width)
      |> assign(:input_output_width, @input_output_width)
      |> assign(:image_ratios, @image_ratios)
      |> assign(:exporting, false)
      |> assign(:importing, false)
      |> assign(:liveview_count, liveview_count)
      |> assign(:node_count, node_count)

    {:ok, socket}
  end

  def handle_info({:counts, liveview_count, node_count}, socket) do
    {:noreply, assign(socket, liveview_count: liveview_count, node_count: node_count)}
  end

  def handle_info({:logic_sim_node_state, from, node_state}, %{assigns: %{nodes: nodes}} = socket) do
    nodes
    |> Enum.split_with(fn %{node_process: node_process} -> node_process == from end)
    |> case do
      {[], _nodes} ->
        Logger.warn("Received :logic_sim_node_state for untracked node: #{inspect(from)}")
        {:noreply, socket}

      {[node], nodes} ->
        Logger.debug("Received :logic_sim_node_state with node_state: #{inspect(node_state)}")
        node = %{node | node_state: node_state}
        nodes = [node | nodes]
        {:noreply, assign(socket, nodes: nodes)}
    end
  end

  def handle_event("node_click_" <> uuid, _, socket) do
    %{assigns: %{nodes: nodes, select_for_move: select_for_move, select_output_for_input: select_output_for_input}} =
      socket

    node = Enum.find(nodes, fn %{uuid: uuid2} -> uuid == uuid2 end)

    cond do
      select_for_move ->
        {:noreply, assign(socket, selected_node: node, selection_mode: :move_node, select_for_move: false)}

      select_output_for_input ->
        {:noreply, socket}

      true ->
        handle_node_click(node, socket)
    end
  end

  def handle_event("set_select_for_move_" <> true_or_false, _, socket) do
    {:noreply, assign(socket, select_for_move: true_or_false == "true")}
  end

  def handle_event("set_selection_mode_" <> mode, _, socket) do
    mode =
      case mode do
        "move_node" -> :move_node
        "nil" -> nil
        "add_node" -> :add_node
      end

    {:noreply, assign(socket, selection_mode: mode)}
  end

  def handle_event("add_" <> type, _, socket) do
    {:noreply, assign(socket, selection_mode: :add_node, node_type_to_add: node_type_from_string(type))}
  end

  def handle_event("selection_mode_div_clicked", params, %{assigns: %{selection_mode: selection_mode}} = socket) do
    [x, y] = String.split(params, ",")
    {x, _} = Integer.parse(x)
    {y, _} = Integer.parse(y)
    handle_selection_mode_div_clicked(selection_mode, x, y, socket)
  end

  # Ignore input click when waiting for output click
  def handle_event("node_input_clicked_" <> _, _, %{assigns: %{select_output_for_input: x}} = socket)
      when x != nil do
    {:noreply, socket}
  end

  def handle_event(
        "node_input_clicked_" <> uuid_and_input,
        _,
        %{assigns: %{nodes: nodes, select_input_for_output: {output_uuid, output_output}}} = socket
      ) do
    [input_uuid, input_input] = String.split(uuid_and_input, "_")
    %{node_process: input_node_process} = get_node_by_uuid(nodes, input_uuid)
    %{node_process: output_node_process} = get_node_by_uuid(nodes, output_uuid)

    Node.link_output_to_node(
      output_node_process,
      String.to_existing_atom(output_output),
      input_node_process,
      String.to_existing_atom(input_input)
    )

    {:noreply, assign(socket, select_input_for_output: nil)}
  end

  def handle_event(
        "node_output_clicked_" <> uuid_and_output,
        _,
        %{assigns: %{nodes: nodes, select_output_for_input: {input_uuid, input_input}}} = socket
      ) do
    [output_uuid, output_output] = String.split(uuid_and_output, "_")
    %{node_process: input_node_process} = get_node_by_uuid(nodes, input_uuid)
    %{node_process: output_node_process} = get_node_by_uuid(nodes, output_uuid)

    Node.link_output_to_node(
      output_node_process,
      String.to_existing_atom(output_output),
      input_node_process,
      String.to_existing_atom(input_input)
    )

    {:noreply, assign(socket, select_output_for_input: nil)}
  end

  def handle_event("node_input_clicked_" <> uuid_and_input, _, socket) do
    [uuid, input] = String.split(uuid_and_input, "_")
    {:noreply, assign(socket, select_output_for_input: {uuid, input})}
  end

  # Ignore output click when waiting for input click
  def handle_event("node_output_clicked_" <> _, _, %{assigns: %{select_input_for_output: x}} = socket)
      when x != nil do
    {:noreply, socket}
  end

  def handle_event("node_output_clicked_" <> uuid_and_output, _, socket) do
    [uuid, output] = String.split(uuid_and_output, "_")
    {:noreply, assign(socket, select_input_for_output: {uuid, output})}
  end

  def handle_event("cancel_select_output_for_input", _, socket),
    do: {:noreply, assign(socket, select_output_for_input: nil)}

  def handle_event("cancel_select_input_for_output", _, socket),
    do: {:noreply, assign(socket, select_input_for_output: nil)}

  def handle_event("export", _, %{assigns: %{nodes: nodes}} = socket) do
    node_map =
      nodes
      |> Enum.map(&node_to_node_export_map_entry/1)
      |> Enum.into(%{})

    node_list_json =
      node_map
      |> Enum.map(&transform_output_nodes_for_export(&1, node_map))
      |> Enum.map(&transform_node_for_output/1)
      |> Jason.encode!()

    {:noreply, assign(socket, :exporting, node_list_json)}
  end

  def handle_event("close_export", _, socket) do
    {:noreply, assign(socket, :exporting, false)}
  end

  def handle_event("import", _, socket) do
    {:noreply, assign(socket, :importing, true)}
  end

  def handle_event("close_import", _, socket) do
    {:noreply, assign(socket, :importing, false)}
  end

  def handle_event("do_import", to_import, %{assigns: %{nodes: nodes}} = socket) do
    new_nodes_with_outputs =
      to_import
      |> Jason.decode!()
      |> Enum.map(&create_imported_node/1)

    new_nodes =
      new_nodes_with_outputs
      |> Enum.map(&elem(&1, 0))

    new_nodes_with_outputs
    |> Enum.each(&link_output_nodes(&1, new_nodes))

    {:noreply, assign(socket, nodes: new_nodes ++ nodes, importing: false)}
  end

  def link_output_nodes({%{uuid: output_uuid}, output_nodes}, nodes) do
    output_nodes
    |> Enum.map(fn {output, inputs} when is_binary(output) ->
      inputs
      |> Enum.map(fn {input_uuid, input_str} when is_binary(input_uuid) and is_binary(input_str) ->
        %{node_process: input_node_process} = get_node_by_uuid(nodes, input_uuid)
        %{node_process: output_node_process} = get_node_by_uuid(nodes, output_uuid)

        Node.link_output_to_node(
          output_node_process,
          String.to_existing_atom(output),
          input_node_process,
          String.to_existing_atom(input_str)
        )
      end)
    end)
  end

  def create_imported_node(%{
        "id" => uuid,
        "left" => left,
        "output_nodes" => %{} = output_nodes,
        "top" => top,
        "type" => type_str
      })
      when is_binary(uuid) and is_integer(left) and is_integer(top) and type_str in @allowed_import_type_strs do
    type = String.to_existing_atom(type_str)
    node = create_node(type, left, top, uuid)
    {node, output_nodes}
  end

  def node_to_node_export_map_entry(%{
        uuid: uuid,
        node_process: node_process,
        node_state: %{output_nodes: output_nodes},
        type: type,
        top: top,
        left: left
      }) do
    {node_process, %{type: type, uuid: uuid, output_nodes: output_nodes, top: top, left: left}}
  end

  def transform_output_nodes_for_export({pid, %{output_nodes: output_nodes} = node}, node_map) do
    output_nodes =
      output_nodes
      |> Enum.map(fn {output, connections} ->
        connections =
          connections
          |> Enum.map(fn {pid, input} ->
            {node_map[pid].uuid, input}
          end)
          |> Enum.into(%{})

        {output, connections}
      end)
      |> Enum.into(%{})

    {pid, %{node | output_nodes: output_nodes}}
  end

  def transform_node_for_output({_, %{top: top, left: left, uuid: uuid, type: type, output_nodes: output_nodes}}) do
    %{id: uuid, type: type, output_nodes: output_nodes, top: top, left: left}
  end

  def node_type_from_string("on_off_switch"), do: OnOffSwitch
  def node_type_from_string("lightbulb"), do: Lightbulb
  def node_type_from_string("or"), do: Or
  def node_type_from_string("and"), do: And

  def handle_selection_mode_div_clicked(:move_node, x, y, socket) do
    %{assigns: %{nodes: nodes, selected_node: %{uuid: uuid, type: type}}} = socket
    {[node], nodes} = Enum.split_with(nodes, fn %{uuid: uuid2} -> uuid == uuid2 end)
    node = %{node | left: x - half(@node_width), top: y - half(@node_width * @image_ratios[type] + @input_output_width)}
    {:noreply, assign(socket, nodes: [node | nodes], selected_node: nil, selection_mode: nil)}
  end

  def handle_selection_mode_div_clicked(:add_node, x, y, socket) do
    %{assigns: %{nodes: nodes, node_type_to_add: node_type_to_add}} = socket

    node =
      create_node(
        node_type_to_add,
        x - half(@node_width),
        y - half(@node_width * @image_ratios[node_type_to_add] + @input_output_width)
      )

    {:noreply, assign(socket, nodes: [node | nodes], selection_mode: nil)}
  end

  def create_node(type, x, y, uuid \\ nil) do
    node_process = type.start_link!(listeners: [self()])
    ProcessCount.register_node(node_process)
    node_state = Node.get_state(node_process)

    %{
      uuid: uuid || UUID.uuid4(),
      type: type,
      node_process: node_process,
      node_state: node_state,
      top: y,
      left: x
    }
  end

  def handle_node_click(%{type: OnOffSwitch, node_process: node_process}, socket) do
    OnOffSwitch.toggle(node_process)
    {:noreply, socket}
  end

  def handle_node_click(%{type: type}, socket) do
    Logger.warn("Unhandled click for type #{type}")
    {:noreply, socket}
  end

  def get_node_by_uuid(nodes, uuid), do: Enum.find(nodes, fn %{uuid: uuid2} -> uuid2 == uuid end)
end
