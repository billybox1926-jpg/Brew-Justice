# RTL language support — investigation & follow-up plan

Findings from auditing the vertical slice's UI for
right-to-left readiness (issue #53), plus the work needed before an RTL
locale (Arabic, Hebrew, Persian) could ship. This is a **plan**, not
implemented support.

## Background: what Godot gives us

Godot 4 has built-in RTL support at the text-server level: automatic
bidi reordering, Arabic/Shaping via ICU, and per-control
`text_direction` (`TEXT_DIRECTION_AUTO` detects script per string) plus
`structured_text_bidi_override` for complex cases. Crucially,
**`Control.layout_direction`** mirrors a control's anchoring/alignment
without touching anchors, and `TranslationServer.set_locale()` to an RTL
locale does **not** flip layout automatically — layout mirroring is
opt-in per control or by setting `layout_direction` explicitly. So the
framework exists; our UI just doesn't use it yet.

## Audit: current UI layout assumptions

| Component | File | Layout method | RTL risk |
| --- | --- | --- | --- |
| StateLabel | `scenes/focus_mode.tscn` | `anchors_preset = 4` (center-left), fixed offsets | **Low** — centered-ish text block; alignment follows text direction automatically |
| SensoryLabel | `scenes/focus_mode.tscn` | preset 1 (top-left), fixed offsets 96..320px | **Medium** — pinned left; in RTL should pin right |
| Caption label | `_setup_captions()` | anchor_left/right = 0.5, symmetric ±320px, center alignment | **Low** — symmetric around center; center alignment is direction-neutral |
| Insight label (InvestigationUI) | `investigation_ui.gd` | `PRESET_CENTER`, center alignment | **Low** |
| Calibration prompt | `sensory_calibration.gd` | `PRESET_CENTER`, center alignment | **Low** |
| BeatPulsar ring | `beat_pulsar.gd` | `PRESET_CENTER_TOP`, symmetric ±60px | **None** — non-textual indicator |
| Focus fade / overlays | `focus_transition_fade.gd`, disruption overlay | full-rect | **None** |

### Text-content risks (the real work)

1. **Composite status strings are assembled LTR.** The state line is
   built as `"%s · %s%s — %.0f%%" % [focus_text, mode, chaos_note,
   sensory]` (focus_mode_main.gd ~line 977). In an RTL locale the
   segments would render in the wrong order because the format string
   itself fixes the visual order. These need to become single
   translatable messages with named placeholders
   (`L10n.t("LABEL_STATE", [...])`) so each locale controls segment
   order — same pattern already used for `LABEL_SENSORY_LOAD`.
2. **The `%s · %s — %.0f%%` separator convention** (middle dot, em
   dash) is punctuation with directional behavior in bidi text; it must
   live inside the translation strings, not in code.
3. **No `text_direction` is set anywhere** (grep confirms zero uses).
   Defaults to LTR. Fine while only LTR locales ship; must be set to
   `TEXT_DIRECTION_AUTO` on all labels before enabling an RTL locale.
4. **Numbers**: percent values use `%.0f` with Western digits. Godot's
   text server handles digit substitution when the font supports it;
   verify chosen fonts include Arabic-Indic digit glyphs.
5. **Fonts**: current project uses default fonts. Arabic/Persian/Hebrew
   shaping requires a font with those glyph sets (e.g. Noto Sans Arabic)
   added as fallbacks, or text renders as boxes.

## Follow-up plan (in order)

1. **Convert composite strings to keyed messages** (~1 hr). Replace the
   three hand-formatted state-line variants with `LABEL_STATE_*` entries
   in `translations.csv`; add es translations as the second-locale proof.
2. **Set `text_direction = TEXT_DIRECTION_AUTO`** on every Label and
   RichTextLabel (StateLabel, SensoryLabel, caption, insight,
   calibration, any future ones). Mechanical, low-risk; can land before
   any RTL locale exists.
3. **Add an RTL smoke check** to `test_l10n.gd`: set locale to a test RTL
   locale (add a stub column), assert no parse errors and that
   `text_direction` resolves to RTL on labeled controls.
4. **Pin SensoryLabel right in RTL**: either switch it to
   `layout_direction = BIDI_LAYOUT_DIRECTION_LOCALE` (auto-mirrors) or
   move it into a container. Prefer the former; one line.
5. **Font fallback pass** (blocking for real RTL shipping): add Noto
   Sans Arabic / Hebrew fallback fonts to the theme.
6. **Manual visual QA** with a real RTL locale on desktop + web exports
   (web was where font rendering differed historically).

Items 1–2 are safe to do now and keep the LTR UI pixel-identical.
Item 3 makes regressions visible. Items 4–6 gate actual RTL release,
not this refactor.

## Known gaps

- No RTL locale ships today; nothing above has been visually verified
  against rendered Arabic/Hebrew text.
- Web export font behavior not audited (needs item 6).
- The evidence-board insight composition ("Combined: X + Y") is keyed
  but its per-clue names come from resources — those resource strings
  are outside the translation CSV and would need their own pass if clue
  names are ever translated.
