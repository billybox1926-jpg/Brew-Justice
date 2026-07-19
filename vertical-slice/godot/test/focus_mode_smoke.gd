extends Node
class_name FocusModeSmokeTest

func run() -> Dictionary:
	var result := {
		"passed": true,
		"failures": PackedStringArray(),
		"checks": 0
	}

	var scene_path := "res://scenes/focus_mode.tscn"
	if not ResourceLoader.exists(scene_path):
		result.passed = false
		result.failures.append("Missing scene: %s" % scene_path)
		return result

	var scene := load(scene_path).instantiate()
	if scene == null:
		result.passed = false
		result.failures.append("Failed to instantiate scene")
		return result

	result.checks += 1
	var main := scene
	if main == null:
		result.passed = false
		result.failures.append("Scene root is null")
		return result

	result.checks += 1
	var script_type := main.get_script()
	if script_type == null or not script_type.resource_path.contains("focus_mode_main.gd"):
		result.passed = false
		result.failures.append("Scene root does not use FocusModeMain script")

	result.checks += 1
	var nodes := {
		"Disruptor": scene.find_child("Disruptor", true, false),
		"DisruptionOverlay": scene.find_child("DisruptionOverlay", true, false),
		"ObserverLight": scene.find_child("ObserverLight", true, false),
		"NpcRegular": scene.find_child("NpcRegular", true, false),
		"TireSmudge": scene.find_child("TireSmudge", true, false),
		"TireClue": scene.find_child("TireClue", true, false),
		"AmbientAudio": scene.find_child("AmbientAudio", true, false),
		"SensoryMeterBar": scene.find_child("SensoryMeterBar", true, false),
	}
	for name in nodes.keys():
		result.checks += 1
		if nodes[name] == null:
			result.passed = false
			result.failures.append("Missing node: %s" % name)

	result.checks += 1
	var has_chaos_signal := main.has_signal("reset_requested") and main.has_signal("investigation_passed") and main.has_signal("investigation_blocked")
	if not has_chaos_signal:
		result.passed = false
		result.failures.append("Missing expected FocusModeMain signals")

	var disruptor_node := nodes["Disruptor"] as Node
	if disruptor_node:
		result.checks += 1
		var callable := Callable(main, "_on_chaos")
		if not disruptor_node.is_connected("chaos_pulse", callable):
			result.passed = false
			result.failures.append("chaos_pulse not connected to FocusModeMain._on_chaos")

	var npc_node := nodes["NpcRegular"] as Node
	if npc_node:
		result.checks += 1
		if npc_node.has_signal("speed_changed"):
			var speed_callable := Callable(main, "_update_world_listeners")
			if not npc_node.is_connected("speed_changed", speed_callable):
				result.passed = false
				result.failures.append("NpcRegular.speed_changed not wired to main")

	return result


func _ready() -> void:
	var summary := run()
	print("SMOKE checks=%d passed=%s" % [summary.checks, summary.passed])
	if not summary.passed:
		for msg in summary.failures:
			print("FAIL: %s" % msg)
		get_tree().quit(1)
	else:
		get_tree().quit(0)
