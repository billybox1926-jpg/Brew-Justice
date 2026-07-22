extends Node2D
class_name NpcRegular

signal speed_changed(speed: float)

const CHAOS_SPEED := 4.0
const CALM_SPEED := 1.8
const STARTLE_MAX_DIST := 12.0
const STARTLE_RECOVER_SEC := 0.35

var animation_player: AnimationPlayer
var _presence: float = 0.0
var _startle_target: Vector2
var _startle_timer: float = 0.0
var _origin: Vector2

func _enter_tree() -> void:
	animation_player = get_node_or_null("AnimationPlayer")
	_origin = position
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


func apply_chaos_spike(intensity: float) -> void:
	_startle_target = _origin + Vector2(randf_range(-STARTLE_MAX_DIST, STARTLE_MAX_DIST), 0.0)
	_startle_timer = STARTLE_RECOVER_SEC
	if animation_player and animation_player.has_animation("startled"):
		animation_player.play("startled")
		animation_player.speed_scale = CHAOS_SPEED


func apply_chaos_if_supported(chaos_value: float) -> void:
	if chaos_value >= 0.25:
		apply_chaos_spike(chaos_value)


func _process(delta: float) -> void:
	if _startle_timer > 0.0:
		_startle_timer = max(_startle_timer - delta, 0.0)
		var t := 1.0 - (_startle_timer / STARTLE_RECOVER_SEC)
		position = _origin.lerp(_startle_target, 1.0 - t)
		if _startle_timer <= 0.0:
			position = _origin
			if animation_player and animation_player.has_animation("tap"):
				animation_player.play("tap")
				animation_player.speed_scale = lerp(CHAOS_SPEED, CALM_SPEED, smoothstep(0.0, 1.0, _presence))

