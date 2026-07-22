# Roadmap

Tracked across four milestones. Full issue list: #19 README upgrade · milestones below.

| Milestone | Theme | Highlights |
| :--- | :--- | :--- |
| **#2 Vertical Slice Polish** | Ship the slice | Disruptor wiring (#4), neon-flicker overlay (#3), scent/locator trail (#14), vignette calm signal (#18), WIRING doc (#5), on-screen chaos UI (#6) |
| **#3 Sensory Systems** | Sound + world react | BandPass "tune-in" (#7), presence-driven light + NPC (#8), smudge→neon clue (#9), real cafe ambience (#17), legible trail (#14) |
| **#4 Narrative & World** | The mystery | Sensory-crime loop (#10), antagonist-as-chaos lore (#11), clue-graph model (#15) |
| **#5 Accessibility Audit** | Sensory justice, verified | Colorblind-safe palette (#12), input remap + captions (#13), persist prefs (#16) |

## Project layout

```text
vertical-slice/godot/
  scenes/focus_mode.tscn      # the runnable demo scene
  scripts/
    focus_mode_main.gd        # scene root: state, audio buses, draw, signals
    sensory_meter.gd          # load state + Baseline/Hyperfocus/Overload tiers
    focus_toggle.gd           # focus mode on/off signal
    stim_tool.gd              # hold-to-charge stim + rhythm_pulse + chaos
    disruptor.gd              # opt-in chaos source (inert until connected)
prototype/
  focus-mode.html             # early non-Godot prototype (Web Audio)
assets/
  readme-focus-mock.svg       # animated loop preview used above
WIRING.md                     # 90-second Godot wiring checklist
```
