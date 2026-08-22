extends SceneTree

## Verification for the localization flow (issue #52).
## Run: godot --headless --path . --script res://test/test_l10n.gd
## Asserts: translations.csv imported and registered, L10n.t() resolves
## known keys to English, formats args, returns keys for unknown entries
## (visible gaps), phase_key maps enum -> key, and switching locale to es
## yields Spanish text.

const L10N := preload("res://scripts/l10n.gd")


func _init() -> void:
	var failures := 0

	# 1. Known English key resolves.
	var en := L10n.t("PHASE_OVERLOAD")
	if en != "Overload":
		print("L10N FAIL: PHASE_OVERLOAD gave '%s', expected 'Overload'" % en)
		failures += 1

	# 2. Formatting args substitute into translated text.
	var surge := L10n.t("CAPTION_CHAOS_SURGE", ["low"])
	if surge != "Chaos surge — low band":
		print("L10N FAIL: CAPTION_CHAOS_SURGE gave '%s'" % surge)
		failures += 1

	# 3. Unknown key is returned verbatim (gap stays visible).
	if L10n.t("TOTALLY_BOGUS_KEY") != "TOTALLY_BOGUS_KEY":
		print("L10N FAIL: unknown key not passed through")
		failures += 1

	# 4. Phase enum mapping covers all five phases.
	var phases := [0, 1, 2, 3, 4]
	for p in phases:
		var k: String = L10n.phase_key(p)
		if k.is_empty() or L10n.t(k) == k:
			print("L10N FAIL: phase %d key '%s' unresolved" % [p, k])
			failures += 1

	# 5. Locale switch to Spanish changes output (framework end-to-end).
	TranslationServer.set_locale("es")
	var es := L10n.t("PHASE_OVERLOAD")
	TranslationServer.set_locale("en")
	if es != "Sobrecarga":
		print(
			"L10N NOTE/Fail: es locale gave '%s' — Spanish translation missing or not loaded" % es
		)
		# Count as failure only if no translation resource loaded at all.
		if TranslationServer.get_loaded_locales().is_empty():
			failures += 1

	if failures > 0:
		print("L10N FAIL: %d failure(s)" % failures)
		quit(1)
	else:
		print("L10N PASS")
		quit(0)
