extends Node

## Session-state persistence (issue #57): investigation progress, unlocked
## clues, and story-beat completion. Mirrors the PreferencesManager pattern
## but for game state, stored JSON-backed under user://.
##
## Additive-only contract: unknown keys in the file are preserved on save,
## missing keys fall back to defaults on load. One file, one owner — nothing
## else writes SAVE_PATH.

signal state_loaded
signal state_saved

const SAVE_PATH := "user://brew_justice_save.json"
const SCHEMA_VERSION := 1

var deduction_progress: float = 0.0
## clue_id -> last known clarity (0..1); presence = unlocked/clues seen.
var clue_clarity: Dictionary = {}
## Beat names that have completed at least once.
var completed_beats: Array[String] = []
var investigation_resolved: bool = false


func save_state() -> bool:
	# Read any existing file first so foreign/future keys survive the write.
	var existing := {}
	if FileAccess.file_exists(SAVE_PATH):
		var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
		if f:
			var parsed: Variant = JSON.parse_string(f.get_as_text())
			if parsed is Dictionary:
				existing = parsed
	existing["schema_version"] = SCHEMA_VERSION
	existing["deduction_progress"] = deduction_progress
	existing["investigation_resolved"] = investigation_resolved
	existing["clue_clarity"] = clue_clarity.duplicate()
	var beats := []
	for b in completed_beats:
		beats.append(b)
	existing["completed_beats"] = beats
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		push_warning("GameStateManager: cannot write %s" % SAVE_PATH)
		return false
	f.store_string(JSON.stringify(existing, "\t"))
	state_saved.emit()
	return true


func load_state() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return false
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if not (parsed is Dictionary):
		push_warning("GameStateManager: corrupt save at %s" % SAVE_PATH)
		return false
	deduction_progress = float(parsed.get("deduction_progress", 0.0))
	investigation_resolved = bool(parsed.get("investigation_resolved", false))
	var raw_clues: Variant = parsed.get("clue_clarity", {})
	clue_clarity.clear()
	if raw_clues is Dictionary:
		for key: String in raw_clues:
			clue_clarity[key] = clampf(float(raw_clues[key]), 0.0, 1.0)
	completed_beats.clear()
	var raw_beats: Variant = parsed.get("completed_beats", [])
	if raw_beats is Array:
		for b: Variant in raw_beats:
			completed_beats.append(str(b))
	state_loaded.emit()
	return true


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func wipe() -> void:
	deduction_progress = 0.0
	investigation_resolved = false
	clue_clarity.clear()
	completed_beats.clear()
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))


func record_clue_clarity(clue_id: String, clarity: float) -> void:
	if clue_id.is_empty():
		return
	clue_clarity[clue_id] = clampf(clarity, 0.0, 1.0)


func is_clue_unlocked(clue_id: String) -> bool:
	return clue_clarity.get(clue_id, 0.0) > 0.0


func mark_beat_completed(beat_name: String) -> void:
	if beat_name.is_empty():
		return
	if not completed_beats.has(beat_name):
		completed_beats.append(beat_name)


func is_beat_completed(beat_name: String) -> bool:
	return completed_beats.has(beat_name)
