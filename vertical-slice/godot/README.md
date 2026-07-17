# Godot Focus-Mode Migration

This contains the first migration milestone for the vertical slice of _Brew & Justice_: a Godot 4.4 project that recreates the focus-mode behavior validated in the HTML prototype at `../prototype/focus-mode.html`.

## Goal

> Recreate the feel of the HTML prototype in a Godot 2D scene.

When you can open `res://scenes/focus_mode.tscn` and experience the same sensory-perception hook—focus toggle, audio filter shift, smudge-to-neon clue resolution, rhythmic stim—the migration milestone is complete.

## Controls

- **F** — toggle focus mode
- **Click canvas** — raise sensory load
- **Hold Space** — rhythmic stim / self-regulation
- **R** — reset sensory load to baseline

## Scene structure

- `scenes/focus_mode.tscn` — root control scene
- `scripts/focus_mode_main.gd` — main loop, rendering, audio, UI wiring
- `scripts/sensory_meter.gd` — sensory load state machine
- `scripts/focus_toggle.gd` — F key handler
- `scripts/stim_tool.gd` — spacebar hold mechanic

## Audio note

Audio requires a user gesture to unlock audio context on most platforms. Click the canvas once to initialize the noise bed. The lowpass/highpass filter chain will then respond to the Sensory Meter state shifts.

## Still todo

- [ ] Extract control rendering into reusable nodes
- [ ] Add coffee truck UI and closing ritual sequence
- [ ] Add investigation layer and deduction lock-in conversation system
- [ ] Vertical slice: _The Stolen Trike_ full cycle

## Migration checklist

- [ ] Smudge clarifies to neon clue under focus
- [ ] Focus mode dims periphery and increases clue intensity
- [ ] Overload mode fragments audio
- [ ] Rhythmic stim reliably brings sensory load down
- [ ] Overall transition feels identical to the HTML prototype
