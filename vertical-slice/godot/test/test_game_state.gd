extends SceneTree

## Headless verification for session-state persistence (issue #57).
## Run: godot --headless --path . --script res://test/test_game_state.gd
## Covers: round-trip, defaults on missing file, additive-only saves
## (foreign keys preserved), clue unlock / beat completion helpers,
## wipe, and no duplicate registrations.

const GSM := preload("res://autoloads/game_state_manager.gd")


func _init() -> void:
	var failures := 0
	var gsm: Node = GSM.new()
	root.add_child(gsm)
	gsm.wipe()

	# 1. Missing file -> load returns false, defaults intact.
	if gsm.load_state():
		print("GS FAIL: load_state() true with no save file")
		failures += 1

	# 2. Round-trip.
	gsm.deduction_progress = 0.6
	gsm.record_clue_clarity("tire_smudge", 0.9)
	gsm.mark_beat_completed("distant_transformer")
	gsm.investigation_resolved = true
	if not gsm.save_state():
		print("GS FAIL: save_state() returned false")
		failures += 1

	var gsm2: Node = GSM.new()
	root.add_child(gsm2)
	if not gsm2.load_state():
		print("GS FAIL: load_state() false after save")
		failures += 1
	if absf(gsm2.deduction_progress - 0.6) > 0.001:
		print("GS FAIL: deduction_progress not restored")
		failures += 1
	if not gsm2.is_clue_unlocked("tire_smudge"):
		print("GS FAIL: clue unlock not restored")
		failures += 1
	if not gsm2.is_beat_completed("distant_transformer"):
		print("GS FAIL: beat completion not restored")
		failures += 1
	if not gsm2.investigation_resolved:
		print("GS FAIL: investigation_resolved not restored")
		failures += 1
	if absf(gsm2.clue_clarity.get("tire_smudge", 0.0) - 0.9) > 0.001:
		print("GS FAIL: clue clarity value not restored")
		failures += 1

	# 3. Additive-only: a foreign key written into the file survives a save.
	var f := FileAccess.open("user://brew_justice_save.json", FileAccess.READ_WRITE)
	var text := f.get_as_text()
	text = text.insert(1, '"future_field": {"x": 1}, ')
	f.seek(0)
	f.store_string(text)
	f.close()
	gsm2.deduction_progress = 0.7
	gsm2.save_state()
	var parsed: Variant = JSON.parse_string(
		FileAccess.open("user://brew_justice_save.json", FileAccess.READ).get_as_text()
	)
	if not (parsed is Dictionary) or not (parsed as Dictionary).has("future_field"):
		print("GS FAIL: foreign keys dropped by save (not additive-only)")
		failures += 1
	elif absf(float(parsed["deduction_progress"]) - 0.7) > 0.001:
		print("GS FAIL: second save did not update progress")
		failures += 1

	# 4. No duplicate registrations: mark_beat_completed twice -> single entry;
	#    record_clue_clarity twice -> one key.
	gsm2.mark_beat_completed("distant_transformer")
	if gsm2.completed_beats.count("distant_transformer") != 1:
		print("GS FAIL: duplicate beat registration")
		failures += 1
	gsm2.record_clue_clarity("tire_smudge", 1.0)
	if gsm2.clue_clarity.size() != 1 or gsm2.clue_clarity["tire_smudge"] != 1.0:
		print("GS FAIL: duplicate/incorrect clue registration")
		failures += 1

	# 5. Wipe resets memory and removes the file.
	gsm2.wipe()
	if gsm2.has_save():
		print("GS FAIL: has_save() true after wipe")
		failures += 1
	if not gsm2.clue_clarity.is_empty() or not gsm2.completed_beats.is_empty():
		print("GS FAIL: wipe left state behind")
		failures += 1

	gsm.queue_free()
	gsm2.queue_free()

	if failures > 0:
		print("GS FAIL: %d failure(s)" % failures)
		quit(1)
	else:
		print("GS PASS")
		quit(0)
