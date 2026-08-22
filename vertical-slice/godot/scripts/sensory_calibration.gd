extends CanvasLayer
class_name SensoryCalibration

## First-run sensory calibration (issue #48): lets the player pick a
## chaos/sensory pacing comfort level before play. Fully skippable —
## skipping keeps the designed "standard" pacing and marks calibration
## done so the prompt doesn't nag. Result persists via PreferencesManager.
##
## Keys: 1 = gentle, 2 = standard, 3 = intense, Esc/Enter = skip.

signal finished(pacing: String)

const PACING_FACTORS := {
	"gentle": {"intensity": 0.6, "interval": 1.4},
	"standard": {"intensity": 1.0, "interval": 1.0},
	"intense": {"intensity": 1.3, "interval": 0.7},
}

var panel: Panel
var label: Label
var active: bool = false


func _ready() -> void:
	layer = 60
	panel = Panel.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.02, 0.02, 0.04, 0.92)
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)
	label = Label.new()
	label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiText.new().apply_to_label(label, UiText.BASE_INSIGHT_SIZE, Color(0.95, 0.95, 0.9))
	label.text = (L10n.t("CALIBRATION_PROMPT").replace("||", "\n\n"))
	panel.add_child(label)
	visible = false
	active = false


## Open the calibration screen. Called on first run when not yet calibrated.
func open() -> void:
	if active:
		return
	active = true
	visible = true


func _unhandled_input(event: InputEvent) -> void:
	if not active or not (event is InputEventKey) or not event.is_pressed():
		return
	var key := (event as InputEventKey).keycode
	match key:
		KEY_1:
			choose("gentle")
		KEY_2:
			choose("standard")
		KEY_3:
			choose("intense")
		KEY_ESCAPE, KEY_ENTER:
			skip()
	get_viewport().set_input_as_handled()


## Apply the chosen pacing and close.
func choose(pacing: String) -> void:
	if not PACING_FACTORS.has(pacing):
		return
	var prefs := get_node_or_null("/root/PreferencesManager")
	if prefs:
		prefs.sensory_pacing = pacing
		prefs.calibration_done = true
		prefs.save()
	_close()
	finished.emit(pacing)


## Skip keeps standard pacing but still marks calibration done so the
## prompt never blocks a returning player.
func skip() -> void:
	var prefs := get_node_or_null("/root/PreferencesManager")
	if prefs:
		prefs.calibration_done = true
		prefs.save()
	_close()
	finished.emit("standard")


func _close() -> void:
	active = false
	visible = false


## Intensity/interval multipliers for a given pacing, applied by the
## disruptor owner to scale chaos delivery.
static func factors_for(pacing: String) -> Dictionary:
	return PACING_FACTORS.get(pacing, PACING_FACTORS["standard"])
