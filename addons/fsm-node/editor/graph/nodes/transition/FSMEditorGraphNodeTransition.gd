tool
extends GraphNode
class_name FSMEditorGraphNodeTransition


signal delete_request(node)
signal name_changed(node)


onready var label = $Label
var node_name: String


func _ready() -> void:
	if self.node_name:
		self.label.text = self.node_name


func _on_close_request() -> void:
	self.emit_signal("delete_request", self)


func _on_Label_text_changed(new_text: String) -> void:
	self.emit_signal("name_changed", self)
