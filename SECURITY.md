# Security Policy

## Scope

Brew & Justice is a cozy single-player game (Godot 4.4 vertical slice + a
browser prototype). There is no server, no network calls, and no account data.
The realistic risk surface is small: supply-chain (dependencies), and anything
in the build/release pipeline if one is added later.

## Reporting a vulnerability

If you find something, **please don't open a public issue.** Report it
privately:

- Open a **private** GitHub security advisory on the repo
  (`Security` tab → `Report a vulnerability`), or
- DM the maintainer (`billybox1926-jpg`).

Give us a way to reproduce it and we'll triage quickly. We'll credit you in the
fix unless you'd prefer to stay anonymous.

## Supported versions

Only the latest commit on `main` is supported. This is a pre-1.0 project; there
are no back-ported fixes to older snapshots.

## Hardening notes for contributors

- Keep the audio bed **pink noise, not white** (see `fe846c6`) — white noise is
  a known sensory-harm trigger and has no place in this game.
- Avoid flashing/rapid state changes. Any new visual that pulses should ease,
  not snap, and should respect the colorblind-safe tokens.
- Don't introduce runtime dependencies without discussing it; the slice is
  intentionally texture-free and dependency-light.
