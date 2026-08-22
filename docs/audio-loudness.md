# Audio loudness policy

How loud Brew Justice should be, and how we keep it safe for
sound-sensitive players. The **enforced** part of this policy is the
limiter on the SFX bus (`scripts/audio_bus_manager.gd`, constants
`LIMITER_CEILING_DB` / `LIMITER_THRESHOLD_DB`) — everything here is
guidance plus that hard ceiling.

## Loudness targets

Measured as integrated LUFS over a full ambient loop (e.g. with
`ffmpeg -i clip.wav -af loudnorm=print_format=summary -f null -`):

| Content | Integrated target | True peak max |
| --- | --- | --- |
| Cafe ambience (baseline loop) | −24 LUFS | −10 dBTP |
| UI sounds (toggles, captions chime) | −20 LUFS | −8 dBTP |
| Chaos / disruption layers | −18 LUFS | −6 dBTP |
| Anything else (narration stings, etc.) | −20 LUFS | −8 dBTP |

Rationale: ambience sits well below conversation level so it never
masks; chaos is allowed to be *present* but only ~6 dB above baseline —
noticeable without being aversive. True peak stays under −6 dBTP so the
bus limiter rarely engages in normal play; it exists for spikes, not as
a mix tool.

## Hard safety ceiling

`AudioBusManager._setup_audio_bus()` appends an `AudioEffectLimiter`
(named `LoudnessLimiter`) as the **last** effect on the SFX bus:

- threshold: −9 dB
- ceiling: −6 dB

No source, variant, or future chaos effect can push SFX output past the
ceiling regardless of how loud the input asset is.

## Contributor checklist

Before landing audio changes or new sound assets:

- [ ] New/changed clips measure at their table's integrated LUFS ±1 LU
      (run `ffmpeg -i clip.wav -af loudnorm=print_format=summary -f null -`
      and read "Input Integrated").
- [ ] True peak ≤ the table's dBTP column.
- [ ] Chaos-driven sources: play the worst-case overload scenario at
      100% master volume and confirm the limiter indicator stays at or
      below ceiling (no audible hard-clipping crunch).
- [ ] No new autoplaying sound without a way to silence it via
      PreferencesManager.
- [ ] Sudden-onset sounds ramp in over ≥80 ms unless the player triggered
      them directly.
- [ ] If you touched bus effects: `godot --headless --path vertical-slice/godot --quit`
      loads clean and the smoke suite passes.

## Known gaps

- LUFS targets are documentation-level only; CI does not measure them
  (no automated loudness gate yet).
- The limiter protects the SFX bus; Master-bus sources added elsewhere
  bypass it until they are routed to SFX.
