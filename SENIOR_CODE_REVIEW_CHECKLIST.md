# Senior Code Review Checklist

Use this checklist to review the current Brew Justice vertical slice before merging final polish work or while preparing issue #8 implementation. The checklist focuses on the thin orchestrator architecture, persistence, investigation logic, sensory feedback, world reactivity, testing coverage, and Godot static/runtime warnings.

## 1. Core Architectural Review: Thin Orchestrator

**Primary file:** `vertical-slice/godot/scripts/focus_mode_main.gd`

- **Signal wiring:** Verify that `_ready()` and `_enter_tree()` correctly connect all subsystems. Confirm scene reloads do not accidentally leave signals disconnected or duplicated.
- **InputMap compliance:** Confirm that every raw keycode, such as `KEY_SPACE` or `KEY_I`, has been replaced with InputMap actions, such as `stim_pulse` or `interact`. Search for `KEY_` and `keycode` to ensure none were missed.
- **Clue resolution gate:** Review `_update_clue_resolution()` and confirm `resolve_progress` decays only outside the `TUNE_IN` phase. Check whether interrupted tweens or state changes can leave progress stuck.

## 2. State and Persistence: Data Layer

**Primary files:**

- `vertical-slice/godot/autoloads/preferences_manager.gd`
- `vertical-slice/godot/scripts/audio_bus_manager.gd`
- `vertical-slice/godot/scripts/sensory_meter.gd`

- **File I/O:** Review `save()` and `load_prefs()` in `PreferencesManager`. Confirm there is a safe fallback if `user://` cannot be written or read, such as on restricted Linux or Web environments.
- **Default fallbacks:** Ensure every `get_value()` call has a sensible default, such as `colorblind_mode` defaulting to `false`.
- **Audio bus indexing:** Confirm `AudioBusManager` retrieves buses by name with `AudioServer.get_bus_index("Master")` or similar lookups instead of relying on hardcoded bus indexes.

## 3. Investigation Logic: Graph and Loop

**Primary files:**

- `vertical-slice/godot/scripts/clue_graph.gd`
- `vertical-slice/godot/scripts/evidence_board.gd`
- `vertical-slice/godot/scripts/sensory_crime_loop.gd`

- **Circular dependencies:** Confirm `ClueGraph` does not reference `EvidenceBoard`. The intended direction should remain Graph to Board to Main.
- **Graph traversal:** When resolving a clue, verify the `leads_to` array handles dead ends gracefully. A clue with no outgoing leads should not stall the investigation loop and should fall back to an observe-ready state.
- **Phase transitions:** Verify that the transition from `STIM` to `TUNE_IN` is triggered by the rhythm pulse rather than a timer, preserving the co-regulation theme.

## 4. Visual and Sensory Feedback: Draw Layer

**Primary file:** `vertical-slice/godot/scripts/sensory_canvas.gd`

- **Performance:** Review `_draw_vignette()` and related redraw scheduling. `queue_redraw()` may be acceptable for a single canvas, but idle states should not trigger unnecessary redraw loops.
- **Color palette fallback:** In `_get_vignette_color()`, confirm `_palette.color_for()` is guarded so startup with a null or unavailable preferences manager safely falls back to default colors.
- **Trail logic:** Confirm `trail_enabled` and `trail_audio_cues` disable scent-trail visuals and audio cues fully. If the trail is disabled, it should avoid drawing rather than simply drawing fully transparent output.

## 5. World Reactivity: Issue #8 Pre-implementation Review

Use these checks when implementing or reviewing world reactivity work.

- **Light complexity:** If adding `WorldLightsController`, avoid creating a new `Tween` for every light every frame. Prefer a single parallel tween or direct `modulate` updates when tweens are already running.
- **NPC state machine:** Keep NPC reactions decoupled. Emit signals from `FocusModeMain` instead of giving NPCs direct references to `SensoryMeter`.
- **Ambient audio:** Confirm the `Ambient` bus exists in `vertical-slice/godot/project.godot` before setting its volume. Guard missing buses with `if bus_index == -1: return`.

## 6. Testing Coverage: Safety Net

**Primary file:** `vertical-slice/godot/test/integration/test_focus_mode_smoke.gd`

Review whether smoke or integration tests cover these edge cases:

- Colorblind mode toggling during gameplay.
- Rebinding a key to an invalid or unexpected input type, such as mouse input instead of keyboard input.
- Resolving a clue when calm is exactly at the threshold boundary, such as `0.7`.
- Preference mocks implementing `is_colorblind_mode()` so tests do not pass because missing methods silently evaluate as falsey assumptions.

## 7. Static Analysis and Runtime Warnings

- Open the Godot Output console and check for red warnings, such as `Node not found` or `Invalid get index`.
- Review `@onready` variables that could become null if the scene structure changes, such as overlay or UI node references.
- Run the smoke test scene and inspect the Remote tab in the Godot debugger to verify runtime node wiring against `WIRING.md`.

## Suggested Review Verdict

The vertical slice can be considered production-ready when the review confirms:

- Signals are the primary integration mechanism.
- The orchestrator remains thin.
- Accessibility preferences persist reliably.
- Investigation graph traversal handles dead ends.
- Sensory feedback remains performant and respects accessibility toggles.
- Smoke coverage protects the key mid-game and threshold edge cases.
