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
	_setup_placeholder_animation()


func _setup_placeholder_animation() -> void:
	if not animation_player:
		return
	var library := animation_player.get_animation_library("")
	if library and library.has_animation("tap"):
		return

	var anim := Animation.new()
	anim.length = 0.5
	anim.loop_mode = Animation.LOOP_LINEAR

	var target_path := "NpcSprite" if has_node("NpcSprite") else "."
	var track_idx := anim.add_track(Animation.TYPE_POSITION)
	anim.track_set_path(track_idx, target_path)

	anim.track_insert_key(track_idx, 0.0, Vector2(0.0, 0.0))
	anim.track_insert_key(track_idx, 0.25, Vector2(0.0, -10.0))
	anim.track_insert_key(track_idx, 0.5, Vector2(0.0, 0.0))

	var lib := AnimationLibrary.new()
	lib.add_animation("tap", anim)
	animation_player.add_animation_library("", lib)
	animation_player.play("tap")

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

