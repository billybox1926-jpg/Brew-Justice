extends GutTest

var scene: Node
var disruptor: Node
var overlay: DisruptionOverlay
var observer_light: ObserverLight
var npc: NpcRegular
var main: Control
var ambient: AudioStreamPlayer2D

func before_each():
	scene = load("res://scenes/focus_mode.tscn").instantiate()
	add_child_autofree(scene)
	main = scene
	disruptor = scene.find_child("Disruptor", true, false)
	overlay = scene.find_child("DisruptionOverlay", true, false) as DisruptionOverlay
	observer_light = scene.find_child("ObserverLight", true, false) as ObserverLight
	npc = scene.find_child("NpcRegular", true, false) as NpcRegular
	ambient = scene.find_child("AmbientAudio", true, false) as AudioStreamPlayer2D


func test_nodes_exist():
	assert_not_null(main, "FocusModeMain should exist")
	assert_not_null(disruptor, "Disruptor node should exist")
	assert_not_null(overlay, "DisruptionOverlay should exist")
	assert_not_null(observer_light, "ObserverLight should exist")
	assert_not_null(npc, "NpcRegular should exist")
	assert_not_null(ambient, "AmbientAudio should exist")
	assert_true(ambient.stream != null, "Ambient stream should be assigned at runtime")


func test_signal_connections():
	assert_true(main.has_signal("reset_requested"), "reset_requested signal missing")
	assert_true(main.has_signal("investigation_passed"), "investigation_passed signal missing")
	assert_true(main.has_signal("world_listeners_updated"), "world_listeners_updated signal missing")
	assert_true(main.has_signal("calm_changed"), "calm_changed signal missing")

	if disruptor:
		var target = Callable(main, "_on_chaos")
		assert_true(disruptor.is_connected("chaos_pulse", target), "chaos_pulse should be connected to _on_chaos")

	if observer_light:
		if observer_light.has_signal("tuned_in"):
			var target_light = Callable(main, "_update_world_listeners")
			assert_true(observer_light.is_connected("tuned_in", target_light), "tuned_in should be connected to _update_world_listeners")


func test_signal_triggers_reaction():
	if not disruptor or not overlay:
		return
	var before_edges := overlay.get("chaos")
	disruptor.chaos_pulse.emit(0.5)
	await wait_frames(2)
	var after_edges := overlay.get("chaos")
	assert_true(after_edges > before_edges, "Chaos pulse should increase overlay chaos")
