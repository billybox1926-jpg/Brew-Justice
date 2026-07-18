extends Node
class_name Disruptor

# A sensory-static source. Emits chaos_pulse on an interval so the world can
# quietly destabilize the player's rhythm. Wire its chaos_pulse to
# FocusModeMain._on_chaos in the scene, or call fire() from gameplay code.

signal chaos_pulse(strength: float)

var auto_fire := true
var min_interval := 4.0
var max_interval := 7.0
var min_strength := 0.3
var max_strength := 0.6
var _timer := 0.0

func _ready() -> void:
	_timer = randf_range(min_interval, max_interval)

func _process(delta: float) -> void:
	if not auto_fire:
		return
	_timer -= delta
	if _timer <= 0.0:
		_timer = randf_range(min_interval, max_interval)
		fire()

func fire() -> void:
	chaos_pulse.emit(randf_range(min_strength, max_strength))
