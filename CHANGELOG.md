# Changelog

All notable changes to Brew & Justice are documented here. The project is
pre-1.0; entries are grouped by what landed, not by release versions.

## Unreleased

### Added
- Full GitHub wiki (13 pages + sidebar/footer) covering architecture, the
  sensory model, rhythm/chaos/audio/rendering, contributing, roadmap, the
  accessibility stance, and a glossary.
- `.gitignore` tuned for Godot 4.x (excludes `.godot/`, `*.import`, local
  secrets, build output).
- `scripts/create-milestones.sh` — seeds the four milestones and the tracked
  issue tree via the GitHub API.

### Docs
- `CONTRIBUTING.md` (canonical guide), `CONTRIBUTORS.md` (redirect),
  `CODE_OF_CONDUCT.md` (Contributor Covenant 2.1, sensory-safe),
  `SECURITY.md`, and `.github/` PR + issue templates.
- `ARCHITECTURE.md` — the signal-driven design behind the README diagrams.
- `README.md` — deluxe version: manifesto, mermaid diagrams, animated preview,
  roadmap.
- `WIRING.md` reconciled with the runtime-wired scene.

## 2026-07-18

### Fixed
- Audio bed changed from **white noise to pink noise** (`fe846c6`) — white is
  harsh static and a sensory-harm trigger; pink rolls off the highs. Applies to
  the Godot ambient bed and both HTML-prototype buffers.
- Removed a dead `@onready var jalopy` pointing at a non-existent scene node
  (would have thrown at `_ready`).

### Added
- Stim-rhythm signal system: `StimTool.rhythm_pulse` (calm beat → `presence`),
  chaos disruption loop, and an opt-in `Disruptor` node (`chaos_pulse`).
- Four milestones (#2–#5) and a tracked issue tree (#3–#19), labeled, assigned,
  and linked as sub-issues.
