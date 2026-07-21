extends Node2D
class_name NpcRegular

signal speed_changed(speed: float)

const CHAOS_SPEED := 4.0
const CALM_SPEED := 1.8

var animation_player: AnimationPlayer
var _presence: float = 0.0

func _enter_tree() -> void:
	animation_player = get_node_or_null("AnimationPlayer")
	if animation_player:
		animation_player.speed_scale = CALM_SPEED

func apply_presence(value: float) -> void:
	_presence = clamp(value, 0.0, 1.0)
	var calm := smoothstep(0.0, 1.0, _presence)

	if has_node("AnimationTree") and $AnimationTree.active:
		$AnimationTree.set("parameters/calm", calm)
		if animation_player and animation_player.speed_scale != 1.0:
			animation_player.speed_scale = 1.0
	else:
		var new_speed := lerp(CHAOS_SPEED, CALM_SPEED, calm)
		if animation_player:
			animation_player.speed_scale = new_speed
		speed_changed.emit(new_speed)

