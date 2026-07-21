class_name Disruptor
extends Node

# Variant-driven antagonist disruption emitter.
# Emits chaos_pulse(STENGTH) for backward compat,
# or chaos_pulse(intensity, duration, band) when a variant is assigned.

signal chaos_pulse(strength: float)
signal chaos_pulse_rich(strength: float, duration: float, band: String)
signal profile_activated(profile: DisruptorProfile)

# Design note: auto-fire is opt-in to avoid surprising players during testing/scenes.
@export var auto_fire: bool = false
@export var variant: DisruptorVariant
@export var profile: DisruptorProfile

# Built-in timer so scenes don't need to add one manually.
var _timer: Timer
var _active: bool = false
var _next_pulse_strength: float = 0.5


func _ready() -> void:
	if not _timer:
		_timer = Timer.new()
		add_child(_timer)
	_timer.timeout.connect(_on_timer_timeout)
	_apply_profile()
	if variant:
		_apply_variant()
	if auto_fire:
		start()


func _apply_variant() -> void:
	if not variant:
		push_warning("Disruptor: no variant assigned — chaos pulses will be absent.")
		return
	_timer.wait_time = variant.interval
	var style := ""
	if profile:
		style = profile.chaos_style
	_next_pulse_strength = _style_strength(style, variant.intensity)
	if profile:
		profile_activated.emit(profile)


func _style_strength(style: String, base: float) -> float:
	match style:
		"pulse": return base
		"drift": return base * 0.7
		"burst": return base * 1.4
		"wave": return base * (0.6 + 0.4 * sin(Time.get_ticks_msec() / 1000.0))
		return base


func _apply_profile() -> void:
	if not profile:
		return
	if profile.chaos_style != "":
		pass
	profile_activated.emit(profile)


func start() -> void:
	_active = true
	_timer.start()


func stop() -> void:
	_active = false
	_timer.stop()


func trigger_pulse() -> void:
	if not variant:
		return
	var strength := _next_pulse_strength
	chaos_pulse.emit(strength)
	chaos_pulse_rich.emit(variant.intensity, variant.duration, variant.auditory_band)


func set_variant(new_variant: DisruptorVariant) -> void:
	variant = new_variant
	if is_inside_tree():
		_apply_variant()


func set_profile(new_profile: DisruptorProfile) -> void:
	profile = new_profile
	if is_inside_tree():
		_apply_profile()


func _on_timer_timeout() -> void:
	trigger_pulse()


func is_active() -> bool:
	return _active
