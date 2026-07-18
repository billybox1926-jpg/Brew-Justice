#!/usr/bin/env bash
# Creates Brew-Justice milestones + seeded issues via the GitHub API.
# Run after authenticating:  gh auth login -h github.com
set -euo pipefail

REPO="$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null || echo "billybox1926-jpg/Brew-Justice")"
API="https://api.github.com/repos/${REPO}"

# milestone <title> <description> <due_on YYYY-MM-DD>
create_milestone() {
  local title="$1" desc="$2" due="$3"
  gh api -X POST "${API}/milestones" \
    -f title="$title" \
    -f description="$desc" \
    -f due_on="${due}T23:59:59Z" \
    -f state=open \
    | python -c "import sys,json;print(json.load(sys.stdin)['number'])"
}

# issue <milestone_number> <title> <body>
create_issue() {
  local ms="$1" title="$2" body="$3"
  gh api -X POST "${API}/issues" \
    -f title="$title" \
    -f body="$body" \
    -F milestone="$ms" \
    | python -c "import sys,json;d=json.load(sys.stdin);print('#%s %s' % (d['number'], d['title']))"
}

echo "Target repo: ${REPO}"

MS_POLISH=$(create_milestone "Vertical Slice Polish" "Wrap up the Godot 4.4 focus-mode slice: disruptor wiring, chaos overlay, doc + UI cleanup." "2026-07-31")
MS_SYS=$(create_milestone "Sensory Systems" "Expand the core mechanics: tune-in audio filter, presence-driven world listeners, deeper clue resolution." "2026-08-31")
MS_NARR=$(create_milestone "Narrative & World" "Define the coffee-detective 'sensory crime' investigation loop and the antagonist-as-chaos lore." "2026-09-30")
MS_ACC=$(create_milestone "Accessibility Audit" "Colorblind-safe palette, input remapping, audio-cue captions, full neurodivergent playtest." "2026-10-31")

echo "Milestones: polish=$MS_POLISH sys=$MS_SYS narr=$MS_NARR acc=$MS_ACC"

create_issue "$MS_POLISH" "Add neon-flicker disruption overlay driven by chaos" "Create disruption_overlay.gd (Control node) that reads chaos and draws a faint, jittery neon edge in _draw(), sleeping when chaos == 0. Wire it to FocusModeMain.chaos. Keep it texture-free and battery-conscious. (Sketched earlier; fix the static-y flicker by offsetting the drawn y by the flicker value, not just alpha.)"

create_issue "$MS_POLISH" "Connect Disruptor node to a scene + tune intervals" "disruptor.gd exists but is inert. Add it to focus_mode.tscn (or a test scene), connect chaos_pulse -> FocusModeMain._on_chaos, and tune min/max interval + strength to feel like an external disruption rather than constant noise."

create_issue "$MS_POLISH" "Reconcile WIRING.md with runtime audio bus setup" "WIRING.md step 3 tells the user to confirm the SFX bus + LowPass/HighPass exist in Project Settings. focus_mode_main.gd already creates that bus and both effects at runtime (_setup_audio). Pick one source of truth: delete step 3 or delete the runtime creation."

create_issue "$MS_POLISH" "Surface chaos + C-key in on-screen UI and README" "The C key injects a chaos spike but nothing on-screen says so. Add a small legend/hint near StateLabel and note C in the README controls table."

create_issue "$MS_SYS" "Add AudioEffectBandPassFilter 'tune-in' to SFX bus" "Add a bandpass filter on the SFX bus; on focus, narrow its cutoff/resonance onto a target voice instead of just muffling everything. This is the 'isolate one cafe conversation' mechanic. Reuse the existing frame-budget exp-glide approach in _lerp_audio."

create_issue "$MS_SYS" "Presence-driven world listeners (light + npc)" "Wire the rhythm_pulse signal to ambient_light.gd (warm the lamp color via tween) and npc_regular.gd (slow the regular's tap anim 4.0 -> 1.8). Connect through FocusModeMain.stim, not tree-scanning. Models co-regulation: the player's calm settles the room."

create_issue "$MS_SYS" "Deepen smudge -> neon clue resolution" "Tire smudge/clue are static markers today. Make the smudge clear and the neon clue resolve as a function of presence/focus so the 'before/after' reads as earned investigation, not a fixed toggle."

create_issue "$MS_NARR" "Define the first 'sensory crime' investigation loop" "A mystery where the antagonist's weapon is destabilizing the sensory environment (chaos) to prevent the detective from thinking. The shield is rhythm. Draft the beat: observe -> overload -> stim to regulate -> tune-in to a clue -> resolve."

create_issue "$MS_NARR" "Antagonist-as-chaos lore + Disruptor variants" "Give the disruptor(s) narrative identity: who emits sensory static and why. Differentiate chaos sources (neon flicker vs hostile patron vs weather) with distinct strength/decay profiles."

create_issue "$MS_ACC" "Colorblind-safe palette verification across states" "Walk Baseline/Hyperfocus/Overload and confirm the state colors are distinguishable without relying on hue alone. Already using _stl_colorblind_safe for the label; extend to vignette/clue/trail."

create_issue "$MS_ACC" "Input remapping + audio-cue captions" "Expose focus_toggle / stim_hold / reset in an in-game remap UI, and caption audio-filter state changes (e.g. 'focus: highs cut') so the soundscape is legible without hearing it."

echo "Done. Open: https://github.com/${REPO}/milestones"
