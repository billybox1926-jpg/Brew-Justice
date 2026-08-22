extends RefCounted
class_name UiText

## Global UI text scaling + high-contrast colors (issue #45).
## Every UI font-size override and text color in the slice routes through
## here so the accessibility prefs apply uniformly without layout reflow
## (sizes multiply; anchors/containers are untouched).

const PREFS_PATH := "/root/PreferencesManager"

## Default (1.0x) sizes for each text role.
const BASE_CAPTION_SIZE := 20
const BASE_INSIGHT_SIZE := 24
const BASE_STATE_SIZE := 16
const BASE_HINT_SIZE := 14

## High-contrast palette: pure white on near-black backing. Contrast ratio
## vs Color(0.02, 0.02, 0.03) is ~19:1 — above WCAG AAA's 7:1 for normal text.
const HC_TEXT_COLOR := Color(1.0, 1.0, 1.0)
const HC_BACKING_COLOR := Color(0.0, 0.0, 0.0, 0.72)


static func _prefs() -> Node:
	# In --script SceneTree runs, Engine.get_main_loop() is null and absolute
	# get_node paths are rejected; resolve relative to the registered root.
	var loop := Engine.get_main_loop()
	if loop is SceneTree:
		return (loop as SceneTree).root.get_node_or_null(PREFS_PATH)
	if _script_tree != null and is_instance_valid(_script_tree):
		var root := _script_tree.root
		for child in root.get_children():
			if child.name == PREFS_PATH.get_slice("/", 2):
				return child
	return null


## Registered by SceneTree-based tests so statics can find the tree.
static var _script_tree: SceneTree = null


## Scale a base font size by the user's ui_text_scale preference.
static func scaled_size(base_size: int) -> int:
	var prefs := _prefs()
	var scale := 1.0 if prefs == null else float(prefs.ui_text_scale)
	return maxi(1, int(round(base_size * scale)))


static func high_contrast_enabled() -> bool:
	var prefs := _prefs()
	return prefs != null and bool(prefs.high_contrast_text)


## The text color to use: pure white under high contrast, else the given default.
static func text_color(default_color: Color) -> Color:
	return HC_TEXT_COLOR if high_contrast_enabled() else default_color


## Apply scaling (+ optional high-contrast color/backing) to a Label.
func apply_to_label(label: Label, base_size: int, default_color: Color) -> void:
	label.add_theme_font_size_override("font_size", UiText.scaled_size(base_size))
	label.add_theme_color_override("font_color", UiText.text_color(default_color))
	if UiText.high_contrast_enabled():
		_ensure_backing(label)


## Apply scaling to a RichTextLabel (normal_font_size role).
func apply_to_rich_label(rtl: RichTextLabel, base_size: int, default_color: Color) -> void:
	rtl.add_theme_font_size_override("normal_font_size", UiText.scaled_size(base_size))
	rtl.add_theme_color_override("default_color", UiText.text_color(default_color))
	if UiText.high_contrast_enabled():
		_ensure_backing(rtl)


## Adds a full-rect dark panel behind a control once, for contrast backing.
func _ensure_backing(control: Control) -> void:
	var parent := control.get_parent()
	if parent == null:
		return
	var backing_name := control.name + "ContrastBacking"
	if parent.has_node(backing_name):
		return
	var backing := ColorRect.new()
	backing.name = backing_name
	backing.color = UiText.HC_BACKING_COLOR
	backing.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backing.show_behind_parent = true
	control.add_child(backing)
