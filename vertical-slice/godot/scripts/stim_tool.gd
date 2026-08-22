extends Node
class_name StimTool

signal stim_released(strength: float)
signal rhythm_pulse(intensity: float)

var holding := false
var charge := 0.0
var cooldown := 0.0

# Rhythm clock — emits one rhythm_pulse per calm beat cycle while held.
const BEAT_RATE := 1.8  # cycles/sec, near a resting heart rate
const CHARGE_RATE := 0.55
const JITTER_SCALE := 0.6
const RAMP_CYCLES := 3.0
const CHAOS_LEAK_SCALE := 0.8
const EMISSION_THRESHOLD := 0.02
const CHAOS_DECAY := 0.25
const COOLDOWN_SECONDS := 0.45

## Rhythm tolerance (issue #47). Generous mode widens the timing windows:
## chaos jitter is damped (beats stay steadier under disruption) and the
## pulse intensity floor drops so softer/off-beat holds still register.
const GENEROUS_JITTER_SCALE := 0.3
const GENEROUS_EMISSION_THRESHOLD := 0.005
const GENEROUS_COOLDOWN_SECONDS := 0.2

var beat_clock := 0.0
var beat_prev := 1.0
var chaos := 0.0  # sensory static; raised by disruptors, decays on its own


func press() -> void:
	if cooldown > 0.0:
		return
	holding = true
	charge = 0.0
	beat_clock = 0.0
	beat_prev = 1.0


## Rhythm tolerance mode from preferences (issue #47): "strict" or "generous".
var timing_mode := "strict"


func _is_generous() -> bool:
	return timing_mode == "generous"


func release() -> void:
	if !holding:
		return
	holding = false
	var strength: float = clampf(charge, 0.0, 1.0)
	stim_released.emit(strength)
	charge = 0.0
	# Generous mode shortens the re-press lockout so mistimed releases can be
	# immediately retried without losing the rhythm.
	cooldown = GENEROUS_COOLDOWN_SECONDS if _is_generous() else COOLDOWN_SECONDS


func update(delta: float) -> void:
	if cooldown > 0.0:
		cooldown = max(cooldown - delta, 0.0)
	if holding and cooldown <= 0.0:
		charge = clamp(charge + delta * CHARGE_RATE, 0.0, 1.0)
		# Chaos injects jitter into the beat, breaking entrainment. Generous
		# mode damps the jitter so the beat stays followable under disruption.
		var jitter_scale: float = GENEROUS_JITTER_SCALE if _is_generous() else JITTER_SCALE
		var jitter := randf_range(-1.0, 1.0) * chaos * jitter_scale
		beat_clock += delta * BEAT_RATE * TAU * (1.0 + jitter)
		var beat_now := cos(beat_clock)
		if beat_prev <= 0.0 and beat_now > 0.0:
			# Intensity ramps in over the first ~3 beats, then sustains at 1.0.
			var intensity: float = clampf(beat_clock / (TAU * RAMP_CYCLES), 0.0, 1.0)
			intensity *= (1.0 - chaos * CHAOS_LEAK_SCALE)  # disrupted calm leaks less into the room
			var threshold: float = (
				GENEROUS_EMISSION_THRESHOLD if _is_generous() else EMISSION_THRESHOLD
			)
			if intensity > threshold:
				rhythm_pulse.emit(intensity)
		beat_prev = beat_now
	if chaos > 0.0:
		chaos = max(chaos - delta * CHAOS_DECAY, 0.0)


func disrupt(amount: float) -> void:
	chaos = clamp(chaos + amount, 0.0, 1.0)


func current_charge() -> float:
	return charge
