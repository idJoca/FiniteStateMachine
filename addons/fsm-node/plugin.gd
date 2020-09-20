tool
extends EditorPlugin

const FSMEditorScene = preload("res://addons/fsm-node/editor/FSMEditor.tscn")
const FSMScript = preload("res://addons/fsm-node/nodes/fsm.gd")

var editor_instance: FSMEditor


func _enter_tree():
	"""
	Handles the initialization, by:
		- instantiating our FSM Editor
		- listening for node selection on the Scene tree
	"""
	editor_instance = FSMEditorScene.instance()
	# editor_instance.connect("popup_hide", self, "_on_FSMEditor_hide")
	get_editor_interface().get_editor_viewport().add_child(editor_instance)
	get_editor_interface().get_selection().connect(
		"selection_changed", self, "_on_editor_tree_selection_changed"
	)


func _exit_tree():
	"""
	Handles the termination, by freeing all used memory
	"""
	if editor_instance != null:
		editor_instance.queue_free()
	queue_free()


func get_name():
	return "FSM"


func has_main_screen():
	return true


func _on_resized() -> void:
	var viewport_size = get_editor_interface().get_editor_viewport().get_size()
	editor_instance.set_size(viewport_size)
	editor_instance.set_global_position(
		get_editor_interface().get_editor_viewport().get_global_position()
	)

func _on_editor_tree_selection_changed() -> void:
	"""
	Check to see if the selected node (Multi selections are ignored)
	has the 'fsm.gd' script. If that is the case, we'll show the FSM Editor.
	"""
	var selection = get_editor_interface().get_selection().get_selected_nodes()

	if selection.size() != 1:
		# We only care for single selections
		return

	if selection[0].get_script() == FSMScript:
		editor_instance.fsm_node = selection[0]
		editor_instance.popup_centered()


func _on_FSMEditor_hide() -> void:
	editor_instance.reset()
