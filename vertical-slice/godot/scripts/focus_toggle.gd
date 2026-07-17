extends Node
class_name FocusToggle

signal focus_changed(is_focused: bool)

var active := false


func toggle() -> void:
	active = not active
	focus_changed.emit(active)
