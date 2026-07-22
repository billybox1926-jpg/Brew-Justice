extends Resource
class_name ColorPalette

## Central color definitions for Brew & Justice visual states.
## Each semantic color has a standard and colorblind-safe variant.
## Systems should prefer named accesses over raw Color literals so
## colorblind toggles can swap the whole palette at once.

@export var calm: Color = Color(0.3, 0.6, 0.9)
@export var overload: Color = Color(0.9, 0.3, 0.2)
@export var trail: Color = Color(0.82, 0.62, 0.18)
@export var clue_resolved: Color = Color(0.2, 0.8, 0.4)
@export var clue_red_herring: Color = Color(0.5, 0.5, 0.5)
@export var chaos_pulse: Color = Color(1.0, 0.6, 0.2)
@export var vignette_tint: Color = Color(0.18, 0.08, 0.04)
@export var neon_edge: Color = Color(0.0, 0.94, 1.0)
@export var bind_highlight: Color = Color(1.0, 0.9, 0.6)

@export var cb_calm: Color = Color(0.9, 0.7, 0.3)
@export var cb_overload: Color = Color(0.1, 0.6, 0.9)
@export var cb_trail: Color = Color(1.0, 0.95, 0.45)
@export var cb_clue_resolved: Color = Color(0.95, 0.85, 0.1)
@export var cb_clue_red_herring: Color = Color(0.6, 0.6, 0.6)
@export var cb_chaos_pulse: Color = Color(0.2, 0.8, 0.8)
@export var cb_vignette_tint: Color = Color(0.15, 0.12, 0.08)
@export var cb_neon_edge: Color = Color(0.1, 0.6, 0.9)
@export var cb_bind_highlight: Color = Color(1.0, 0.9, 0.6)


func color_for(name: String, colorblind: bool) -> Color:
	var key := ("cb_" if colorblind else "") + name
	match key:
		"calm": return calm
		"overload": return overload
		"trail": return trail
		"clue_resolved": return clue_resolved
		"clue_red_herring": return clue_red_herring
		"chaos_pulse": return chaos_pulse
		"vignette_tint": return vignette_tint
		"neon_edge": return neon_edge
		"bind_highlight": return bind_highlight
		"cb_calm": return cb_calm
		"cb_overload": return cb_overload
		"cb_trail": return cb_trail
		"cb_clue_resolved": return cb_clue_resolved
		"cb_clue_red_herring": return cb_clue_red_herring
		"cb_chaos_pulse": return cb_chaos_pulse
		"cb_vignette_tint": return cb_vignette_tint
		"cb_neon_edge": return cb_neon_edge
		"cb_bind_highlight": return cb_bind_highlight
		_: return Color.WHITE
