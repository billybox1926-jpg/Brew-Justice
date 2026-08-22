# Resilience & graceful degradation spec

How the vertical slice behaves when pieces are missing at runtime
(issue #59): failed `@onready` lookups, audio init failures, or a
missing `PreferencesManager` autoload. The rule of thumb:

> **Degrade the feature, never crash the frame — and never fail silently.**
> Every fallback logs once, loudly, via `push_error`/`push_warning`.

## Fallback matrix

| Failure | Behavior | Where owned |
| --- | --- | --- |
| `PreferencesManager` autoload missing | All `_prefs` guards treat it as null; accessibility features (captions, TTS, reduced motion, scaling) silently-off this session; game runs on built-in defaults. Logged via `push_error`. | `focus_mode_main.gd` (`_install_fallbacks_for_missing_nodes`) and every `if _prefs` guard |
| SensoryMeter missing at init | `FallbackNode` no-op installed in the `meter` slot; load changes do nothing; game remains playable but static | `fallback_node.gd`, installed by `_install_fallbacks_for_missing_nodes` |
| StimTool missing at init | `FallbackNode` no-op in `stim` slot; stim input does nothing | same |
| EvidenceBoard / InvestigationBeat / UI overlays | Constructed in code (`X.new()`), so they cannot be missing unless class registration fails — no fallback needed | `_setup_evidence_board` etc. |
| `cafe_ambience.tres` asset missing | Procedural placeholder WAV generated at runtime; ambience continues | `audio_bus_manager.gd` `_make_placeholder_stream()` |
| AmbientAudio node absent | Skipped gracefully (`get_node_or_null`) | `audio_bus_manager.gd` |
| SFX bus / filters already exist | Idempotent: found by name instead of duplicated | `_setup_audio_bus()` |
| TTS voices absent (headless, some Linux) | `NarrativeTTS.tts_available()` false → narration skipped | `narrative_tts.gd` |
| No joypads connected | Haptic commands are safe no-ops | `haptic_feedback.gd` |
| Save file corrupt | `load_state()` returns false, defaults kept, warning pushed | `game_state_manager.gd` |

## Contributor guidance

1. **Guard optional dependencies with `get_node_or_null` + null checks**;
   never assume a sibling node exists. Existing code does this for
   `observer_light`, `tire_clue`, `evidence_board`, etc. — follow it.
2. **Log every fallback exactly once**, with `push_error` for
   player-visible degradation and `push_warning` for cosmetic ones.
   Silent fallbacks mask bugs; repeated log spam hides real signals.
3. **Prefer no-op objects over null-spread.** If many call sites would
   each need a null check, install a no-op object (see
   `fallback_node.gd`) so callers stay simple.
4. **Never try/catch around gameplay logic to hide errors.** GDScript
   has no exceptions; a push_error + degrade is the pattern.
5. **Smoke-test your failure path**: temporarily rename a node in the
   scene, run the smoke suite, confirm PASS with the degraded path and
   the expected error line, then revert.

## Known gaps

- `FallbackNode` covers the meter/stim surface only; other slots fail
  loudly rather than degrading (acceptable: they're code-constructed).
- Audio device failures mid-session (device unplugged) are not handled
  beyond Godot's internal fallbacks.
