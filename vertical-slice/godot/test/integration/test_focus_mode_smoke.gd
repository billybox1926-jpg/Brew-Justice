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


func test_sensory_crime_loop_emits_phase_without_focus_main() -> void:
	var loop = SensoryCrimeLoop.new()
	add_child_autofree(loop)
	loop.bind(null, null)

	var phases = []
	loop.phase_changed.connect(func(from: int, to: int) -> void:
		phases.append([from, to])
	)
	loop.trigger_overload()
	loop.trigger_stim()
	loop.trigger_tune_in()
	assert_true(phases.size() >= 3, "Loop should advance phases without a FocusModeMain dependency")
	assert_eq(loop.current_phase, SensoryCrimeLoop.Phase.TUNE_IN, "Loop should own its current phase")


func test_sensory_crime_loop_resets_on_any_reset_signal() -> void:
	var loop = SensoryCrimeLoop.new()
	add_child_autofree(loop)

	var mock = Node.new()
	mock.name = "MockResetSource"
	mock.add_user_signal("reset_requested")
	add_child_autofree(mock)
	loop.bind(mock, null)

	var phases = []
	loop.phase_changed.connect(func(from: int, to: int) -> void:
		phases.append([from, to])
	)
	loop.trigger_overload()
	loop.trigger_stim()
	loop.trigger_tune_in()
	assert_eq(loop.current_phase, SensoryCrimeLoop.Phase.TUNE_IN)

	mock.reset_requested.emit()
	assert_eq(loop.current_phase, SensoryCrimeLoop.Phase.OBSERVE, "Loop should reset when reset signal fires")


func test_sensory_crime_loop_resolves_when_beat_resolves() -> void:
	var scene = load("res://scenes/focus_mode.tscn").instantiate()
	var main = scene
	var loop = main.get_node("SensoryCrimeLoop")
	assert_not_null(loop, "SensoryCrimeLoop should be created in code")

	var resolved_texts = []
	loop.loop_resolved.connect(func(text: String) -> void:
		resolved_texts.append(text)
	)

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


func test_vignette_calculation_constants_present() -> void:
	var canvas = SensoryCanvas.new()
	add_child_autofree(canvas)
	assert_true(canvas.has_method("_get_vignette_strength"), "Vignette strength helper should exist")
	assert_true(canvas.has_method("_get_vignette_color"), "Vignette color helper should exist")

	var calm_strength := canvas._get_vignette_strength(0.0, 0.0, 1.0)
	var chaos_strength := canvas._get_vignette_strength(0.0, 1.0, 0.0)
	assert_true(chaos_strength >= calm_strength, "Chaos should increase vignette strength")

	var calm_color := canvas._get_vignette_color(canvas._get_vignette_strength(0.0, 0.0, 1.0), 1.0)
	var chaos_color := canvas._get_vignette_color(canvas._get_vignette_strength(0.0, 1.0, 0.0), 0.0)
	assert_true(chaos_color.a >= calm_color.a, "Chaos should make vignette more visible")


func test_disruptor_auto_fire_default_false() -> void:
	var disruptor_node = Disruptor.new()
	add_child_autofree(disruptor_node)
	assert_false(disruptor_node.auto_fire, "Review feedback: auto_fire should default to false")
	assert_false(disruptor_node.is_active(), "Disruptor should not start automatically when auto_fire is false")


func test_disruptor_missing_variant_does_not_crash() -> void:
	var disruptor_node = Disruptor.new()
	add_child_autofree(disruptor_node)
	disruptor_node.trigger_pulse()
	assert_false(disruptor_node.has_signal("chaos_pulse"), "No signal should exist; trigger_pulse should no-op when variant is absent")


func test_disruptor_variant_emits_chaos_pulse() -> void:
	var disruptor_node = Disruptor.new()
	add_child_autofree(disruptor_node)
	var variant = DisruptorVariant.new()
	variant.intensity = 0.9
	variant.duration = 0.5
	variant.auditory_band = "mid"
	variant.lore_text = "Test lore"
	disruptor_node.variant = variant

	var strengths = []
	disruptor_node.chaos_pulse.connect(func(value: float) -> void:
		strengths.append(value)
	)
	disruptor_node.trigger_pulse()
	assert_eq(strengths.size(), 1, "chaos_pulse should emit once when trigger_pulse is called")
	assert_almost_eq(strengths[0], 0.9, 0.01, "chaos_pulse intensity should match variant")


func test_audio_bus_manager_apply_chaos_band_shifts_targets() -> void:
	var manager = AudioBusManager.new()
	add_child_autofree(manager)
	manager._ready()
	manager._target_band_cutoff = 1200.0
	manager._target_band_q = 0.6

	manager.apply_chaos_band("low", 1.0)
	assert_true(manager._target_band_cutoff < 1200.0 - 0.01, "Low band should lower bandpass target cutoff")

	manager.apply_chaos_band("high", 1.0)
	assert_true(manager._target_band_cutoff > 1200.0 + 0.01, "High band should raise bandpass target cutoff")


func test_focus_mode_main_rich_chaos_applies_audio_band() -> void:
	var scene = load("res://scenes/focus_mode.tscn").instantiate()
	var main = scene
	var manager = main.get_node("AudioBusManager")
	assert_not_null(manager, "AudioBusManager should exist in focus_mode scene")

	var band_requested = ""
	var original = manager.apply_chaos_band
	manager.apply_chaos_band = func(band: String, strength: float) -> void:
		band_requested = band

	main._on_chaos_rich(0.4, 0.5, "mid")
	assert_eq(band_requested, "mid", "FocusModeMain should delegate band to AudioBusManager.apply_chaos_band")


func test_story_beat_starts_disruptor_on_target_phase() -> void:
	var beat = StoryBeat.new()
	add_child_autofree(beat)
	beat.beat_name = "transformer_intro"
	beat.target_phase = 1
	var d = Disruptor.new()
	add_child_autofree(d)
	d.auto_fire = false
	beat.disruptor = d
	var variant = DisruptorVariant.new()
	variant.variant_name = "transformer_hum"
	variant.intensity = 0.5
	variant.duration = 1.0
	variant.interval = 4.0
	variant.auditory_band = "low"
	variant.lore_fragment = "A distant transformer hums through the wall."
	beat.variant_on_start = variant

	beat.on_phase_changed(0, 1)
	assert_true(d.auto_fire, "StoryBeat should enable auto_fire when entering target phase")


func test_story_beat_ends_disruptor_on_phase_exit() -> void:
	var beat = StoryBeat.new()
	add_child_autofree(beat)
	beat.beat_name = "transformer_intro"
	beat.target_phase = 1
	var d = Disruptor.new()
	add_child_autofree(d)
	d.auto_fire = false
	beat.disruptor = d
	beat.start_beat()

	beat.on_phase_changed(1, 2)
	assert_false(d.auto_fire, "StoryBeat should disable auto_fire when leaving target phase")


func test_story_beat_applies_variant_on_start() -> void:
	var beat = StoryBeat.new()
	add_child_autofree(beat)
	beat.beat_name = "transformer_intro"
	beat.target_phase = 1
	var d = Disruptor.new()
	add_child_autofree(d)
	d.variant = DisruptorVariant.new()
	beat.disruptor = d
	var variant = DisruptorVariant.new()
	variant.variant_name = "transformer_hum"
	variant.intensity = 0.5
	variant.auditory_band = "low"
	beat.variant_on_start = variant

	beat.on_phase_changed(0, 1)
	assert_eq(d.variant.variant_name, "transformer_hum", "StoryBeat should assign variant on start")


func test_clue_graph_register_and_clarity() -> void:
	var graph = ClueGraph.new()
	add_child_autofree(graph)
	var data = ClueData.new()
	data.clue_id = "smudge_pattern"
	data.clue_name = "Tread Pattern"
	data.presence_threshold = 0.7
	graph.register_clue(data)
	assert_true(graph.get_clue("smudge_pattern") != null, "ClueGraph should store registered clue")
	graph.set_clarity("smudge_pattern", 0.2)
	assert_almost_eq(graph.get_clarity("smudge_pattern"), 0.2, 0.01, "ClueGraph should persist clarity")


func test_clue_graph_resolve_locks_clue() -> void:
	var graph = ClueGraph.new()
	add_child_autofree(graph)
	var data = ClueData.new()
	data.clue_id = "smudge_pattern"
	data.leads_to = ["neon_symbol"]
	graph.register_clue(data)
	graph.set_clarity("smudge_pattern", 1.0)
	var unlocked_ids: Array[String] = []
	graph.clue_unlocked.connect(func(from_clue: String, ids: Array[String]) -> void:
		unlocked_ids = ids
	)
	graph.resolve_clue("smudge_pattern")
	assert_true(unlocked_ids.has("neon_symbol"), "Resolving a clue should unlock leads_to")


func test_evidence_board_bridges_to_clue_graph() -> void:
	var board = EvidenceBoard.new()
	add_child_autofree(board)
	var graph = ClueGraph.new()
	add_child_autofree(graph)
	board.graph_progression_requested.connect(func(id: String) -> void:
		graph.resolve_clue(id)
	)
	var data = ClueData.new()
	data.clue_id = "bridge_test"
	data.leads_to = ["next_clue"]
	board.resolve_clue("bridge_test")
	assert_eq(graph.total_unlocked, 1, "EvidenceBoard bridge should resolve clue in ClueGraph")


func test_focus_mode_main_sets_up_clue_graph() -> void:
	var scene = load("res://scenes/focus_mode.tscn").instantiate()
	var main = scene
	assert_true(main.has_node("ClueGraph"), "FocusModeMain should create ClueGraph during setup")
