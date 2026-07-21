extends Node
class_name InvestigationBeat

signal beat_resolved(insight_text: String)

@export var required_progress: float = 0.75
@export var fallback_insight: String = "A new connection emerges from what you noticed."
var _resolved: bool = false


func start(focus_node: FocusModeMain) -> void:
	if not focus_node:
		return
	if focus_node.has_signal("deduction_updated"):
		focus_node.deduction_updated.connect(_on_deduction)


func _on_deduction(progress: float, insight_text: String) -> void:
	if not _resolved and progress >= required_progress:
		_resolved = true
		var text := insight_text
		if text == null or text == "":
			text = fallback_insight
		beat_resolved.emit(text)
