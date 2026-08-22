# Wiring the Focus-Mode Slice

`vertical-slice/godot/scenes/focus_mode.tscn` in **Godot 4.4**.

## The short version

1. Open `vertical-slice/godot/project.godot` in Godot 4.4.
2. Open `scenes/focus_mode.tscn`.
3. Press **F5**.

That's it. The scene root has `focus_mode_main.gd` attached, and the scripts
**build everything else at runtime** — you do not hand-wire the audio bus,
the input map, or the ambient stream.

This document is verified against the code by
`test/test_wiring_doc.gd` (headless). If it fails, this doc has drifted.

> Last reconciled: Aug 2026, against the post-#36 repair of
> `focus_mode_main.gd` / `audio_bus_manager.gd`.

## What the scene file itself provides

The `.tscn` is not empty — it carries these nodes with these scripts:

| Node | Type | Script |
|---|---|---|
| *(root)* | Control | `focus_mode_main.gd` |
| `AudioBusManager` | Node | `audio_bus_manager.gd` |
| `SensoryCanvas` | Control | `sensory_canvas.gd` |
| `Disruptor` | Node | `disruptor.gd` |
| `DisruptionOverlay` | Control | `disruption_overlay.gd` |
| `ObserverLight` | Control | `observer_light.gd` (owns `RoomLight`, a `PointLight2D`) |
| `NpcRegular` | Node2D | `npc_regular.gd` (owns `Anim`, `NpcSprite`) |
| `SceneView` | Node2D | — (owns `TireSmudge`, `TireClue` sprites) |
| `AmbientAudio` | AudioStreamPlayer2D | — (stream assigned at runtime) |
| UI: `SensoryMeterBar`, `StateLabel`, `SensoryLabel`, `Highlight`, `StimIndicator` | Control family | — |

Everything else (meter/focus/stim components, evidence board, investigation
beat/UI, sensory crime loop, story beats, captions, trail/rain data) is
constructed by script at runtime, below.

## Runtime wiring: input actions

Registered in `_enter_tree()` via `_input_map_add_or_replace()` (replaces any
existing binding), plus demo actions from `_setup_demo_inputs()`. Note that
`project.godot` *also* declares `stim_hold` and `reset_sensory`; the runtime
registration wins because it erases and re-adds the action.

| Action | Key | Registered in |
|---|---|---|
| `focus_toggle` | **F** | `_enter_tree()` |
| `stim_hold` | **Space** | `_enter_tree()` |
| `reset_sensory` | **R** | `_enter_tree()` |
| `demo_overload` | **O** | `_setup_demo_inputs()` |
| `demo_stim_toggle` | **S** | `_setup_demo_inputs()` |
| `demo_tune_in` | **T** | `_setup_demo_inputs()` |

`chaos_trigger` (**C**) has no InputMap action and no project.godot entry:
the `_input()` handler checks `event.is_action_pressed("chaos_trigger")`,
which only fires if something else registered that action (e.g. saved custom
bindings from `PreferencesManager.apply_bindings()`). Out of the box, chaos
arrives through the `Disruptor` node's timer instead. This is a known gap —
see "Known gaps" below.

## Runtime wiring: audio (`AudioBusManager._ready()`)

- Creates the **SFX bus** if missing (`AudioServer.add_bus()`, send → Master).
  Previously it only looked the bus up, so on a fresh checkout all filter
  effects were silently inactive.
- Adds **LowPassFilter**, **HighPassFilter**, and **BandPassFilter** to the
  SFX bus if not already present; caches them for per-frame glide updates.
- Starts the synthesized cafe ambience: an `AudioStreamGenerator` on an
  internal `AudioStreamPlayer`, buffer-filled every frame
  (`_fill_cafe_buffer`). No pre-existing bus or stream needs to exist.
- Assigns a stream to the scene's `AmbientAudio` node if it lacks one and
  plays it.

Filter targets are set per-frame from game state via
`update_targets(mode, stim_holding, tune_active, focus_active)` — called from
`FocusModeMain._update_canvas()`. Chaos bands arrive via
`apply_chaos_band(band, intensity)`; world calm via `set_world_calm(calm)`.

## Runtime wiring: children constructed by FocusModeMain

All created in `_ready()` (directly or through `_setup_*` helpers):

| Component | Created by | Purpose |
|---|---|---|
| `SensoryMeter` | `_ready()` | owns sensory load value + mode tiers |
| `FocusToggle` | `_ready()` | emits `focus_changed` |
| `StimTool` | `_ready()` | emits `stim_released`, `rhythm_pulse` |
| `EvidenceBoard` | `_setup_evidence_board()` | registers TireSmudge/TireClue clues |
| `InvestigationBeat` | `_setup_investigation_beat()` | deduction beat gate |
| `InvestigationUI` | `_setup_investigation_ui()` | insight display |
| `SensoryCrimeLoop` | `_setup_sensory_crime_loop()` | phase machine (Observe→Overload→Stim→Tune-in→Resolve) |
| `StoryBeat` ("distant_transformer") | `_setup_story_beat_overload()` | lore beat fired on OVERLOAD phase |
| Caption label + timer | `_setup_captions()` | accessibility captions |

Track/trail/rain geometry (`build_track`, `build_trail`, `init_drops`) is
data built at startup, redrawn by `SensoryCanvas` each frame.

## Signal connections (source → target)

Every `connect()` in `focus_mode_main.gd`:

| Source signal | Target handler | Where connected |
|---|---|---|
| `FocusToggle.focus_changed` | `FocusModeMain._on_focus_changed` | `_ready()` |
| `StimTool.stim_released` | `FocusModeMain._on_stim_released` | `_ready()` |
| `StimTool.rhythm_pulse` | `FocusModeMain._on_rhythm_pulse` | `_ready()` |
| `FocusModeMain.reset_requested` | `FocusModeMain._on_reset` | `_ready()` |
| `FocusModeMain.reset_requested` | `FocusModeMain._reset_investigation` | `_setup_investigation_ui()` |
| `Disruptor.chaos_pulse` | `FocusModeMain._on_chaos` | `_ready()` |
| `Disruptor.chaos_pulse_rich` | `FocusModeMain._on_chaos_rich` | `_ready()` |
| `SensoryCrimeLoop.phase_changed` | `FocusModeMain._on_sensory_loop_phase_changed` | `_setup_sensory_crime_loop()` |
| `SensoryCrimeLoop.phase_changed` | `StoryBeat.on_phase_changed` | `_setup_story_beat_overload()` |
| `SensoryCrimeLoop.phase_changed` | `FocusModeMain._on_sensory_loop_phase_changed_for_profile` | `_setup_story_beat_overload()` |
| `EvidenceBoard.deduction_progress` | `FocusModeMain._on_deduction_progress` | `_setup_evidence_board()` |
| `EvidenceBoard.contradiction_detected` | `FocusModeMain._on_contradiction_detected` | `_setup_evidence_board()` |
| `InvestigationBeat.beat_resolved` | `FocusModeMain._on_beat_resolved` | `_setup_investigation_ui()` |
| `PreferencesManager.preferences_updated` | `FocusModeMain._on_preferences_updated` | `_setup_preferences()` |
| `CaptionTimer.timeout` | `FocusModeMain._hide_caption` | `_setup_captions()` |

Outbound signals emitted by `FocusModeMain` for external listeners:
`reset_requested`, `investigation_passed`, `investigation_blocked`,
`world_listeners_updated(presence)`, `calm_changed(calm)`,
`deduction_updated(progress, insight)`, `contradiction_noted(a, b)`.

World listeners updated each frame from `_update_world_listeners()`:
`ObserverLight.apply_calm()`, `NpcRegular.apply_presence()/apply_chaos_if_supported()`,
`TireSmudge/TireClue apply_presence()`, `AudioBusManager.set_world_calm()`.

## Controls (as wired)

| Key / Input | Action |
|---|---|
| **F** | Toggle focus mode (dims periphery, boosts perception) |
| **Hold Space** | Rhythmic stim: charges, emits a calm pulse each beat |
| **Release Space** | Drops sensory load by charge strength |
| **Left Click** | Raise sensory load (+9 toward Overload) and try clue resolve |
| **R** | Reset the Sensory Meter to baseline |
| **O / S / T** | Demo: force Overload / toggle focus / force Tune-in |

## Opt-in disruptor

`scripts/disruptor.gd` is a `Disruptor` node wired into the scene. It emits
`chaos_pulse(strength)` on its own randomized interval, and
`chaos_pulse(strength, duration, band)` variants when a profile/variant is
assigned (profiles load from `resources/disruptor_profiles/`). Both signals
are connected to FocusModeMain automatically in `_ready()` — no manual step.

## Known gaps

- `chaos_trigger` (**C**) is checked in `_input()` but never registered —
  out of the box, pressing C does nothing unless PreferencesManager restores
  a custom binding for it.
- `project.godot` duplicates the `stim_hold` / `reset_sensory` definitions
  that the script re-registers anyway; harmless but redundant.

## If it doesn't run

- **Parse errors on load** — run the headless check:
  `godot --headless --path . --check-only --script res://scripts/focus_mode_main.gd`
- **Smoke test**: `godot --headless --path . --script res://test/run_focus_mode_smoke.gd`
  should print `SMOKE PASS`.
- **No audio** — `AudioBusManager` creates the SFX bus and streams itself;
  if `AmbientAudio` is missing from the scene, add an
  `AudioStreamPlayer2D` named `AmbientAudio` as a child of the root.
- **Wiring doc drift** — run `godot --headless --path . --script res://test/test_wiring_doc.gd`;
  it fails if the tables above no longer match the code.
