# Brew & Justice

A cozy neo-noir game about coffee, community, and **sensory justice** — built
in Godot 4.4 (GDScript).

The premise: different minds perceive the world deeply and intensely. This
game isn't built *with* accessibility features bolted on — accessibility **is**
the genre. The way a player regulates their own sensory load isn't a side
mechanic; it's how they investigate, co-regulate the room around them, and
solve mysteries.

## Playable demo (vertical slice)

A runnable Godot 4.4 vertical slice lives in `vertical-slice/godot/`. It is a
self-contained "focus-mode" scene that demonstrates the core loop:

- **Your calm leaks into the room.** Holding a steady rhythm raises a
  `presence` value; the peripheral vignette eases back and the space opens up.
- **Sensory load drives state.** The Sensory Meter moves through
  `Baseline → Hyperfocus → Overload`, reshaping the audio filters, the
  peripheral fade, and the clue markers.
- **Disruption is noise, not a separate bar.** A `chaos` spike injects jitter
  into your rhythm and throttles how much calm reaches the world. Re-grounding
  lets it decay. The shield and the weapon share the same currency: rhythm.

### Run it

1. Open `vertical-slice/godot/project.godot` in **Godot 4.4**.
2. Open `scenes/focus_mode.tscn`.
3. Press **F5** to run the scene.

### Controls

| Key / Input      | Action                                                        |
| ---------------- | ------------------------------------------------------------- |
| `F`              | Toggle focus mode (dims periphery, boosts perception)        |
| `Hold Space`     | Rhythmic stim: charges, and emits a calm pulse each beat      |
| `Release Space`  | Release the stim — drops sensory load by charge strength      |
| `Left Click`     | Raise sensory load (push toward Overload)                     |
| `R`              | Reset the Sensory Meter to baseline                           |
| `C`              | Inject a chaos spike (opt-in disruption — see below)          |

### How the loop reads

- Hold **Space** and keep a steady beat → `rhythm_pulse` fires (~1.8 beats/sec,
  ramping in over the first ~3 beats like entrainment). Each pulse raises
  `presence` and the vignette softens.
- Press **C** → a `chaos` spike jitters the beat clock and throttles the calm
  leak, so the room recoils. `chaos` decays on its own; keep stimming to win
  your peace back.

### Opt-in disruptor

`scripts/disruptor.gd` is a `Disruptor` node that emits `chaos_pulse(strength)`
on a randomized interval. It does **nothing** until you add it to the scene and
connect its `chaos_pulse` signal to `FocusModeMain._on_chaos`. By default the
room stays a sanctuary.

## Project layout

```
vertical-slice/godot/
  scenes/focus_mode.tscn      # the runnable demo scene
  scripts/
    focus_mode_main.gd        # scene root: state, audio buses, draw, signals
    sensory_meter.gd          # load state + Baseline/Hyperfocus/Overload tiers
    focus_toggle.gd           # focus mode on/off signal
    stim_tool.gd              # hold-to-charge stim + rhythm_pulse + chaos
    disruptor.gd              # opt-in chaos source (inert until connected)
prototype/
  focus-mode.html             # early non-Godot prototype
WIRING.md                     # 90-second Godot wiring checklist
```

## License

MIT — see `LICENSE`.
