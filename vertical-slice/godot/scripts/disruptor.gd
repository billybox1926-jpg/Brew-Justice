class_name Disruptor
extends Node

# Variant-driven antagonist disruption emitter.
# Emits chaos_pulse(STENGTH) for backward compat,
# or chaos_pulse(intensity, duration, band) when a variant is assigned.

signal chaos_pulse(strength: float)
signal chaos_pulse_rich(strength: float, duration: float, band: String)

# Design note: auto-fire is opt-in to avoid surprising players during testing/scenes.
# Review feedback: change default to false.
@export var auto_fire: bool = false
@export var variant: DisruptorVariant

# Built-in timer so scenes don't need to add one manually.
var _timer: Timer
var _active: bool = false


func _ready() -> void:
	if not _timer:
		_timer = Timer.new()
		add_child(_timer)
	_timer.timeout.connect(_on_timer_timeout)
	_apply_variant()
	if auto_fire:
		start()


func _apply_variant() -> void:
	if not variant:
		push_warning("Disruptor: no variant assigned — chaos pulses will be absent.")
		return
	_timer.wait_time = variant.interval


func start() -> void:
	_active = true
	_timer.start()


func stop() -> void:
	_active = false
	_timer.stop()


func trigger_pulse() -> void:
	if not variant:
		return
	chaos_pulse.emit(variant.intensity)
	chaos_pulse_rich.emit(variant.intensity, variant.duration, variant.auditory_band)


func set_variant(new_variant: DisruptorVariant) -> void:
	variant = new_variant
	if is_inside_tree():
		_apply_variant()


func _on_timer_timeout() -> void:
	trigger_pulse()


func set_variant(new_variant: DisruptorVariant) -> void:
	variant = new_variant
	if is_inside_tree():
		_apply_variant()


func is_active() -> bool:
	return _active
