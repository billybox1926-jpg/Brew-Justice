extends RefCounted
class_name NarrativeTTS

## Optional text-to-speech for narrative/insight text (issue #46).
## Uses Godot's built-in DisplayServer TTS voices. Strictly opt-in:
## speaks only when PreferencesManager.tts_enabled is true AND the
## platform exposes at least one TTS voice.

const PREFS_PATH := "/root/PreferencesManager"


static func tts_available() -> bool:
	return DisplayServer.tts_get_voices().size() > 0


func _enabled() -> bool:
	var prefs: Node = Engine.get_main_loop().root.get_node_or_null(PREFS_PATH)
	return prefs != null and bool(prefs.tts_enabled)


## Speak `text` if TTS is opted in and available. Returns true if spoken.
func speak(text: String) -> bool:
	if text.is_empty() or not _enabled():
		return false
	if not NarrativeTTS.tts_available():
		return false
	# One utterance at a time: interrupt any in-flight narration.
	DisplayServer.tts_stop()
	DisplayServer.tts_speak(text, "default")
	return true


func stop() -> void:
	if NarrativeTTS.tts_available():
		DisplayServer.tts_stop()


func is_speaking() -> bool:
	if not NarrativeTTS.tts_available():
		return false
	return DisplayServer.tts_is_speaking() or DisplayServer.tts_is_paused()
