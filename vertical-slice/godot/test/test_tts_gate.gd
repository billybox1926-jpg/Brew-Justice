extends SceneTree

## Headless verification for the opt-in TTS gate (issue #46).
## Run: godot --headless --path . --script res://test/test_tts_gate.gd
## Headless servers expose no TTS voices, so we assert the GATE logic:
## disabled by default, speak() never reaches DisplayServer while off,
## and the flag round-trips through PreferencesManager persistence.

const NARRATIVE_TTS := preload("res://scripts/narrative_tts.gd")
const PREFS := preload("res://autoloads/preferences_manager.gd")


func _init() -> void:
	var failures := 0

	# Instantiate PreferencesManager directly, as test_integration_expanded.gd
	# does; --script runs skip project autoloads.
	var prefs: Node = PREFS.new()
	root.add_child(prefs)

	# 1. Opt-in: default must be OFF.
	if prefs.tts_enabled != false:
		print("TTS FAIL: tts_enabled defaults to true; must be opt-in")
		failures += 1

	# 2. While disabled, speak() is a no-op regardless of voice availability.
	var tts: NarrativeTTS = NARRATIVE_TTS.new()
	tts.speak("This must never be spoken.")
	if tts.is_speaking():
		print("TTS FAIL: spoke while tts_enabled=false")
		failures += 1

	# 3. Empty text is always rejected.
	prefs.tts_enabled = true
	if tts.speak(""):
		print("TTS FAIL: empty text accepted")
		failures += 1
	prefs.tts_enabled = false

	# 4. The setting round-trips through save/load.
	prefs.tts_enabled = true
	prefs.save()
	var prefs2: Node = PREFS.new()
	prefs2.load_or_create_defaults()
	if prefs2.tts_enabled != true:
		print("TTS FAIL: tts_enabled not persisted/loaded")
		failures += 1
	prefs2.free()

	# 5. Document the environment honestly: headless has no voices, so the
	# on-device audible path can't be exercised here.
	if NARRATIVE_TTS.tts_available():
		if not tts.speak("gate open"):
			print("TTS FAIL: speak() refused while enabled with voices present")
			failures += 1
	else:
		print("TTS NOTE: no TTS voices in headless env; audible path untested here")

	tts.stop()
	prefs.queue_free()

	if failures > 0:
		print("TTS FAIL: %d failure(s)" % failures)
		quit(1)
	else:
		print("TTS PASS")
		quit(0)
