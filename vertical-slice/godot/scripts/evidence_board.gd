extends Node
class_name EvidenceBoard

signal deduction_progress(progress: float, insight_text: String)
signal contradiction_detected(clue_a: String, clue_b: String)
signal graph_progression_requested(clue_id: String)

var _clue_states: Dictionary = {}
var _graph: Dictionary = {}
const COMBINATION_THRESHOLD := 0.8
const CONTRADICTION_THRESHOLD := 0.5


func register_clue(clue_data: ClueData, resolver: ClueResolver) -> void:
	if not clue_data or not resolver:
		return
	_graph[clue_data.clue_id] = clue_data
	_clue_states[clue_data.clue_id] = 0.0
	if not resolver.is_connected("clarity_changed", _on_clue_clarity_changed):
		resolver.clarity_changed.connect(_on_clue_clarity_changed)


func _on_clue_clarity_changed(clue_id: String, clarity: float) -> void:
	_clue_states[clue_id] = clarity
	_evaluate_graph()


func _evaluate_graph() -> void:
	var total_progress := 0.0
	var insights: Array[String] = []

	for id_a in _graph:
		var data_a: ClueData = _graph[id_a]
		var clarity_a := _clue_states.get(id_a, 0.0)
		total_progress += clarity_a

		for id_b in data_a.combines_with:
			var clarity_b := _clue_states.get(id_b, 0.0)
			if clarity_a > COMBINATION_THRESHOLD and clarity_b > COMBINATION_THRESHOLD:
				var name_b := _graph[id_b].clue_name if _graph.has(id_b) else id_b
				insights.append("Combined: %s + %s" % [data_a.clue_name, name_b])
				total_progress += 1.0

		for id_contra in data_a.contradicts:
			var clarity_contra := _clue_states.get(id_contra, 0.0)
			if clarity_a > _contradiction_threshold and clarity_contra > _contradiction_threshold:
				contradiction_detected.emit(id_a, id_contra)

	var avg_clarity := 0.0
	for clarity in _clue_states.values():
		avg_clarity += clarity
	if _clue_states.size() > 0:
		avg_clarity /= float(_clue_states.size())
	total_progress += avg_clarity

	var divisor := float(_graph.size() + insights.size())
	var progress := clamp(total_progress / (divisor if divisor > 0.0 else 1.0), 0.0, 1.0)
	deduction_progress.emit(progress, "\n".join(insights))


func resolve_clue(clue_id: String) -> void:
	graph_progression_requested.emit(clue_id)
