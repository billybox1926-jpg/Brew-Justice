extends Node2D
class_name NpcRegular

signal speed_changed(speed: float)

@export var idle_speed := 1.8
@export var stressed_speed := 4.0

var animation_player: AnimationPlayer

func _enter_tree() -> void:
	animation_player = get_node_or_null("AnimationPlayer")
	if animation_player:
		animation_player.speed_scale = idle_speed


func apply_presence(presence: float) -> void:
	var t := smoothstep(0.0, 1.0, clamp(presence, 0.0, 1.0))
	var new_speed := lerp(stressed_speed, idle_speed, t)
	if animation_player:
		animation_player.speed_scale = new_speed
	speed_changed.emit(new_speed)
