# Senior Code Review Checklist — Brew-Justice Vertical Slice

Use this checklist before merging gameplay, wiring, or accessibility changes. Missing items are additive candidates for faster follow-up PRs.

---

## 1. Architecture and Decoupling

**Primary file:** `vertical-slice/godot/scripts/focus_mode_main.gd`

- Review changed files for **single-responsibility drift** (helpers moving into `focus_mode_main.gd` instead of dedicated `.gd` scripts).
- Confirm new signals stay in the component that owns the state; callers only connect, never duplicate logic.
- If a new world listener is added, verify it is **signal-driven**, not polling from `_process`.
- Check for dead exports, unused `@onready` references, and orphan `connect()` blocks.
- Confirm scene reloads do not leave signals disconnected or duplicated.
- Review `@onready` variables that could become null if the scene structure changes; consider temporarily renaming a referenced node to confirm graceful failure or clear logging.

**Supporting files:** `investigation_beat.gd`, `story_beat.gd`, `sensory_crime_loop.gd`

---

## 2. State and Persistence

**Primary files:**

- `vertical-slice/godot/autoloads/preferences_manager.gd`
- `vertical-slice/godot/scripts/audio_bus_manager.gd`
- `vertical-slice/godot/scripts/sensory_meter.gd`

- Verify `PreferencesManager` persists sensitive fields (`colorblind_mode`, `captions_enabled`, `trail_enabled`, `trail_audio_cues`, `custom_bindings`) on meaningful change, not every frame.
- Confirm fallback defaults are restored when the config file is missing or corrupted.
- **Custom bindings persistence:** After remapping a key, restart the game and confirm the new binding is still applied.
- Review autoload injection in `project.godot` to prevent duplicate `PreferencesManager` entries after repeated local patches.
- Verify missing `user://` writes/reads fail safely instead of crashing on restricted environments.

---

## 3. Accessibility and Sensory Feedback

**Primary files:**

- `vertical-slice/godot/scripts/sensory_canvas.gd`
- `vertical-slice/godot/resources/color_palette.gd`
- `vertical-slice/godot/autoloads/preferences_manager.gd`
- `vertical-slice/godot/scripts/focus_mode_main.gd`
- `vertical-slice/godot/scripts/neon_clue.gd`
- `vertical-slice/godot/scripts/smudge_resolver.gd`

- Confirm all visuals route through `ColorPalette.color_for()` when colorblind mode toggles.
- Toggle `PreferencesManager.colorblind_mode` mid-game and verify immediate redraw without crashes.
- **Caption system:** Verify captions appear for chaos spikes, trail pulses, and phase transitions, and that `captions_enabled` toggles them off immediately.
- Confirm `captions_enabled` is persisted across restarts.
- Confirm `trail_enabled` and `trail_audio_cues` disable scent-trail visuals and audio fully; when disabled, skip drawing rather than drawing transparent output.
- Check that `SensoryCanvas` redraws only when state changes (`queue_redraw_if_needed()`), not every frame.
- Verify `NeonClue` and `SmudgeResolver` no-op gracefully when no shader material is assigned.

---

## 4. Input Remapping

**Primary files:**

- `vertical-slice/godot/scripts/focus_mode_main.gd`
- `vertical-slice/godot/autoloads/preferences_manager.gd`

- Confirm all input handling uses `InputMap` actions, not raw `KEY_*` checks.
- Verify demo actions (`demo_overload`, `demo_stim_toggle`, `demo_tune_in`) do not collide with persisted custom bindings.
- Confirm remapped bindings survive restart via `PreferencesManager.custom_bindings`.
- Review `_input()` branches for accidental fallthrough or unreleased stim state when focus toggles rapidly.

---

## 5. Investigation Logic and Clue Graph

**Primary files:**

- `vertical-slice/godot/scripts/evidence_board.gd`
- `vertical-slice/godot/scripts/clue_graph.gd`
- `vertical-slice/godot/scripts/investigation_beat.gd`
- `vertical-slice/godot/scripts/focus_mode_main.gd`
- `vertical-slice/godot/scripts/disruptor.gd`

- Confirm `ClueGraph.register_clue()` never connects duplicate `clarity_changed` handlers.
- Verify `EvidenceBoard.resolve_clue()` does not double-emit `graph_progression_requested`.
- Verify clue resolution is gated by **calm threshold**, not just time, and that chaos resets progress.
- **Disruptor profile wiring:** Confirm the active clue's antagonist profile is applied to the `Disruptor` during the Overload phase, and that `chaos_style` affects pulse behavior.
- Check that `InvestigationBeat` does not advance while UI is blocking input.
- Verify `ClueGraph` evaluation remains stable with 0, 1, or N clues.
- Verify circular dependencies do not creep back in; intended direction remains Graph -> Board -> Main.

---

## 6. Audio Layer

**Primary files:**

- `vertical-slice/godot/scripts/audio_bus_manager.gd`

- Confirm all audio filters glide through `AudioBusManager._glide_filters()` with exponential smoothing; no direct property writes outside that path.
- Verify `apply_chaos_band()` is safe when called before `_ready()` / filter setup.
- Confirm the SFX bus name matches the project's actual audio bus layout.
- Verify the cafe generator stereo balance remains centered and ping-pong safe.

---

## 7. Testing and Headless Runner

**Primary file:** `vertical-slice/godot/test/integration/test_focus_mode_smoke.gd`

- Run the full smoke suite and confirm **no new failures** from this change.
- Verify tests do not depend on specific scene hierarchy beyond `focus_mode.tscn`.
- Confirm new tests cover the happy path and at least one failure/no-op path.
- Check that no test serializes `Node` state without `call()` or public methods.

---

## 8. World Reactivity

**Primary files:**

- `vertical-slice/godot/scripts/focus_mode_main.gd`
- `vertical-slice/godot/scripts/observer_light.gd`
- `vertical-slice/godot/scripts/npc_regular.gd`
- `vertical-slice/godot/scripts/audio_bus_manager.gd`

- Avoid **per-light tweens**; reuse one controller update per frame via `FocusModeMain._update_world_listeners()`.
- Verify NPC behavior is decoupled from `FocusModeMain` state through `NpcRegular.apply_presence()` and `apply_chaos_spike()`.
- Confirm `AudioBusManager` guards missing buses with `push_warning` instead of crashing when `Ambient` is absent.
- Verify startle/recover paths reset position cleanly and do not accumulate drift.

---

## 9. Runtime Verification

- Open the Godot Output console and check for red warnings, such as `Node not found` or `Invalid get index`.
- Review `@onready` variables that could become null if the scene structure changes.
- Launch the scene and inspect the Remote tab in the Godot debugger to verify runtime node wiring against `WIRING.md`.
- Confirm smoke tests still pass in headless mode after this change.

**Reference:** `WIRING.md`

---

## 10. Edge-Case and Integration Checks

- Verify interrupted clue-resolve tweens re-tween cleanly without jumping or stalling progress.
- Verify colorblind mode toggle during active `TuneIn` preserves clue tint and trail visibility immediately.
- Verify calm threshold boundaries do not oscillate under floating-point noise.
- Confirm restarting the game preserves custom keybindings, captions, trail, and colorblind settings.
- Verify `FocusModeMain.stim` does not register duplicate listeners on reset.

**Files to review:** `focus_mode_main.gd`, `preferences_manager.gd`, `sensory_canvas.gd`

---

## Suggested Review Verdict

The vertical slice is **vertical-slice ready** when review confirms:

- Signals are the primary integration mechanism.
- The orchestrator remains thin.
- Accessibility preferences persist reliably.
- Investigation graph traversal handles dead ends.
- Sensory feedback remains performant and respects accessibility toggles.
- Smoke coverage protects key mid-game and threshold edge cases.

- [ ] **Vertical-slice ready** — checklist complete, no blockers.
- [ ] **Needs follow-up** — missing items tracked in a new issue or follow-up PR.
