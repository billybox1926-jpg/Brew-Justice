extends Node
class_name StoryBeat

## Lightweight narrative trigger: listens for a specific sensory-crime phase
## and activates a Disruptor variant for the story beat.

signal beat_started(beat_name: String)
signal beat_ended(beat_name: String)

## Friendly name for this beat (used in lore log / future UI).
@export var beat_name: String = ""

## Which loop phase activates this beat.
@export var target_phase: int = -1

## Optional fallback phase if the target phase is missed during dynamic transitions.
@export var fallback_phase: int = -1

## The disruptor this beat controls.
@export var disruptor: Disruptor

## Variant assigned when the beat starts. If null, the beat starts the
## disruptor with whatever variant is already assigned.
@export var variant_on_start: DisruptorVariant

## If true and the beat starts during the wrong phase, retry next phase change.
@export var retry_until_triggered: bool = false

var _active: bool = false
var _last_phase: int = -1

func _ready() -> void:
	if not disruptor:
		push_warning("StoryBeat: no Disruptor assigned for beat '%s'" % beat_name)


func on_phase_changed(from: int, to: int) -> void:
	_last_phase = to
	if _active:
		if to == target_phase:
			# Stay active while loop remains in the target phase.
			return
		if should_end(to):
			end_beat()
		return
	if to == target_phase or (retry_until_triggered and from == target_phase):
		start_beat()


func start_beat() -> void:
	if _active or not disruptor:
		return
	_active = true
	if variant_on_start:
		disruptor.set_variant(variant_on_start)
	disruptor.auto_fire = true
	disruptor.start()
	beat_started.emit(beat_name)


func end_beat() -> void:
	if not _active or not disruptor:
		return
	_active = false
	disruptor.stop()
	disruptor.auto_fire = false
	beat_ended.emit(beat_name)


func force_stop() -> void:
	end_beat()


func is_active() -> bool:
	return _active


func last_seen_phase() -> int:
	return _last_phase


func should_end(next_phase: int) -> bool:
	# Default implementation: end when we leave the target phase.
	return next_phase != target_phase
