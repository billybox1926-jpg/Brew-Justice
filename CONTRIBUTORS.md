# Contributing to Brew & Justice

Thanks for wanting to help build a cozy neo-noir game where **accessibility is
the genre**, not a bolt-on. This file explains how the project is organized and
how to work in it without tripping over anyone else.

## The one rule

Accessibility *is* the design. Any change that makes the game harder to
perceive, regulate, or control for a neurodivergent player needs a compensating
feature (caption, colorblind-safe token, remap, calm signal) — not a disclaimer.
If a sound, flash, or density would overwhelm, soften it. See the noise-colour
fix (`fe846c6`) for the tone we hold: white noise → pink noise because the
ambient bed must not be the thing that overloads the player.

## Branch hygiene

- Work on a **feature branch** off `main`; never commit straight to `main`.
- Keep branches small and atomic. One concern per branch, one logical change per
  commit.
- Before pushing: `git pull --rebase` so history stays linear. The CI bot may
  push formatting fixes (e.g. ruff), so a rebase keeps your branch clean.
- Delete the branch once it's merged.
- Commit messages: short imperative subject, why-not-what body when non-obvious.
  Reference the issue it closes (`closes #N`).

## Issues, milestones, labels

Everything is tracked on GitHub Issues. The project uses **four milestones**
that describe the path from a runnable slice to a verified, accessible game:

| # | Milestone | Due | What lives there |
| --- | --- | --- | --- |
| 2 | Vertical Slice Polish | 2026-07-31 | Finish the Godot 4.4 focus-mode slice: disruptor wiring, chaos overlay, doc + UI cleanup |
| 3 | Sensory Systems | 2026-08-31 | Tune-in audio filter, presence-driven world listeners, deeper clue resolution |
| 4 | Narrative & World | 2026-09-30 | The "sensory crime" investigation loop + antagonist-as-chaos lore |
| 5 | Accessibility Audit | 2026-10-31 | Colorblind-safe palette, input remapping, audio captions, full neurodivergent playtest |

Issues are organized as a **parent/child tree** (sub-issues): each milestone has
one "epic" issue that parents the others, so the sidebar shows the relationships.
Dependency *badges* (blocked-by) aren't enabled on this repo tier, so the
dependency story is written into each issue's `## Relationships` section in
words — read those before starting work.

### Labels

Custom labels (the rest are GitHub defaults):

- `enhancement` — new feature or system.
- `accessibility` — serves the sensory-justice theme. On essentially every
  issue, because the whole game is that.
- `architecture` — clean, decoupled, signal-driven code. Used on the code
  systems, not the narrative/audit issues.
- `documentation` — doc additions or fixes (e.g. `WIRING.md` reconciliation).

GitHub defaults (`bug`, `duplicate`, `good first issue`, `help wanted`,
`invalid`, `question`, `wontfix`) are used as their names say.

### Assignees

Issues are intentionally left **unassigned** until someone picks them up — grab
one, assign yourself, and move. There's no auto-assignment.

## Architecture in brief

The game is **signal-driven, not tree-scanning**. `FocusModeMain` owns
references to its components (`stim`, `focus`, `meter`) and connects to their
signals; children never reach up the tree to find a parent. Two signals carry
the whole emotional model:

- `rhythm_pulse` (from `StimTool`) raises `presence` — the player's calm leaks
  into the room.
- `chaos_pulse` (from `Disruptor`) raises `chaos`, which jitters the beat and
  throttles how much calm reaches the world.

For the full picture, see [ARCHITECTURE.md](ARCHITECTURE.md). For the player-
facing overview, see [README.md](README.md).

## Prototype vs engine

- `vertical-slice/godot/` — the real Godot 4.4 vertical slice. Run
  `scenes/focus_mode.tscn` with **F5**.
- `prototype/focus-mode.html` — a single-file, no-build browser prototype (Web
  Audio API). Open it directly. Keep it in sync with the Godot slice's controls
  and audio behaviour when you touch either.

## Code style

- GDScript: typed, signal-driven, `snake_case`, no dead code, no backward-compat
  shims. If a feature isn't used, remove it rather than gate it.
- Battery-conscious: sleep/idle when there's nothing to draw or animate; don't
  poll. The stim pulse is computed from a `cos` wave on the fly — no per-frame
  allocation, no animation-plugin memory.
- Keep the audio texture-free and runtime-light.

## Running the checks

No local builds are required for this repo — push to CI and watch it. Keep the
working tree clean and let CI catch formatting/lint.

## License

By contributing, you agree your contributions are licensed under the MIT
License.
