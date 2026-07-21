extends Node
class_name ClueGraph

signal clue_registered(clue_id: String)
signal clue_unlocked(from_clue: String, unlocked_ids: Array[String])
signal graph_progressed(progress: float, insights: Array[String])

## Clue data model suitable for designer-authored `ClueData` instances.
class Clue:
	var id: String
	var data: ClueData
	var clarity: float = 0.0
	var unlocked: bool = false
	var registered: bool = false

	func _init(p_id: String, p_data: ClueData) -> void:
		id = p_id
		data = p_data

var clues: Dictionary = {}

var total_registered: int = 0
var total_unlocked: int = 0
var avg_clarity: float = 0.0
var last_progress: float = 0.0
var _insights: Array[String] = []

func register_clue(clue_data: ClueData) -> bool:
	if not clue_data or not clue_data.clue_id:
		return false
	var id := clue_data.clue_id
	if clues.has(id):
		var c := clues[id] as Clue
		c.data = clue_data
		c.registered = true
		return true
	var c_new := Clue.new(id, clue_data)
	clues[id] = c_new
	total_registered += 1
	clue_registered.emit(id)
	return true


func get_clue(id: String) -> Clue:
	return clues.get(id, null)


func get_data(id: String) -> ClueData:
	var c := clues.get(id, null) as Clue
	return c.data if c else null


func set_clarity(id: String, clarity: float) -> void:
	var c := clues.get(id, null) as Clue
	if not c:
		return
	c.clarity = clampf(clarity, 0.0, 1.0)
	_recalculate()


func get_clarity(id: String) -> float:
	var c := clues.get(id, null) as Clue
	return c.clarity if c else 0.0


func resolve_clue(id: String) -> bool:
	var c := clues.get(id, null) as Clue
	if not c or not c.data:
		return false
	if c.unlocked:
		return false
	c.unlocked = true
	total_unlocked += 1
	var unlocked_ids: Array[String] = []
	for lead_id in c.data.leads_to:
		unlocked_ids.append(lead_id)
	if not unlocked_ids.is_empty():
		clue_unlocked.emit(id, unlocked_ids)
	_recalculate()
	return true


func is_locked(id: String) -> bool:
	var c := clues.get(id, null) as Clue
	return not (c and (c.unlocked or c.data.is_empty() or c.data.leads_to.is_empty()))


func _recalculate() -> void:
	var sum := 0.0
	var count := 0
	_insights.clear()
	for id in clues:
		var c := clues[id] as Clue
		sum += c.clarity
		count += 1
		if c.data and c.data.combines_with:
			for partner_id in c.data.combines_with:
				var partner := clues.get(partner_id, null) as Clue
				if partner and partner.clarity > COMBINATION_THRESHOLD and c.clarity > COMBINATION_THRESHOLD:
					_insights.append("Combined: %s + %s" % [c.data.clue_name, partner.data.clue_name if partner.data else partner_id])
		if c.data and c.data.contradicts:
			for contra_id in c.data.contradicts:
				var contra := clues.get(contra_id, null) as Clue
				if contra and contra.clarity > CONTRADICTION_THRESHOLD and c.clarity > CONTRADICTION_THRESHOLD:
					_insights.append("Contradiction: %s vs %s" % [c.data.clue_name, contra.data.clue_name if contra.data else contra_id])
	avg_clarity = (sum / float(count)) if count > 0 else 0.0
	var progress := clamp(avg_clarity * 0.6 + (float(total_unlocked) / float(max(total_registered, 1))) * 0.4, 0.0, 1.0)
	last_progress = progress
	graph_progressed.emit(progress, _insights.duplicate())


func reset() -> void:
	for id in clues:
		var c := clues[id] as Clue
		c.clarity = 0.0
		c.unlocked = false
	total_unlocked = 0
	avg_clarity = 0.0
	last_progress = 0.0
	_insights.clear()
