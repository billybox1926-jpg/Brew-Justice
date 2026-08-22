extends SceneTree

## Demo choreography for the README preview (issue #39).
## SceneTree-root driver for Movie Maker capture. Drives the real scene
## through its showcase beats while Godot renders offline frames.
##
## Beats (all driven through the game's own input actions, no shortcuts):
##   0.0-2.5s  baseline room, rain, meter idle
##   2.5-5.0s  rhythmic stim (Space held, released) -> load drops, pulse rings
##   5.0-6.5s  focus toggle (F) -> periphery dims, clue brightens
##   6.5-8.0s  chaos spike via Disruptor.trigger_pulse() -> jitter + overlay
##   8.0-10.5s calm again, focus off, trail proximity sweep toward the tire

var _scene: Node
var _t := 0.0


func _initialize() -> void:
	var packed: PackedScene = load("res://scenes/focus_mode.tscn")
	_scene = packed.instantiate()
	root.add_child(_scene)


func _press(action: String) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = true
	Input.parse_input_event(ev)


func _release(action: String) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = false
	Input.parse_input_event(ev)


func _process(delta: float) -> bool:
	_t += delta

	match _t:
		2.5:
			_press("stim_hold")
		4.6:
			_release("stim_hold")
		5.0:
			_press("focus_toggle")
			root.get_tree().create_timer(0.1).timeout.connect(
				func() -> void: _release("focus_toggle")
			)
		6.3:
			var disruptor := _scene.find_child("Disruptor", true, false)
			if disruptor and disruptor.has_method("trigger_pulse"):
				disruptor.trigger_pulse()
		7.2:
			_press("focus_toggle")
			root.get_tree().create_timer(0.1).timeout.connect(
				func() -> void: _release("focus_toggle")
			)
		8.5:
			var canvas := _scene.find_child("SensoryCanvas", true, false)
			if canvas:
				canvas.set_trail_target(Vector2(640, 500))
		10.5:
			print("DEMO_DONE")
			return true
	return false

	if _t > 8.0 and int(_t * 10.0) % 5 == 0:
		var canvas := _scene.find_child("SensoryCanvas", true, false)
		if canvas:
			var x := 400.0 + 300.0 * sin(_t * 1.1)
			canvas.set_trail_target(Vector2(x, 480.0 + 40.0 * cos(_t * 0.9)))
