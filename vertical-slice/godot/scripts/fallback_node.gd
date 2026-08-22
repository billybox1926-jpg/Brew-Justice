extends Node
class_name FallbackNode

## Delegating fallback for missing sensory-system nodes (issue #59).
## When a scene node is missing at runtime (shipped build, partial
## export, mod conflict), FocusModeMain installs one of these under the
## missing node's expected name instead of crashing on @onready lookups.
## It exposes no-op implementations of the signals/methods the rest of
## the slice expects, so callers degrade gracefully — and it logs once,
## loudly, so the gap is visible rather than masked.

signal deduction_progress(progress: float, insight_text: String)
signal contradiction_detected(clue_a: String, clue_b: String)
signal clarity_changed(clue_id: String, clarity: float)
signal chaos_pulse(strength: float)
signal rhythm_pulse(intensity: float)
signal stim_released(strength: float)

var expected_type: String = ""
var missing_path: String = ""


## Create a fallback standing in for the node that should have been at
## `path`, expected to be of Godot class `type_name`.
static func for_missing(path: String, type_name: String) -> FallbackNode:
	var f := FallbackNode.new()
	f.name = String(path).get_file()
	f.expected_type = type_name
	f.missing_path = path
	push_error(
		(
			"[Resilience] Node missing at '%s' (expected %s) — degraded no-op fallback installed."
			% [path, type_name]
		)
	)
	return f


# --- No-op surface: everything the slice calls on these nodes. ---


func apply_presence(_value: float) -> void:
	pass


func register_clue(_clue_data: Resource, _resolver: Node) -> void:
	pass


func resolve_clue(_clue_id: String) -> void:
	pass


func update_targets(_mode: String, _stim: bool, _tune: bool, _focus: bool) -> void:
	pass


func apply_chaos_band(_band: String, _intensity: float) -> void:
	pass


func set_world_calm(_calm: float) -> void:
	pass


func press() -> void:
	pass


func release() -> void:
	pass


func update(_delta: float) -> void:
	pass


func disrupt(_amount: float) -> void:
	pass


func current_charge() -> float:
	return 0.0


func add_load(_amount: float) -> void:
	pass


func reduce_load(_amount: float) -> void:
	pass


func reset() -> void:
	pass


func toggle() -> void:
	pass
