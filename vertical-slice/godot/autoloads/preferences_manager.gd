extends Node
class_name PreferencesManager

## Persistent accessibility and audio preferences.
## Loaded automatically at startup via project autoload.
## Other systems read this directly and/or listen for `preferences_updated`.

signal preferences_updated()

const SAVE_PATH := "user://brew_justice_prefs.cfg"

@export var colorblind_mode: bool = false
@export var master_volume: float = 1.0
@export var sfx_volume: float = 0.8
@export var subtitles_enabled: bool = true


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
	else:
		save()


func save() -> void:
	var config := ConfigFile.new()
	config.set_value("accessibility", "colorblind_mode", colorblind_mode)
	config.set_value("audio", "master_volume", master_volume)
	config.set_value("audio", "sfx_volume", sfx_volume)
	config.set_value("ui", "subtitles_enabled", subtitles_enabled)
	config.save(SAVE_PATH)


func apply_settings() -> void:
	# Audio bus application is intentionally minimal until an exposed
	# settings UI calls these setters. We keep the signal so systems
	# can react without coupling to save/load internals.
	if AudioServer.get_bus_count() > 0:
		AudioServer.set_bus_volume_db(0, linear_to_db(master_volume))
	preferences_updated.emit()


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


func is_colorblind_mode() -> bool:
	return colorblind_mode
