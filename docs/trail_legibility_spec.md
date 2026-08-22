# Scent / Locator Trail Legibility Specification

**Issue:** #38 · **Implements the trail requirements of:** #14
**Status:** Active — values below are the *shipped* values, each tied to the
constant that implements it
**Last reconciled:** 2026-08-22 against `sensory_canvas.gd` and
`focus_mode_main.gd` on `docs/wiring-reconciliation`

The trail is the player's primary low-vision navigation aid. Its job is to be
findable when needed and *quiet* when not: legibility rules apply most when
the player is lost, and the trail must get out of the way as the player
regulates and closes in on the clue.

---

## 1. Visual rules

| Property | Requirement | Implemented by |
|---|---|---|
| Base width | **≥ 5 px** at 1280×720, anti-aliased polyline | `sensory_canvas.gd` `TRAIL_BASE_WIDTH = 5.0`; width = `max(5.0, 2.0 + presence × 3.0)` |
| Width response | Width grows with presence (max +3 px) — never shrinks below base | same expression |
| Trail length | **14–36 points**, scaled by presence + focus bonus | `focus_mode_main.gd` `TRAIL_MIN_POINTS = 14`, `TRAIL_STEP_POINTS = 22` |
| Length smoothing | Exponential smoothing, time constant **≤ 0.25 s** (`1 − e^(−4.5·Δt)`) | `HIGHLIGHT_SMOOTH = 4.5` in `_update_trail_legibility()` |
| Dash spacing | Bind highlights sampled every **6–18 points** along the trail, tightening (more markers) as density rises | `TRAIL_DASH_MAX_STEP = 18`, min step 6 in `_update_canvas()` |
| Colors | Warm ochre normal / high-luminance yellow colorblind variant; dims to neutral grey near resolution | `TRAIL_COLOR_NORMAL`, `TRAIL_COLOR_COLORBLIND`, `TRAIL_COLOR_DIM` in `sensory_canvas.gd`; palette variants in `resources/color_palette.gd` (`trail`, `cb_trail`) |

### Dimming behavior (the trail must fade, not vanish)

| State | Behavior |
|---|---|
| Baseline wandering | Full trail color, alpha 0.9 |
| Calm ≥ 0.72 or tune-progress ≥ 0.35 (near a clue) | Trail lerps toward grey (`TRAIL_COLOR_DIM`) — the *world* is opening, the aid recedes |
| Tune-progress > 0.85 (clue resolving) | Alpha clamps to **≤ 0.12** (`TRAIL_FADE_RESOLVED`) |
| Player disables trail | `PreferencesManager.trail_enabled = false` hides the trail entirely (`trail_help_visible`) |

Rationale: a navigation aid that stays at full salience after it's needed
becomes noise. The fade curve is tied to *calm*, the game's regulation
signal, so the trail literally quiets as the player settles.

---

## 2. Colorblind requirements

1. **Palette fallback:** colorblind mode swaps the ochre trail for the
   high-luminance yellow variant (`cb_trail` in `color_palette.gd`,
   `Color(1.0, 0.95, 0.45)`), selected via
   `PreferencesManager.colorblind_mode`.
2. **Shape fallback (mandatory, always on):** bind markers are never
   color-only. Three distinct shapes rotate by index — **circle, diamond,
   square** (`_draw_bind_highlights()`, `i % 3`). Shape identity survives any
   palette, including grayscale.
3. **Contrast targets:** trail ≥ 4.5:1 against typical scene background;
   bind highlights ≥ 3:1 against the trail color. Verify with a WCAG contrast
   checker against the actual scene, not a white swatch.
4. Trail is never the *only* cue: proximity audio cues exist
   (`PreferencesManager.trail_audio_cues`) and the clue glow is a separate
   channel.

---

## 3. Interaction

### Trail-to-target proximity

- `set_trail_target()` computes the nearest trail point to the pointer/target.
- Proximity signal `trail_proximity(0..1)` fires per update: full strength
  within **45 px** (`_trail_proximity_threshold`), falling to 0 at **75 px**
  (smoothstep over a 30 px band).
- Consumers (audio cues, UI hints) must treat proximity as a *gradient*,
  not a boolean.

### Bind placement

- Bind highlights sit at evenly spaced samples along the current trail
  (step 6–18 points per §1), so markers always ride the path rather than
  floating in screen space.
- Marker size scales gently with presence: **6–10 px** base, pulsing
  ±20% (`base_size = 6.0 + presence × 4.0`, pulse `0.8 + 0.4·pulse`).

### Fade / resolve rules

- **Photosensitivity:** bind pulse is a sine at **≤ 1.5 Hz**
  (`sin(t · (1 + presence·2))`, max frequency multiplier 3 rad/s ≈ 0.48 Hz
  full cycle at presence 1.0 — well under the 2 Hz WCAG flash limit). No
  hard on/off flashes anywhere in the trail system.
- **Resolution:** as tune-progress passes 0.85, trail alpha clamps to ≤ 0.12
  and the clue glow takes over as the salient element. After resolve, the
  trail resets with the investigation (length back to `TRAIL_MIN_POINTS`).
- **Growth never snaps:** all length/alpha changes go through the exp
  smoothing in §1; no step changes larger than the smoothing constant allows.

---

## 4. Implementation reference

| Concern | File | Section |
|---|---|---|
| Trail drawing, colors, dimming, proximity | `vertical-slice/godot/scripts/sensory_canvas.gd` | `_draw()`, `_computed_trail_color()`, `set_trail_target()`, `_draw_trail()`, `_draw_bind_highlights()` |
| Trail length/density state machine | `vertical-slice/godot/scripts/focus_mode_main.gd` | `_update_trail_legibility()`, `_computed_trail_points()`, constants block (`TRAIL_*`, `HIGHLIGHT_SMOOTH`) |
| Palette (normal + colorblind variants) | `vertical-slice/godot/resources/color_palette.gd` | `trail`, `cb_trail` |
| Player toggles | `vertical-slice/godot/autoloads/preferences_manager.gd` | `trail_enabled`, `trail_audio_cues`, `colorblind_mode` |

Automated coverage: `test/test_integration_expanded.gd` (proximity emission
and empty-trail safety), `test/test_wiring_doc.gd` (wiring drift), focus-mode
smoke runner (scene loads with the trail system active).

---

## 5. Non-legible failure examples (for review)

- Trail color within 1.5:1 of the scene background.
- All bind markers the same shape (color-only distinction).
- Pulse implemented as a square wave or alpha snap.
- Trail at full alpha after clue resolution.
- Length changes applied without smoothing (point-count snapping).
- Removing the trail entirely when the player disables *audio cues* — the
  two toggles are independent.

---

## 6. Review and acceptance

- Any change to the constants in §1 must update this doc in the same PR
  (the wiring-doc guard pattern applies here too).
- Deviations require a documented justification tied to a playtest
  observation, per the neurodivergent playtest protocol
  (`docs/playtests/neurodivergent-playtest-protocol.md`).
