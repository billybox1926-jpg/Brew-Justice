# Scent / Locator Trail Legibility Specification

**Issue:** #14
**Status:** Draft
**Version:** 1.0

## Purpose
Define measurable criteria for the scent/locator trail so it is a clear, accessible sensory aid, usable by players with diverse visual and cognitive needs.

---

## 1. Contrast Ratios (WCAG AA)

- **Trail elements** (dots, lines, shapes) must have a **luminance contrast ratio ≥ 4.5:1** against the background.
- **Bind highlights** (e.g., circles, diamonds, squares) must have **≥ 3.0:1** against the trail color to distinguish them.
- **Color‑blind safe palette** (from #12) must be used, with shapes as fallback.

**Testing:** Use a contrast checker (e.g., WebAIM) on the actual colors used in the game.

---

## 2. Animation Speed

- **Pulse frequency** of bind highlights **≤ 2 Hz** (2 cycles per second).
- **Trail fade‑in/out transitions** must be smooth, with a rate of change **≤ 0.5 opacity per second**.
- **Movement of trail points** should not exceed **2 pixels per frame** at 60 FPS.

**Rationale:** Prevents disorientation and photosensitive reactions.

---

## 3. Trail Growth Behavior

- **Trail length** (number of points) is capped at **60 points**.
- **Density** (points per screen area) should be proportional to presence and focus, but **never exceed 0.5 points per 1000 pixels**.
- **Growth rate** is exponential smoothed (lerp) with a time constant **≤ 0.5 seconds** to avoid sudden jumps.

---

## 4. Maximum Viewport Usage

- The trail should never occupy more than **20% of the screen width/height**.
- The trail should be confined to the **lower third** of the screen (near the player’s feet), unless the player is actively looking down.
- The trail should not overlap with UI elements (meter, labels).

---

## 5. Failure Example (Non‑Legible Trail)

- **Poor contrast:** Trail color is similar to background (#999 on #888).
- **Fast pulsing:** Bind highlights flash at 8 Hz, causing flicker.
- **Overgrowth:** Trail fills 70% of the screen, obscuring other elements.
- **No shape diversity:** All markers are identical circles, relying solely on color.
- **Jerkiness:** Trail points snap without smoothing, causing visual noise.

---

## 6. Photosensitivity Safety

- **No flashing** – all pulses and animations use smooth sine or exponential curves.
- **No sudden brightness changes** greater than 0.2 luminance within 100 ms.
- **Maximum brightness** of any trail element is 80% of full white to avoid glare.

---

## 7. Review and Acceptance

- The spec must be reviewed by at least one accessibility expert or tested with players.
- The implementation (#14) will be updated to meet these values.
- Any deviation must be documented and justified.

---

## Linked Issues
- #14 – Make the scent/locator trail a legible sensory aid
- #12 – Colorblind‑safe palette verification
- #21 – Automated scene‑smoke test (can verify these metrics)

**Last updated:** 2026-07-19
