# Architecture

Brew & Justice is **signal-driven**. State lives in a few plain values;
everything else *reacts* to changes through Godot signals. There is no
tree-scanning, no global singletons reached into from a child, and no per-frame
polling of other nodes. This document is the long-form behind the two mermaid
diagrams in [README.md](README.md).

## The emotional model: three values

The whole game is three numbers on `FocusModeMain`:

| Value | Range | Meaning |
| --- | --- | --- |
| `sensory` | 0–100 | Load on the player. Drives `Baseline → Hyperfocus → Overload`. |
| `presence` | 0–1 | The player's calm. Rises as they hold a steady rhythm; the room settles with them. |
| `chaos` | 0–1 | Sensory static in the room. Raised by disruptors; throttles how much calm reaches the world. |

`tier` thresholds (in `SensoryMeter`): Baseline 0–40, Hyperfocus 41–75,
Overload 76–100. `sensory` is owned by `SensoryMeter`; `presence` and `chaos`
are owned by `FocusModeMain`.

## Components and their signals

```
FocusModeMain  (scene root, Control)
├── SensoryMeter   — owns `sensory`; emits load_changed / mode_changed
├── FocusToggle    — emits focus_changed(bool)
├── StimTool       — emits stim_released(float) / rhythm_pulse(float)
└── (optional) Disruptor — emits chaos_pulse(float)
```

Exact signatures (from source):

- `StimTool.stim_released(strength: float)` — fires on release; `strength` is
  the held charge (0–1). `FocusModeMain` turns it into a sensory-load drop
  (`strength * 18.0`).
- `StimTool.rhythm_pulse(intensity: float)` — fires once per calm beat *while
  held*. `intensity` ramps in over the first ~3 beats (`beat_clock / TAU*3`)
  then sustains at 1.0, and is reduced by `(1 - chaos*0.8)` so disrupted calm
  leaks less into the room.
- `FocusToggle.focus_changed(active: bool)` — focus mode on/off.
- `Disruptor.chaos_pulse(strength: float)` — a chaos spike. Inert until you
  connect it to `FocusModeMain._on_chaos`.

## The rhythm clock

`StimTool` runs a free-running beat using a `cos` wave — no animation plugin,
no stored frames, nothing allocated per frame:

```
beat_clock += delta * BEAT_RATE * TAU * (1 + jitter)
beat_now  = cos(beat_clock)
if beat_prev <= 0 and beat_now > 0:   # upward zero-crossing = one beat
    rhythm_pulse.emit(intensity)
beat_prev = beat_now
```

- `BEAT_RATE = 1.8` cycles/sec — near a resting heart rate, so the pulse feels
  like breathing, not a metronome.
- `jitter = randf_range(-1,1) * chaos * 0.6` — chaos warps the beat, breaking
  entrainment. This is the mechanic's spine: **the shield and the weapon share
  the same currency (rhythm).** A disruptor doesn't add a separate bar; it
  desynchronizes the beat you're trying to keep.

## Signal flow (the meat)

```
StimTool ──rhythm_pulse──▶ FocusModeMain ──load──▶ SensoryMeter
   │                          │  ▲
   └──stim_released──────────┘  │ mode_changed
Disruptor ──chaos_pulse────────┘
                                 │
       FocusModeMain emits to:
         • SFX bus        (LowPass + HighPass + BandPass)  [audio targets]
         • Vignette + clue markers   (presence, peripheries)  ┄ chaos throttles
         • Ambient light + NPC       (presence)              ┄ chaos throttles
```

What each arrow does per frame in `_process`:

1. `presence = max(presence - delta*(0.15 + chaos*0.4), 0)` — calm decays,
   faster when chaos is high.
2. `chaos = max(chaos - delta*0.2, 0)` — static always drains on its own.
3. `rhythm_pulse` → `presence += intensity * 0.1 * (1 - chaos*0.8)` — each beat
   of steady stim pushes calm back into the world; chaos bleeds the leak.
4. `chaos_pulse` (`C` key or `Disruptor`) → `chaos = min(chaos + strength, 1)`.
5. `sensory` follows `SensoryMeter`; its `mode` selects audio targets, vignette
   width, clue alpha, and the bind-trail density.

## Decoupling rule (do not break this)

`FocusModeMain` **owns references** to its components (`stim`, `focus`, `meter`)
set in `_ready()`. Children never call `get_node("../..")` or `find_child` to
reach a parent. They emit; the root connects. The one stable cross-reference is
the scene root's known children (`$SceneView/TireSmudge`, etc.) — acceptable
because it's the root wiring its own subtree, not a leaf climbing.

`Disruptor` is the proof of the rule: it knows nothing about `FocusModeMain`. It
just emits `chaos_pulse`. Wire it (or don't) and the rest of the game doesn't
change. That's why the room "stays a sanctuary" until you connect it.

## Audio: filters act on a noise bed

`_setup_audio()` builds the SFX bus at runtime and adds `AudioEffectLowPassFilter`
+ `AudioEffectHighPassFilter` (and the BandPass "tune-in" from issue #7). The
bed is **pink noise** (corrected from white in `fe846c6` — white is harsh
static). Per `mode`, `_audio_targets()` sets cutoff/resonance targets and
`_lerp_audio()` glides toward them with a frame-rate-independent exponential
(`1 - exp(-8*delta)`). Holding stim lowers the cutoffs (muffle); Overload pushes
the high cutoff up and resonance way up (piercing). The audio is **texture-free
and runtime-light** — no stream files, the bed is synthesized.

## Rendering: draw, don't allocate

`FocusModeMain._draw()` paints the whole scene each frame: background, skyline,
the sensory "smear" graph, the scent/bind trail (`_update_trail`), the vignette
(`_vignette(1 - peripheries, presence)`), and the clue marker. The vignette
widens as `presence` rises — that's the screen-level co-regulation signal. All
from `cos`/lerp math; no `Sprite` allocations in the loop. The trail density and
clue alpha are driven by `sensory` mode, not raw polling of unrelated nodes.

## Why this shape

- **Battery / focus**: no allocations in `_process`, no plugins, math on the
  fly. The stim pulse is a `cos` zero-crossing, not 60fps of tween state.
- **Testability**: a component can be driven by emitting its signal from a test;
  nothing reaches sideways.
- **Sensory honesty**: the player's regulation *is* the world's state. Calm
  leaks out (`presence`), disruption leaks in (`chaos`). The mechanics are the
  message.

## Open threads (tracked issues)

- #7 BandPass "tune-in" — the filter exists; the isolate-one-voice behaviour is
  the next step.
- #8 presence → light + NPC; #18 vignette as the screen-level calm cue.
- #14 scent/locator trail legibility; #17 real (pink-noise) cafe ambience.
- #3 neon-flicker overlay driven by `chaos`; #4 wire the `Disruptor` in-scene.
- Full signal map: see [README.md](README.md) → "Signal flow".
