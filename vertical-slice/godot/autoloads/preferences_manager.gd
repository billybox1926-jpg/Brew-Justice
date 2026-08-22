extends Node

## Persistent accessibility, audio, and input preferences.
## Loaded automatically at startup via project autoload.

signal preferences_updated

const SAVE_PATH := "user://brew_justice_prefs.cfg"

@export var colorblind_mode: bool = false
@export var master_volume: float = 1.0
@export var sfx_volume: float = 0.8
@export var subtitles_enabled: bool = true
@export var trail_enabled: bool = true
@export var trail_audio_cues: bool = true
@export var captions_enabled: bool = true
## Opt-in text-to-speech for narrative/insight text (issue #46). Off by default.
@export var tts_enabled: bool = false
## Vestibular safety (issue #44): when true, disable jitter/flicker/scale
## animation and show static low-motion alternatives instead. Off by default.
@export var reduced_motion: bool = false
## Rhythm input tolerance (issue #47). "strict" keeps tuned timing;
## "generous" widens hold/release windows so off-beat inputs still count.
@export_enum("strict", "generous") var rhythm_timing: String = "strict"
var custom_bindings: Dictionary = {}


func _ready() -> void:
	load_or_create_defaults()
	apply_settings()


func load_or_create_defaults() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) == OK:
		colorblind_mode = config.get_value("accessibility", "colorblind_mode", colorblind_mode)
		master_volume = config.get_value("audio", "master_volume", master_volume)
		sfx_volume = config.get_value("audio", "sfx_volume", sfx_volume)
		subtitles_enabled = config.get_value("ui", "subtitles_enabled", subtitles_enabled)
		trail_enabled = config.get_value("accessibility", "trail_enabled", trail_enabled)
		trail_audio_cues = config.get_value("accessibility", "trail_audio_cues", trail_audio_cues)
		captions_enabled = config.get_value("accessibility", "captions_enabled", captions_enabled)
		tts_enabled = config.get_value("accessibility", "tts_enabled", tts_enabled)
		reduced_motion = config.get_value("accessibility", "reduced_motion", reduced_motion)
		var loaded_timing: Variant = config.get_value(
			"accessibility", "rhythm_timing", rhythm_timing
		)
		rhythm_timing = loaded_timing if loaded_timing in ["strict", "generous"] else "strict"
		var loaded_bindings = config.get_value("input", "custom_bindings", {})
		if typeof(loaded_bindings) == TYPE_DICTIONARY:
			custom_bindings = loaded_bindings
		apply_bindings()
	else:
		save()


func save() -> void:
	var config := ConfigFile.new()
	config.set_value("accessibility", "colorblind_mode", colorblind_mode)
	config.set_value("audio", "master_volume", master_volume)
	config.set_value("audio", "sfx_volume", sfx_volume)
	config.set_value("ui", "subtitles_enabled", subtitles_enabled)
	config.set_value("accessibility", "trail_enabled", trail_enabled)
	config.set_value("accessibility", "trail_audio_cues", trail_audio_cues)
	config.set_value("accessibility", "captions_enabled", captions_enabled)
	config.set_value("accessibility", "tts_enabled", tts_enabled)
	config.set_value("accessibility", "reduced_motion", reduced_motion)
	config.set_value("accessibility", "rhythm_timing", rhythm_timing)
	_save_bindings_to_config(config)
	config.save(SAVE_PATH)


func apply_settings() -> void:
	if AudioServer.get_bus_count() > 0:
		AudioServer.set_bus_volume_db(0, linear_to_db(master_volume))
	apply_bindings()
	preferences_updated.emit()


func apply_bindings() -> void:
	for action in InputMap.get_actions():
		if custom_bindings.has(action):
			InputMap.action_erase_events(action)
			var events = custom_bindings[action]
			if typeof(events) == TYPE_ARRAY:
				for entry in events:
					if typeof(entry) == TYPE_DICTIONARY and entry.has("keycode"):
						var e := InputEventKey.new()
						e.keycode = int(entry.keycode)
						e.physical_keycode = e.keycode
						e.shift_pressed = bool(entry.get("shift", false))
						e.ctrl_pressed = bool(entry.get("ctrl", false))
						e.alt_pressed = bool(entry.get("alt", false))
						InputMap.action_add_event(action, e)


func save_binding(action: String, event: InputEvent) -> void:
	if event is InputEventKey:
		var entry := {
			"keycode": event.keycode,
			"shift": event.shift_pressed,
			"ctrl": event.ctrl_pressed,
			"alt": event.alt_pressed
		}
		custom_bindings[action] = [entry]
		save()


func _save_bindings_to_config(config: ConfigFile) -> void:
	config.set_value("input", "custom_bindings", custom_bindings)


func set_colorblind_mode(enabled: bool) -> void:
	if colorblind_mode == enabled:
		return
	colorblind_mode = enabled
	save()
	apply_settings()


func set_master_volume(value: float) -> void:
	master_volume = clamp(value, 0.0, 1.0)
	save()
	apply_settings()


func set_sfx_volume(value: float) -> void:
	sfx_volume = clamp(value, 0.0, 1.0)
	save()
	apply_settings()


func set_subtitles_enabled(enabled: bool) -> void:
	if subtitles_enabled == enabled:
		return
	subtitles_enabled = enabled
	save()
	apply_settings()


func set_captions_enabled(enabled: bool) -> void:
	if captions_enabled == enabled:
		return
	captions_enabled = enabled
	save()
	apply_settings()


func is_colorblind_mode() -> bool:
	return colorblind_mode
