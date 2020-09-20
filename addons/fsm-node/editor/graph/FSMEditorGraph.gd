tool
extends GraphEdit
class_name FSMEditorGraph


signal invalid_connection(from, from_slot, to, to_slot)
signal delete_node(name)
signal edit_state(current_name, new_name, transitions)
signal edit_transition(current_name, new_name, target_state)


const FSMEditorGraphNodeStateScene = preload("res://addons/fsm-node/editor/graph/nodes/state/FSMEditorGraphNodeState.tscn")
const FSMEditorGraphNodeTransitionScene = preload("res://addons/fsm-node/editor/graph/nodes/transition/FSMEditorGraphNodeTransition.tscn")
const UUID = preload("res://addons/uuid/UUID.gd")


var connections := {}
var selection := []


func _on_delete_nodes_request() -> void:
	for node in self.get_children():
		if node is FSMEditorGraphNodeState or node is FSMEditorGraphNodeTransition:
			if node.selected:
				self._on_remove_nodes_request(node)


func _on_connection_request(from: String, from_slot: int, to: String, to_slot: int) -> void:
	if not (from.begins_with('State') and to.begins_with('State')):
		# States can't be connected directly
		# Instead, they should be connet by Transitions
		self._save_connection(from, from_slot, to, to_slot)
		connect_node(from, from_slot, to, to_slot)
		self._child_changed(self._get_node_by_name(from))
	else:
		emit_signal("invalid_connection", from, from_slot, to, to_slot)


func _on_disconnection_request(from: String, from_slot: int, to: String, to_slot: int) -> void:
	var from_connections := []
	for connection in self.connections.get(from):
		if connection.get("to") != to:
			from_connections.append(connection)
	self.connections[from] = from_connections

	var to_connections := []
	for connection in self.connections.get(to):
		if connection.get("from") != from:
			from_connections.append(connection)
	self.connections[to] = to_connections
	disconnect_node(from, from_slot, to, to_slot)
	self._child_changed(self._get_node_by_name(from))


func _on_remove_nodes_request(node: GraphNode) -> void:
	var node_connections = self.connections.get(node.name)
	if node_connections != null and node_connections.size() > 0:
		for node_connection in node_connections:
			disconnect_node(
				node_connection.from,
				node_connection.from_slot,
				node_connection.to,
				node_connection.to_slot
			)
	self.connections.erase(node.name)
	self.emit_signal("delete_node", node.node_name)
	node.disconnect("delete_request", self, "_on_remove_nodes_request")
	node.disconnect("name_changed", self, "_child_changed")
	node.queue_free()


func _add_child_state(state_name = '') -> GraphNode:
	var state = FSMEditorGraphNodeStateScene.instance()
	state.node_name = state_name
	state.name = 'State_%s' % [UUID.generate()]
	state.connect("delete_request", self, "_on_remove_nodes_request")
	state.connect("name_changed", self, "_child_changed")
	self.add_child(state)
	return state


func _add_child_transition(transition_name = '') -> GraphNode:
	var transition = FSMEditorGraphNodeTransitionScene.instance()
	transition.node_name = transition_name
	transition.name = 'Transition_%s' % [UUID.generate()]
	transition.connect("delete_request", self, "_on_remove_nodes_request")
	transition.connect("name_changed", self, "_child_changed")
	self.add_child(transition)
	return transition


func _child_changed(node: GraphNode) -> void:
	if node is FSMEditorGraphNodeState:
		var transitions := []
		for connection in connections.get(node.name):
			if connection.get('from') == node.name:
				var transition := self._get_node_by_name(connection.get('to'))
				transitions.append(transition.node_name)
		self.emit_signal("edit_state", node.node_name, node.label.text, transitions)
		node.node_name = node.label.text
	elif node is FSMEditorGraphNodeTransition:
		var target_state_name := ''
		for connection in connections.get(node.name):
			if connection.get('from') == node.name:
				var state := self._get_node_by_name(connection.get('to'))
				target_state_name = state.node_name
				break
		self.emit_signal("edit_transition", node.node_name, node.label.text, target_state_name)
		node.node_name = node.label.text


func _save_connection(_from, _from_slot, _to, _to_slot) -> void:
	var connection = {
		'from': _from,
		'from_slot': _from_slot,
		'to': _to,
		'to_slot': _to_slot
	}
	if not self.connections.has(_from):
		self.connections[_from] = []
	self.connections[_from].append(connection)
	if not self.connections.has(_to):
		self.connections[_to] = []
	self.connections[_to].append(connection)


func _get_graph_node_by_node_name(name: String) -> Node:
	for child in self.get_children():
		if child is FSMEditorGraphNodeState or child is FSMEditorGraphNodeTransition:
			if child.node_name == name:
				return child
	return null


func _get_node_by_name(name: String) -> Node:
	for child in self.get_children():
		if child is FSMEditorGraphNodeState or child is FSMEditorGraphNodeTransition:
			if child.name == name:
				return child
	return null


func sync_state(name: String, transitions: Array) -> void:
	var state := self._get_graph_node_by_node_name(name) as FSMEditorGraphNodeState
	if state == null:
		self._add_child_state(name)
		state = self._get_graph_node_by_node_name(name) as FSMEditorGraphNodeState
	for transition in transitions:
		var _transition := self._get_graph_node_by_node_name(transition) as FSMEditorGraphNodeTransition
		if _transition == null:
			self._add_child_transition(transition)
			_transition = self._get_graph_node_by_node_name(transition) as FSMEditorGraphNodeTransition
		self._on_connection_request(state.name, 0, _transition.name, 0)


func sync_transition(name: String, target_state_name: String) -> void:
	var transition := self._get_graph_node_by_node_name(name) as FSMEditorGraphNodeTransition
	if transition == null:
		self._add_child_transition(name)
		transition = self._get_graph_node_by_node_name(name) as FSMEditorGraphNodeTransition
	if target_state_name == '':
		return
	var target := self._get_graph_node_by_node_name(target_state_name) as FSMEditorGraphNodeState
	if target == null:
		self._add_child_state(target_state_name)
		target = self._get_graph_node_by_node_name(target_state_name) as FSMEditorGraphNodeState
	self._on_connection_request(transition.name, 0, target.name, 0)


func reset() -> void:
	for child in self.get_children():
		if child is FSMEditorGraphNodeState or child is FSMEditorGraphNodeTransition:
			self.remove_child(child)
	connections = {}
	selection = []
