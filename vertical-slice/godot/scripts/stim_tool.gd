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


func release() -> void:
	if !holding:
		return
	holding = false
	var strength := clamp(charge, 0.0, 1.0)
	stim_released.emit(strength)
	charge = 0.0
	cooldown = COOLDOWN_SECONDS


func update(delta: float) -> void:
	if cooldown > 0.0:
		cooldown = max(cooldown - delta, 0.0)
	if holding and cooldown <= 0.0:
		charge = clamp(charge + delta * CHARGE_RATE, 0.0, 1.0)
		# Chaos injects jitter into the beat, breaking entrainment.
		var jitter := randf_range(-1.0, 1.0) * chaos * JITTER_SCALE
		beat_clock += delta * BEAT_RATE * TAU * (1.0 + jitter)
		var beat_now := cos(beat_clock)
		if beat_prev <= 0.0 and beat_now > 0.0:
			# Intensity ramps in over the first ~3 beats, then sustains at 1.0.
			var intensity := clamp(beat_clock / (TAU * RAMP_CYCLES), 0.0, 1.0)
			intensity *= (1.0 - chaos * CHAOS_LEAK_SCALE)  # disrupted calm leaks less into the room
			if intensity > EMISSION_THRESHOLD:
				rhythm_pulse.emit(intensity)
		beat_prev = beat_now
	if chaos > 0.0:
		chaos = max(chaos - delta * CHAOS_DECAY, 0.0)


func disrupt(amount: float) -> void:
	chaos = clamp(chaos + amount, 0.0, 1.0)


func current_charge() -> float:
	return charge
