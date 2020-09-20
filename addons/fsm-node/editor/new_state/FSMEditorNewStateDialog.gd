tool
extends ConfirmationDialog

signal create_state(state_name)

onready var state_name_edit = $VBoxContainer/HBoxContainer/LineEdit


func _ready() -> void:
	self.get_ok().rect_min_size = Vector2(60, 20)
	self.get_cancel().rect_min_size = Vector2(60, 20)


func _on_confirmed() -> void:
	emit_signal("create_state", state_name_edit.text)
