# Architecture

Brew & Justice is **signal-driven**. State lives in a few plain values;
everything else *reacts* to changes through Godot signals.

## Nodes in the vertical slice

```text
FocusModeMain   (Control root) — thin orchestrator
├── AudioBusManager     (Node)    — SFX bus, filters, cafe synthesis
├── SensoryCanvas       (Control) — draws vignette/trail/highlights/clue glow
├── SensoryMeter        — owns `sensory`; mode only via exposed state
├── FocusToggle         — emits focus_changed
├── StimTool            — emits stim_released / rhythm_pulse
└── Disruptor           — emits chaos_pulse
]
with SceneView:
  ├── TireSmudge
  └── TireClue
  ├── ObserverLight -> RoomLight
  └── NpcRegular -> Anim, NpcSprite
]
with UI:
  ├── SensoryMeterBar
  ├── StateLabel
  ├── SensoryLabel
  ├── Highlight
  └── StimIndicator
]
with async audio:
  └── AmbientAudio (played by AudioBusManager synthesiser)
```

```text
StimTool ──rhythm_pulse──▶ FocusModeMain ──presence──▶ ObserverLight / NpcRegular
Disruptor ─chaos_pulse──▶ FocusModeMain ──chaos────▶ DisruptionOverlay
```

![System interaction diagram](assets/brewjustice.svg)

Audio targets are set on `AudioBusManager` each frame; it glides lowpass/highpass
and bandpass filter values from the scene’s state.

## Teardown and invariants

- Root owns references to collaborators; children do not climb the tree.
- `AudioBusManager` is the sole owner of audio bus setup and cafe synthesis.
- `SensoryCanvas` is the sole owner of drawn feedback:
  vignette/trail/bind highlights/clue glow.
- `FocusModeMain` has no audio setup and no drawing code.

## Open threads

- #20 split `FocusModeMain` into `AudioBusManager` + `SensoryCanvas`.
- #22 trail legibility spec; #21 smoke tests; #27 demo scene+GIF.
