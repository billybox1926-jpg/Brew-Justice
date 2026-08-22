extends RefCounted
class_name L10n

## Localization flow (issue #52): single entry point for translatable
## strings in code. Wraps Object.tr() semantics via TranslationServer so
## static contexts work; falls back to the key's English text when no
## translation is loaded (which matches the CSV's en column).
##
## Strings live in locale/translations.csv (Godot CSV translation format,
## imported to .translation files registered in project.godot). Mark new
## user-facing strings with L10n.t("KEY") — never hard-code display text.


## Translate a message key, optionally formatting args into the result.
static func t(key: String, args: Array = []) -> String:
	var text := tr_text(key)
	if not args.is_empty():
		text = text % args
	return text


static func tr_text(key: String) -> String:
	var translated := TranslationServer.translate(key)
	# TranslationServer returns the key itself when nothing matches; the
	# en column of translations.csv uses readable English as the key fallback
	# only for legacy keys. For missing keys we return the key so gaps are
	# visible rather than silently wrong.
	return translated if translated != "" else key


## Convenience: phase label keys.
static func phase_key(phase: int) -> String:
	match phase:
		0:
			return "PHASE_OBSERVE"
		1:
			return "PHASE_OVERLOAD"
		2:
			return "PHASE_STIM"
		3:
			return "PHASE_TUNE_IN"
		4:
			return "PHASE_RESOLVE"
	return ""
