tool
extends WindowDialog
class_name FSMEditor


const FSMStateScript = preload("res://addons/fsm-node/nodes/state.gd")
const FSMTransitionScript = preload("res://addons/fsm-node/nodes/transition.gd")


onready var graph: FSMEditorGraph = $Panel/Graph
onready var new_state_dialog := $Panel/NewStateDialog
onready var new_transition_dialog := $Panel/NewTransitionDialog
onready var invalid_connection_dialog := $Panel/InvalidConnection
var fsm_node: FSM


func _ready() -> void:
	if ! Engine.is_editor_hint():
		show()


func _on_Graph_invalid_connection(from, from_slot, to, to_slot) -> void:
	self.invalid_connection_dialog.popup_centered()


func _on_AddStateButton_pressed() -> void:
	self.new_state_dialog.popup_centered()


func _on_AddTransitionButton_pressed() -> void:
	self.new_transition_dialog.popup_centered()


func _on_NewTransitionDialog_create_transition(transition_name) -> void:
	self.create_transition(transition_name)
	self.graph.sync_transition(transition_name, '')


func _on_AcceptDialog_create_state(state_name) -> void:
	self.create_state(state_name)
	self.graph.sync_state(state_name, [])


func _on_Graph_delete_node(name: String) -> void:
	self.delete_node(name)


func _on_about_to_show() -> void:
	for child in self.fsm_node.get_children():
		if child is State:
			var transitions := []
			for transition in child.transitions:
				var _transition = child.get_node(transition)
				if _transition != null:
					transitions.append(_transition.name)
			self.graph.sync_state(child.name, transitions)
		elif child is Transition:
			if child.target_state == '':
				continue
			var target = child.get_node(child.target_state)
			if target != null:
				self.graph.sync_transition(child.name, target.name)


func _on_Graph_edit_state(current_name, new_name, transitions) -> void:
	self.update_state(current_name, new_name, transitions)


func _on_Graph_edit_transition(current_name, new_name, target_state) -> void:
	self.update_transition(current_name, new_name, target_state)


func _get_node_by_name(name: String) -> Node:
	for child in self.fsm_node.get_children():
		if child.name == name:
			return child
	return null


func reset() -> void:
	self.fsm_node = null
	self.graph.reset()


func create_state(name: String) -> void:
	var node = State.new()
	node.name = name
	self.fsm_node.add_child(node, true)
	node.set_owner(get_tree().get_edited_scene_root())


func create_transition(name: String) -> void:
	var node = Transition.new()
	node.name = name
	self.fsm_node.add_child(node, true)
	node.set_owner(get_tree().get_edited_scene_root())


func delete_node(name: String) -> void:
	var node = self._get_node_by_name(name)
	if node != null:
		for child in self.fsm_node.get_children():
			if child is State:
				var index := 0
				var transitions := []
				for transition in child.transitions:
					var _transition = child.get_node(transition)
					if _transition != null and node.name != _transition.name:
						transitions.append(transition)
				child.transitions = transitions
			elif child is Transition:
				var target := self.fsm_node.get_node(child.target_state)
				if target != null and node.name == target.name:
					child.target_state = null
		self.fsm_node.remove_child(node)
		node.queue_free()


func update_state(current_name: String, new_name: String, transitions: Array) -> void:
	var state := self._get_node_by_name(current_name)
	var _transitions := []
	for transition in transitions:
		var _transition := self._get_node_by_name(transition)
		if _transition != null:
			var relative_path_to_transition := state.get_path_to(_transition)
			if _transitions.find(relative_path_to_transition) == -1:
				_transitions.append(relative_path_to_transition)
	state.transitions = _transitions
	state.name = new_name


func update_transition(current_name: String, new_name: String, target_state_name: String) -> void:
	var transition := self._get_node_by_name(current_name)
	transition.target_state = self._get_node_by_name(target_state_name).get_path()
	transition.name = new_name
