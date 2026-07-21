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


func test_npc_regular_fallback_speed_scale() -> void:
	var scene = load("res://scenes/focus_mode.tscn").instantiate()
	var npc = scene.get_node("NpcRegular")
	assert_false(npc.has_node("AnimationTree"), "NPC should start without AnimationTree")
	npc.apply_presence(1.0)
	assert_almost_eq(npc.get_node("AnimationPlayer").speed_scale, 1.8, 0.01)
	npc.apply_presence(0.0)
	assert_almost_eq(npc.get_node("AnimationPlayer").speed_scale, 4.0, 0.01)


func test_npc_regular_with_animation_tree() -> void:
	var scene = load("res://scenes/focus_mode.tscn").instantiate()
	var npc = scene.get_node("NpcRegular")
	var tree = AnimationTree.new()
	tree.active = true
	var blend_root = AnimationNodeBlendSpace1D.new()
	blend_root.add_blend_point(null, 0.0)
	blend_root.add_blend_point(null, 1.0)
	tree.tree_root = blend_root
	npc.add_child(tree, true)
	npc.apply_presence(1.0)
	assert_almost_eq(tree.get("parameters/calm"), 1.0, 0.01)
	assert_eq(npc.get_node("AnimationPlayer").speed_scale, 1.0)
	npc.remove_child(tree)
	tree.queue_free()


func test_placeholder_tap_animation_exists() -> void:
	var scene = load("res://scenes/focus_mode.tscn").instantiate()
	var npc = scene.get_node("NpcRegular")
	var player: AnimationPlayer = npc.get_node("AnimationPlayer")
	assert_not_null(player, "AnimationPlayer should exist")
	npc._setup_placeholder_animation()
	assert_true(player.has_animation("tap"), "Placeholder tap animation should exist")
	assert_eq(player.current_animation, "tap", "Placeholder tap should be playing")


func test_smudge_resolver_no_material_no_crash() -> void:
	var sprite = Sprite2D.new()
	sprite.name = "SmudgeTest"
	add_child_autofree(sprite)
	sprite.set_script(load("res://scripts/smudge_resolver.gd"))
	sprite.apply_presence(0.0)
	sprite.apply_presence(1.0)
	assert_true(true, "SmudgeResolver should no-op without ShaderMaterial")


func test_neon_clue_no_material_no_crash() -> void:
	var sprite = Sprite2D.new()
	sprite.name = "NeonClueTest"
	add_child_autofree(sprite)
	sprite.set_script(load("res://scripts/neon_clue.gd"))
	sprite.apply_presence(0.0)
	sprite.apply_presence(1.0)
	assert_true(true, "NeonClue should no-op without ShaderMaterial")


func test_evidence_board_progress_and_contradiction() -> void:
	var board = EvidenceBoard.new()
	add_child_autofree(board)

	var clue_a = ClueData.new()
	clue_a.clue_id = "smudge_pattern"
	clue_a.clue_name = "Tread Pattern"
	clue_a.presence_threshold = 0.7
	clue_a.combines_with = ["neon_symbol"]
	clue_a.contradicts = ["false_trail"]

	var clue_b = ClueData.new()
	clue_b.clue_id = "neon_symbol"
	clue_b.clue_name = "Neon Glyph"
	clue_b.presence_threshold = 0.7
	clue_b.combines_with = ["smudge_pattern"]

	var clue_contra = ClueData.new()
	clue_contra.clue_id = "false_trail"
	clue_contra.clue_name = "Old Brake Mark"

	var resolver_a = ClueResolver.new()
	resolver_a.clue_data = clue_a
	var resolver_b = ClueResolver.new()
	resolver_b.clue_data = clue_b
	var resolver_contra = ClueResolver.new()
	resolver_contra.clue_data = clue_contra

	board.register_clue(clue_a, resolver_a)
	board.register_clue(clue_b, resolver_b)
	board.register_clue(clue_contra, resolver_contra)

	resolver_a.apply_presence(1.0)
	resolver_b.apply_presence(1.0)
	resolver_contra.apply_presence(1.0)

	var received_contradiction := false
	board.contradiction_detected.connect(func(a: String, b: String) -> void:
		received_contradiction = true
	)
	resolver_a.apply_presence(1.0)
	resolver_contra.apply_presence(1.0)
	assert_true(received_contradiction, "Contradiction should be detected when both conflicting clues resolve")

	var last_progress := 0.0
	board.deduction_progress.connect(func(progress: float, _text: String) -> void:
		last_progress = progress
	)
	resolver_a.apply_presence(1.0)
	resolver_b.apply_presence(1.0)
	assert_true(last_progress > 0.0, "Deduction progress should increase when clues combine")


func test_evidence_board_wired_in_focus_mode() -> void:
	var scene = load("res://scenes/focus_mode.tscn").instantiate()
	var main = scene
	var board = main.get_node_or_null("EvidenceBoard")
	assert_not_null(board, "EvidenceBoard should be created in code")

	var smudge: SmudgeResolver = main.smudge_resolver
	var neon: NeonClue = main.neon_clue
	if smudge and neon:
		var data1 = ClueData.new()
		data1.clue_id = "smudge"
		data1.clue_name = "Tread Pattern"
		data1.presence_threshold = 0.5
		data1.combines_with = ["neon"]
		var data2 = ClueData.new()
		data2.clue_id = "neon"
		data2.clue_name = "Neon Glyph"
		data2.presence_threshold = 0.5
		data2.combines_with = ["smudge"]
		smudge.clue_data = data1
		neon.clue_data = data2
		board.register_clue(data1, smudge)
		board.register_clue(data2, neon)

		var progress_values = []
		main.deduction_updated.connect(func(p: float, _t: String) -> void:
			progress_values.append(p)
		)
		smudge.apply_presence(1.0)
		neon.apply_presence(1.0)
		smudge._clarity = 1.0
		neon._clarity = 1.0
		smudge.clarity_changed.emit("smudge", 1.0)
		neon.clarity_changed.emit("neon", 1.0)
		assert_true(progress_values.size() > 0, "deduction_updated should emit when clues combine")
		assert_true(progress_values.back() > 0.9, "Progress should be high when both clues resolved")


func test_investigation_beat_resolves_after_combined_clues() -> void:
	var scene = load("res://scenes/focus_mode.tscn").instantiate()
	var main = scene
	var board = main.get_node_or_null("EvidenceBoard")
	assert_not_null(board, "EvidenceBoard should exist")

	var smudge: SmudgeResolver = main.smudge_resolver
	var neon: NeonClue = main.neon_clue
	var beat: InvestigationBeat = main.get_node_or_null("InvestigationBeat")
	assert_not_null(beat, "InvestigationBeat should be created in code")

	if smudge and neon:
		var data1 = ClueData.new()
		data1.clue_id = "smudge"
		data1.clue_name = "Tread Pattern"
		data1.presence_threshold = 0.5
		data1.combines_with = ["neon"]
		var data2 = ClueData.new()
		data2.clue_id = "neon"
		data2.clue_name = "Neon Glyph"
		data2.presence_threshold = 0.5
		data2.combines_with = ["smudge"]
		smudge.clue_data = data1
		neon.clue_data = data2
		board.register_clue(data1, smudge)
		board.register_clue(data2, neon)

	var resolved_texts = []
	beat.beat_resolved.connect(func(text: String) -> void:
		resolved_texts.append(text)
	)
	smudge.apply_presence(1.0)
	neon.apply_presence(1.0)
	smudge._clarity = 1.0
	neon._clarity = 1.0
	smudge.clarity_changed.emit("smudge", 1.0)
	neon.clarity_changed.emit("neon", 1.0)
	assert_true(resolved_texts.size() > 0, "beat_resolved should emit when combined clues reach threshold")
	if resolved_texts.size() > 0:
		assert_true(resolved_texts.back() != "", "beat_resolved should include non-empty insight text")


func test_investigation_ui_fades_in_insight() -> void:
	var scene = load("res://scenes/focus_mode.tscn").instantiate()
	var main = scene
	var ui: InvestigationUI = main.get_node_or_null("InvestigationUI")
	assert_not_null(ui, "InvestigationUI should be created in code")
	assert_not_null(ui.label, "InvestigationUI should own a Label")

	ui.show_insight("The smudge and neon both point to the alley.")
	assert_true(ui.label.visible, "InvestigatonUI label should be visible after show_insight")
	assert_eq(ui.label.text, "The smudge and neon both point to the alley.")
	ui.hide_insight()


func test_sensory_crime_loop_phases_and_auto_resolve() -> void:
	var scene = load("res://scenes/focus_mode.tscn").instantiate()
	var main = scene
	var loop = main.get_node_or_null("SensoryCrimeLoop")
	assert_not_null(loop, "SensoryCrimeLoop should be created in code")

	var phases = []
	loop.phase_changed.connect(func(from: int, to: int) -> void:
		phases.append([from, to])
	)

	var resolved_texts = []
	loop.loop_resolved.connect(func(text: String) -> void:
		resolved_texts.append(text)
	)

	main.investigation_phase = main.InvestigationPhase.Observe
	loop.reset_loop()
	loop.bind(main, main.investigation_beat)
	loop.trigger_overload()
	loop.trigger_stim()
	loop.trigger_tune_in()

	var beat = main.investigation_beat
	var combo_texts = []
	beat.beat_resolved.connect(func(text: String) -> void:
		combo_texts.append(text)
	)
	main.smudge_resolver.apply_presence(1.0)
	main.neon_clue.apply_presence(1.0)
	main.smudge_resolver._clarity = 1.0
	main.neon_clue._clarity = 1.0
	main.smudge_resolver.clarity_changed.emit("smudge", 1.0)
	main.neon_clue.clarity_changed.emit("neon", 1.0)

	assert_true(phases.size() >= 3, "Loop should advance through at least 3 phases")
	assert_true(resolved_texts.size() > 0, "loop_resolved should fire when beat resolves")


func test_focus_mode_main_demo_inputs_registered() -> void:
	var scene = load("res://scenes/focus_mode.tscn").instantiate()
	var main = scene
	for action in ["demo_overload", "demo_stim_toggle", "demo_tune_in"]:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
	var eo = InputEventKey.new()
	eo.keycode = KEY_O
	eo.scancode = KEY_O
	InputMap.action_add_event("demo_overload", eo)
	var es = InputEventKey.new()
	es.keycode = KEY_S
	es.scancode = KEY_S
	InputMap.action_add_event("demo_stim_toggle", es)
	var et = InputEventKey.new()
	et.keycode = KEY_T
	et.scancode = KEY_T
	InputMap.action_add_event("demo_tune_in", et)
	main._setup_demo_inputs()
	assert_true(InputMap.has_action("demo_overload"), "Demo overload action should exist")
	assert_true(InputMap.has_action("demo_stim_toggle"), "Demo stim action should exist")
	assert_true(InputMap.has_action("demo_tune_in"), "Demo tune-in action should exist")


func test_audio_bus_manager_looks_up_effects_by_name() -> void:
	var manager = AudioBusManager.new()
	add_child_autofree(manager)
	manager._ready()
	assert_true(manager._effects.has("lowpass"), "AudioBusManager should register lowpass by name")
	assert_true(manager._effects.has("highpass"), "AudioBusManager should register highpass by name")
	assert_true(manager._effects.has("bandpass"), "AudioBusManager should register bandpass by name")
	var bandpass = manager._effects["bandpass"] as AudioEffectBandPassFilter
	assert_not_null(bandpass, "BandPassFilter lookup should succeed after setup")


func test_audio_bus_manager_glide_noops_when_effect_missing() -> void:
	var manager = AudioBusManager.new()
	add_child_autofree(manager)
	manager._effects["bandpass"] = null
	manager._effects["lowpass"] = null
	manager._effects["highpass"] = null
	manager._current_band_cutoff = 1000.0
	manager._target_band_cutoff = 2000.0
	manager._glide_filters(0.016)
	assert_almost_eq(manager._current_band_cutoff, 1000.0, 0.01, "Glide should no-op when effect lookup returns null")
