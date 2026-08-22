# Performance budget & profiling baseline

Budgets for the vertical slice at a 60 Hz target, plus the measured
baseline from the capture script (`test/profile_baseline.gd`). Re-run
the capture after any rendering or overlay change and update this file.

## Frame time targets (60 Hz)

| Metric | Budget | Baseline (headless, 240 frames) |
| --- | --- | --- |
| Mean frame time | ≤ 10 ms | ~6.9–9.2 ms |
| p50 frame time | ≤ 12 ms | 6.8–7.2 ms |
| p99 frame time | ≤ 16.6 ms (one dropped frame per 100) | 13–50 ms (noisy headless; see below) |
| Worst frame | ≤ 33 ms (1 skipped frame max) | up to ~75 ms on first-load spikes |

Baseline caveat, stated plainly: these captures are **headless**, so
there is no GPU rasterization cost — real on-GPU frame times will be
higher. Headless p99 is also noisy (GC/import-cache hitches land there).
Treat the mean/p50 as the comparable signal; re-capture in a windowed
run before judging p99 regressions.

## Memory budget

| System | Budget | Baseline |
| --- | --- | --- |
| `focus_mode` scene static memory | ≤ 64 MB | 21.5 MB |
| Static memory peak during loop | ≤ 96 MB | 26.9 MB |
| Trail system (per-frame PackedVector2Array rebuilds) | no growth across 240 frames | flat (arrays reused, not accumulated) |

The trail/vignette paths rebuild packed arrays per draw rather than
allocating new ones — any change that grows memory frame-over-frame is a
regression against this budget.

## Top runtime contenders (from code inspection + capture overlay list)

1. **`AudioBusManager._process`** — runs every frame doing two jobs:
   cafe-sample synthesis (44.1 kHz sample-by-sample float math in
   `_generate_sample`) and filter glide. The synthesis inner loop is the
   single most expensive per-frame script path.
2. **`FocusModeMain._process` / `_update_ui`** — sensory math plus label/
   bar updates and `_update_disruption_overlay` fan-out each frame.
3. **`DisruptionOverlay._draw`** — redraws every frame while chaos > 0
   (sin/cos flicker + line draws). Under `reduced_motion` (#44) it goes
   fully static, which is also the cheapest path.

Godot's built-in profiler (Monitor tab: Process time per node) is the
tool to confirm ranking on desktop; the headless capture cannot measure
per-node process cost, so this list is inspection-based, not sampled.

## Capture script

```bash
godot --headless --path vertical-slice/godot \
  --script res://test/profile_baseline.gd
```

Writes `docs/perf-baseline.json` with frame-time percentiles, memory,
and the live overlay node list. Run it before and after performance-
relevant changes and diff.

## Known gaps

- Baselines captured headless on Windows; GPU-bound costs not measured.
- No automated CI gate on budgets yet — the smoke suite checks
  correctness only.
- Per-node profiler sampling requires an interactive editor run;
  contender ranking above is code-inspection based.
