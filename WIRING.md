# Wiring the Focus-Mode Slice

`vertical-slice/godot/scenes/focus_mode.tscn` in **Godot 4.4**.

## The short version

1. Open `vertical-slice/godot/project.godot` in Godot 4.4.
2. Open `scenes/focus_mode.tscn`.
3. Press **F5**.

That's it. The scene root already has `focus_mode_main.gd` attached, and the
script **builds everything else at runtime** — you do not hand-wire the audio
bus, the input map, or the ambient stream. The old "confirm SFX bus / Input Map"
steps are gone because the code creates them.

## What the script wires for you (runtime)

On `_enter_tree()` it registers input actions programmatically:

| Action | Key | Where |
| --- | --- | --- |
| `focus_toggle` | **F** | `_input_map_add_or_replace` |
| `stim_hold` | **Space** | `_input_map_add_or_replace` |
| `reset_sensory` | **R** | `_input_map_add_or_replace` |
| (chaos) | **C** | handled directly in `_input` (not an InputMap action) |

On `_ready()` it builds the scene graph and audio:

- Creates `SensoryMeter`, `FocusToggle`, `StimTool` as child nodes and connects
  their signals (`stim_released`, `rhythm_pulse`, `focus_changed`).
- **Audio**: creates an `SFX` bus at runtime, adds a `LowPassFilter`
  (180 Hz, Q 0.7) and a `HighPassFilter` (1200 Hz, Q 0.5), points
  `AmbientAudio.bus = "SFX"`, and feeds it a synthesized cafe-ambience
  stream (`_make_cafe_stream`). No pre-existing bus or effect needs to exist
  in Project Settings.
- Builds the track, scent/bind trail, rain, and UI nodes.

## Controls (as wired)

| Key / Input | Action |
| --- | --- |
| `F` | Toggle focus mode (dims periphery, boosts perception) |
| `Hold Space` | Rhythmic stim: charges, emits a calm pulse each beat |
| `Release Space` | Drops sensory load by charge strength |
| `Left Click` | Raise sensory load (push toward Overload) |
| `R` | Reset the Sensory Meter to baseline |
| `C` | Inject a chaos spike (opt-in disruption) |

## First-run punchlist

- [ ] Scene runs with **F5** and shows the rainy borough + sensory meter.
- [ ] **F** dims the periphery and brightens the tire-tread clue.
- [ ] **Hold Space** pulses; releasing drops the meter.
- [ ] Audio is a soft pink-noise bed (muffles on stim, sharpens toward Overload)
      — *not* harsh white static.
- [ ] **C** jitters the beat and recoils the room; it decays on its own.
- [ ] **R** resets to Baseline.

## Opt-in disruptor

`scripts/disruptor.gd` is a `Disruptor` node that emits `chaos_pulse(strength)`
on a randomized interval. It does nothing until you add it to the scene and
connect its `chaos_pulse` signal to `FocusModeMain._on_chaos`. By default the
room stays a sanctuary.

## If it doesn't run

- **`@onready` node errors** — a `$SceneView/...` path is missing. The scene
  exposes `TireSmudge`, `TireClue`, `SensoryMeterBar`, `StateLabel`,
  `SensoryLabel`, `Highlight`, `StimIndicator`. Any other path in
  `focus_mode_main.gd` is a bug — the script expects no extra nodes.
- **No audio** — `AmbientAudio` is created by the script; if it's missing from
  the scene, `_setup_audio` will fail. Add an `AudioStreamPlayer2D` named
  `AmbientAudio` as a child of the root.
