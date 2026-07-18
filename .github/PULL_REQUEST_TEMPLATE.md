## What this PR does

<!-- one or two sentences; link the issue it closes with "closes #N" -->

closes #

## Kind of change

- [ ] `enhancement` — new feature or system
- [ ] `accessibility` — serves the sensory-justice theme
- [ ] `architecture` — clean, decoupled, signal-driven code
- [ ] `bug` — fixes something broken
- [ ] `documentation` — docs only

## Sensory-safety check

- [ ] No new white noise / harsh audio (pink only — see `fe846c6`)
- [ ] No flashing or rapid state snaps; any pulse eases
- [ ] Colorblind-safe tokens used; controls remappable if input changed
- [ ] Battery-conscious: no per-frame allocations / polling added

## How to test

- [ ] Godot slice runs (`scenes/focus_mode.tscn`, F5)
- [ ] Prototype in sync if audio/controls touched (`prototype/focus-mode.html`)

## Notes for reviewers

<!-- anything non-obvious: why this approach, what you considered -->
