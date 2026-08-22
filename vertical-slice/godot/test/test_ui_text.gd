extends SceneTree

## Verification for UI text scaling + high-contrast text (issue #45).
## Run: godot --headless --path . --script res://test/test_ui_text.gd
## Asserts: defaults are 1.0/off, scaling multiplies sizes, persistence
## round-trips, and every shipped text color passes >=4.5:1 (WCAG AA)
## against its dark background under both modes.

const PREFS := preload("res://autoloads/preferences_manager.gd")
const UITEXT := preload("res://scripts/ui_text.gd")


## WCAG relative luminance of a Color.
func _luminance(c: Color) -> float:
	var lin := func(v: float) -> float:
		return v / 12.92 if v <= 0.04045 else pow((v + 0.055) / 1.055, 2.4)
	return 0.2126 * lin.call(c.r) + 0.7152 * lin.call(c.g) + 0.0722 * lin.call(c.b)


func _contrast(a: Color, b: Color) -> float:
	var la := _luminance(a)
	var lb := _luminance(b)
	var lighter := maxf(la, lb)
	var darker := minf(la, lb)
	return (lighter + 0.05) / (darker + 0.05)


func _init() -> void:
	UITEXT._script_tree = self
	var failures := 0

	# Darkest in-game backdrop the labels sit over.
	var dark_bg := Color(0.02, 0.02, 0.03)

	# 1. Defaults.
	var prefs: Node = PREFS.new()
	prefs.name = "PreferencesManager"
	root.add_child(prefs)
	if prefs.ui_text_scale != 1.0 or prefs.high_contrast_text != false:
		print("UIX FAIL: ui_text_scale/high_contrast_text not default")
		failures += 1

	# 2. Scaling multiplies and floors at 1px.
	if UiText.scaled_size(20) != 20:
		print("UIX FAIL: scale 1.0 changed size")
		failures += 1
	prefs.ui_text_scale = 1.5
	if UiText.scaled_size(20) != 30:
		print("UIX FAIL: 1.5x scale did not multiply 20 -> 30")
		failures += 1

	# 3. Persistence round-trip incl. clamping out-of-range values.
	prefs.ui_text_scale = 99.0
	prefs.save()
	var prefs2: Node = PREFS.new()
	prefs2.load_or_create_defaults()
	if prefs2.ui_text_scale != 2.0:
		print("UIX FAIL: ui_text_scale clamp/persist broken (%s)" % str(prefs2.ui_text_scale))
		failures += 1
	prefs2.free()

	# 4. High contrast switches colors to pure white.
	prefs.high_contrast_text = true
	if UiText.text_color(Color(0.5, 0.5, 0.5)) != UiText.HC_TEXT_COLOR:
		print("UIX FAIL: high contrast did not force HC color")
		failures += 1
	prefs.high_contrast_text = false
	if UiText.text_color(Color(0.5, 0.5, 0.5)) != Color(0.5, 0.5, 0.5):
		print("UIX FAIL: normal mode altered default color")
		failures += 1

	# 5. Contrast audit: every text color used by the slice vs dark bg,
	#    in BOTH normal and high-contrast mode. WCAG AA large-text 3:1,
	#    normal-text 4.5:1; these are HUD/status texts so require >=4.5.
	var audit := {
		"state_default": Color(0.478, 0.655, 0.792),
		"state_calm": Color(0.95, 0.95, 0.95),
		"hint_gray": Color(0.518, 0.506, 0.471),
		"hint_hyperfocus": Color(1.0, 0.78, 0.2),
		"hint_overload": Color(0.96, 0.27, 0.24),
		"caption": Color(0.95, 0.95, 0.95),
		"insight": Color(0.95, 0.95, 0.85),
	}
	for hc in [false, true]:
		prefs.high_contrast_text = hc
		for role: String in audit:
			var fg: Color = UiText.text_color(audit[role])
			var ratio := _contrast(fg, dark_bg)
			if ratio < 4.5:
				print("UIX FAIL: %s (hc=%s) contrast %.2f:1 < 4.5:1" % [role, str(hc), ratio])
				failures += 1
	print(
		(
			"UIX NOTE: worst-case audited pair hint_gray/dark_bg = %.2f:1"
			% _contrast(UiText.text_color(audit["hint_gray"]), dark_bg)
		)
	)

	prefs.queue_free()

	if failures > 0:
		print("UIX FAIL: %d failure(s)" % failures)
		quit(1)
	else:
		print("UIX PASS")
		quit(0)
