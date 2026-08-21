# Neurodivergent playtest protocol

How Brew & Justice runs playtests with neurodivergent participants (issue #62,
milestone: Accessibility Audit). The goal is feedback that is honest, low-risk,
and actionable — collected in a way that does not turn "telling us how the
game treats your nervous system" into a burden on the person giving that
information.

**Prerequisite:** sessions run only against a representative build — after
#57 (Persistence), #60 (Gamepad/controller input), and #61 (Build pipeline)
are delivered. A build that loses settings or input coverage mid-session
invalidates the sensory-load observations.

## Principles

1. **Nothing about us without us.** The protocol itself should be revisited
   with past participants before major revisions ship.
2. **Participation is regulation-friendly by design.** Breaks are scheduled,
   not requested. Leaving early is a complete, uncomplicated outcome.
3. **No diagnosis talk.** We collect observations about the *game*, never
   about the participant's neurotype, medication, or clinical history. See
   "Data minimization" below.
4. **Withdrawal without explanation.** A participant may withdraw at any
   point, including after the session, and their data is deleted on request
   with no questions asked.

## Eligibility guidance

- Open to anyone 18+ who self-identifies as neurodivergent (self-ID is the
  only criterion; no disclosure of any specific condition is requested or
  recorded).
- Participants under 18 are out of scope for this protocol — a separate
  guardian-consent protocol would be required first.
- Participants may bring a support person, and the support person may stay
  for the whole session.
- No prior familiarity with the game is required; first-contact sessions are
  the most valuable and are actively sought.
- Sessions are remote or in-person at the participant's choice; the
  participant chooses the time of day (sensory load varies across a day, and
  we want them at their typical play time, not ours).

## Data collected

| Collected | Not collected |
|---|---|
| Session observations (what happened on screen, when) | Diagnosis, medication, therapy details |
| Participant's own words about load, comfort, and friction | Self-ratings of the participant's neurotype |
| Build hash, platform, input device used | Contact details beyond the participant's chosen channel |
| Session audio/video **only with explicit per-session opt-in** | Anything from a participant's home visible in background |

The participant receives a copy of everything recorded about them and can
correct or strike anything before it is stored.

## Data minimization

Collect the least that answers the question. Every field in the feedback
template maps to a design decision; if a field doesn't, it is removed. Raw
notes are pseudonymized (participant code, e.g. `ND-07`) before they leave
the session notes; the code-to-identity link is kept only until the
participant confirms their copy of the record, then deleted.

## Session structure (60 minutes, participant-paced)

| Time | Segment |
|---|---|
| 0–10 | Welcome, walk through this protocol together, consent confirmation, sensory environment check (volume, screen distance, lighting) |
| 10–15 | Unstructured first contact — just play; moderator silent |
| 15–30 | Guided play on one system (e.g. rhythmic stim loop); think-aloud optional, never required |
| 30–40 | **Break.** Scheduled regardless of whether the participant seems to need it |
| 40–50 | Second play segment, optionally a different input device or settings configuration |
| 50–60 | Debrief using the feedback template (below); participant reviews and approves the session record |

The moderator may compress segments if the participant is engaged and
flowing; may extend breaks indefinitely; and ends the session immediately at
any sign of sustained distress, without needing to justify it.

### Moderator conduct

- Announce every change before it happens ("I'm going to ask about the sound
  now").
- Never ask "why" about a person's response — ask "what did the game do
  right before that."
- Offer written alternatives to verbal answers at every step.
- Do not fill silences. Silence is processing, not a problem.

## Storage expectations

- Session records live in the private `playtest-records` location (not this
  public repo) until pseudonymized.
- Only pseudonymized, participant-approved summaries are published, e.g. in
  the accessibility audit report. Quotes are used only with separate,
  explicit permission.
- Records are kept at most 12 months, then deleted; participants may request
  earlier deletion at any time through the channel they were recruited on.
- The code-to-identity link, where one exists, is stored apart from session
  data.
- Moderators do not discuss identifiable session content outside the
  moderation team.

## Feedback loop

After each round of sessions: summarize pseudonymized findings into issues
(labeled `accessibility`), note protocol friction in this document, and
invite past participants to review the summary before it is published.
