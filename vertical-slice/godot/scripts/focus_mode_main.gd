extends Control
class_name FocusModeMain

signal reset_requested()
signal investigation_passed()
signal investigation_blocked()
signal world_listeners_updated(presence: float)
signal calm_changed(calm: float)
signal deduction_updated(progress: float, insight_text: String)
signal contradiction_noted(clue_a: String, clue_b: String)

# Components
var meter: SensoryMeter
var focus: FocusToggle
var stim: StimTool
var disruption_overlay: DisruptionOverlay

var observer_light: ObserverLight
var npc_regular: NpcRegular
var smudge_resolver: SmudgeResolver
var neon_clue: NeonClue
var evidence_board: EvidenceBoard
var investigation_beat: InvestigationBeat
var investigation_ui: InvestigationUI
var sensory_crime_loop: SensoryCrimeLoop
var audio_manager: AudioBusManager
var sensory_canvas: SensoryCanvas
var story_beat_overload: StoryBeat


var sensory := 18.0
var focus_active := false
var elapsed := 0.0
var peripheries := 1.0
var presence := 0.0
var presence_target := 0.0
var chaos := 0.0
var clue_alpha := 0.0
var stream_id_requested := false

# Investigation beat
enum InvestigationPhase { Observe, TuneIn, Resolve, Resolved }
const FOCUS_TEXT_INACTIVE := "Baseline"
const FOCUS_TEXT_ACTIVE := "Focus"
const METER_MODE_BASELINE := "Baseline"
const METER_MODE_HYPERFOCUS := "Hyperfocus"
const METER_MODE_OVERLOAD := "Overload"
var investigation_phase := InvestigationPhase.Observe
var investigation_cooldown := 0.0
var investigation_clue_idx := 0
var investigation_emitted := false
var investigation_resolve_duration := 0.0
var active_clue_id: String = ""
func INVESTIGATION_COOLDOWN() -> float: return 3.0
func INVESTIGATION_RESOLVE_TIME() -> float: return 1.2

# Style
const TRAIL_MIN_POINTS := 14
const TRAIL_STEP_POINTS := 22
const TRAIL_DASH_MAX_STEP := 18
const TRAIL_DASH_LEN := 14
const TRAIL_SHAPE_COUNT := 3
const HIGHLIGHT_SMOOTH := 4.5
var trail_target_len := TRAIL_MIN_POINTS
var trail_current_len := TRAIL_MIN_POINTS
var trail_dash_step := TRAIL_DASH_MAX_STEP
var trail_shape_idx := 0
var trail_highlight_strength := 0.0

# Track + rain
var track_points: PackedVector2Array = PackedVector2Array()
var track_steps := 280
var drops := []
var drop_count := 160
var SMELL := PackedVector2Array([
	Vector2(460, 576), Vector2(525, 524), Vector2(615, 474),
	Vector2(700, 480), Vector2(750, 520)
])
var odor_points := PackedVector2Array(
	PackedVector2Array([Vector2(502, 564), Vector2(571, 514), Vector2(658, 486), Vector2(740, 494), Vector2(736, 512)])
)
var hazard := PackedVector2Array([
	Vector2(462,572),Vector2(502,552),Vector2(534,528),Vector2(582,512),
	Vector2(618,518),Vector2(654,524),Vector2(694,510),Vector2(736,518)
])
var trail_offset := -6.0
var TRAIL := PackedVector2Array()

@onready var ambient := $AmbientAudio
@onready var scene_view := $SceneView
@onready var meter_bar := $SensoryMeterBar
@onready var state_label := $StateLabel
@onready var stim_indicator := $StimIndicator
@onready var sensory_label := $SensoryLabel
@onready var highlight := $Highlight
@onready var tire_smudge: Sprite2D = $SceneView/TireSmudge
@onready var tire_clue: Sprite2D = $SceneView/TireClue
@onready var disruption_overlay_node: DisruptionOverlay = $DisruptionOverlay
@onready var disruptor := $Disruptor


func _enter_tree() -> void:
	_input_map_add_or_replace("focus_toggle", KEY_F)
	_input_map_add_or_replace("stim_hold", KEY_SPACE)
	_input_map_add_or_replace("reset_sensory", KEY_R)


func _ready() -> void:
	meter = SensoryMeter.new()
	meter.set_load(sensory)
	add_child(meter)

	focus = FocusToggle.new()
	add_child(focus)
	focus.focus_changed.connect(_on_focus_changed)

	stim = StimTool.new()
	add_child(stim)
	stim.stim_released.connect(_on_stim_released)
	stim.rhythm_pulse.connect(_on_rhythm_pulse)

	reset_requested.connect(_on_reset)
	set_process_input(true)

	audio_manager = $AudioBusManager
	sensory_canvas = $SensoryCanvas
	observer_light = $ObserverLight
	npc_regular = $NpcRegular
	smudge_resolver = $TireSmudge
	neon_clue = $TireClue
	_setup_evidence_board()
	_setup_investigation_beat()
	_setup_investigation_ui()
	_setup_sensory_crime_loop()
	disruption_overlay = disruption_overlay_node
	if disruptor:
		if disruptor.has_signal("chaos_pulse_rich"):
			disruptor.chaos_pulse_rich.connect(_on_chaos_rich)
		elif disruptor.has_signal("chaos_pulse"):
			disruptor.chaos_pulse.connect(_on_chaos)
	_apply_antagonist_lore(disruptor)

	build_track()
	build_trail()
	init_drops()
	_setup_ui()
	_update_disruption_overlay()


func _setup_sensory_crime_loop() -> void:
	sensory_crime_loop = SensoryCrimeLoop.new()
	sensory_crime_loop.name = "SensoryCrimeLoop"
	add_child(sensory_crime_loop)
	sensory_crime_loop.bind(self, investigation_beat)
	if sensory_crime_loop.has_signal("phase_changed"):
		sensory_crime_loop.phase_changed.connect(_on_sensory_loop_phase_changed)
	_setup_demo_inputs()
	_setup_story_beat_overload()


func _setup_story_beat_overload() -> void:
	story_beat_overload = StoryBeat.new()
	story_beat_overload.name = "StoryBeatOverload"
	story_beat_overload.beat_name = "distant_transformer"
	story_beat_overload.target_phase = SensoryCrimeLoop.Phase.OVERLOAD
	story_beat_overload.retry_until_triggered = true
	story_beat_overload.disruptor = disruptor
	var transformer_variant = DisruptorVariant.new()
	transformer_variant.variant_name = "transformer_hum"
	transformer_variant.intensity = 0.5
	transformer_variant.duration = 1.0
	transformer_variant.interval = 4.0
	transformer_variant.auditory_band = "low"
	transformer_variant.lore_fragment = "A distant transformer hums through the wall."
	story_beat_overload.variant_on_start = transformer_variant
	add_child(story_beat_overload)
	if sensory_crime_loop.has_signal("phase_changed"):
		sensory_crime_loop.phase_changed.connect(story_beat_overload.on_phase_changed)


func _on_sensory_loop_phase_changed(from: int, to: int) -> void:
	if state_label:
		state_label.text = _focus_mode_phase_label(to)
	if to == SensoryCrimeLoop.Phase.TUNE_IN:
		_start_next_clue()


func _focus_mode_phase_label(phase: int) -> String:
	match phase:
		SensoryCrimeLoop.Phase.OBSERVE:
			return "Observe"
		SensoryCrimeLoop.Phase.OVERLOAD:
			return "Overload"
		SensoryCrimeLoop.Phase.STIM:
			return "Stim"
		SensoryCrimeLoop.Phase.TUNE_IN:
			return "Tune-in"
		SensoryCrimeLoop.Phase.RESOLVE:
			return "Resolve"
		_:
			return ""


func _setup_demo_inputs() -> void:
	_input_map_add_or_replace("demo_overload", KEY_O)
	_input_map_add_or_replace("demo_stim_toggle", KEY_S)
	_input_map_add_or_replace("demo_tune_in", KEY_T)


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if sensory_crime_loop:
			if InputMap.has_action("demo_overload") and InputMap.action_has_event("demo_overload", event):
				sensory_crime_loop.trigger_overload()
			elif InputMap.has_action("demo_stim_toggle") and InputMap.action_has_event("demo_stim_toggle", event):
				focus.toggle()
			elif InputMap.has_action("demo_tune_in") and InputMap.action_has_event("demo_tune_in", event):
				sensory_crime_loop.trigger_tune_in()
		if event.keycode == KEY_F:
			focus.toggle()
		elif event.keycode == KEY_SPACE:
			stim.press()
		elif event.keycode == KEY_R:
			_on_reset()
		elif event.keycode == KEY_C:
			_on_chaos(0.6)
	elif event is InputEventKey:
		if event.keycode == KEY_SPACE:
			stim.release()
	elif event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			meter.add_load(9.0)
			_try_resolve_investigation()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		stim.release()


func _process(delta: float) -> void:
	delta = min(delta, 0.05)
	elapsed += delta
	presence = move_toward(presence, presence_target, delta * 0.6)
	presence = clamp(presence, 0.0, 1.0)
	chaos = max(chaos - delta * 0.2, 0.0)
	stim.chaos = chaos
	_update_disruption_overlay()
	stim.update(delta)

	if investigation_cooldown > 0.0:
		investigation_cooldown = max(investigation_cooldown - delta, 0.0)

	if focus_active:
		meter.add_load(6.0 * delta)

	sensory = clamp(meter.sensory, 0.0, 100.0)

	_peripheral_state()
	_update_investigation(delta)
	_rain(delta)
	_update_world_listeners(delta)
	_update_canvas(delta)
	_update_ui()

	if sensory_canvas:
		sensory_canvas.queue_redraw_if_needed()


func _update_canvas(delta: float) -> void:
	if not audio_manager or not sensory_canvas:
		return
	var mode := meter.mode_name()
	var tune_active := investigation_phase == InvestigationPhase.TuneIn and investigation_emitted
	audio_manager.update_targets(mode, stim.holding, tune_active, focus_active)
	sensory_canvas.set_state(presence, chaos, 0.0 if investigation_phase != InvestigationPhase.TuneIn else int(investigation_emitted) + 0.0, smoothstep(0.0, 1.0, presence))
	var trail := _computed_trail_points()
	sensory_canvas.set_trail(trail)
	var binds := PackedVector2Array()
	var step := max(6, trail.size() / 8)
	for i in range(0, trail.size(), step):
		binds.append(trail[i])
	sensory_canvas.set_bind_points(binds)


func _peripheral_state() -> void:
	var mode := meter.mode_name()
	if mode == "Overload":
		peripheries = lerp(peripheries, 0.18, get_process_delta_time() * 5.0)
		clue_alpha = lerp(clue_alpha, 0.92, get_process_delta_time() * 4.0)
	elif mode == "Hyperfocus":
		peripheries = lerp(peripheries, 0.52, get_process_delta_time() * 3.0)
		clue_alpha = lerp(clue_alpha, 0.78, get_process_delta_time() * 3.0)
	else:
		peripheries = lerp(peripheries, 1.0, get_process_delta_time() * 3.0)
		clue_alpha = lerp(clue_alpha, 0.22, get_process_delta_time() * 3.0)

	if investigation_cooldown <= 0.0 and investigation_phase == InvestigationPhase.Observe:
		active_clue_id = ""
		investigation_phase = InvestigationPhase.TuneIn
		investigation_clue_idx = 0
		investigation_emitted = false
		_reset_investigation_visuals()


func _try_resolve_investigation() -> void:
	if investigation_phase != InvestigationPhase.TuneIn or not investigation_emitted:
		return
	if evidence_graph and active_clue_id != "":
		evidence_graph.resolve_clue(active_clue_id)
		active_clue_id = ""
	investigation_phase = InvestigationPhase.Resolved
	investigation_resolve_duration = INVESTIGATION_RESOLVE_TIME()
	investigation_passed.emit()
	focus_active = false


func _on_sensory_loop_phase_changed(from: int, to: int) -> void:
	if state_label:
		state_label.text = _focus_mode_phase_label(to)
	if to == SensoryCrimeLoop.Phase.OBSERVE:
		active_clue_id = ""
	elif to == SensoryCrimeLoop.Phase.TUNE_IN:
		_active_clue_if_any()


func _active_clue_if_any() -> void:
	if evidence_graph:
		return
	for id in evidence_graph.clues:
		var c := evidence_graph.clues[id] as ClueGraph.Clue
		if c and not c.unlocked:
			active_clue_id = id
			break


func _focus_mode_phase_label(phase: int) -> String:
	match phase:
		SensoryCrimeLoop.Phase.OBSERVE:
			return "Observe"
		SensoryCrimeLoop.Phase.OVERLOAD:
			return "Overload"
		SensoryCrimeLoop.Phase.STIM:
			return "Stim"
		SensoryCrimeLoop.Phase.TUNE_IN:
			return "Tune-in"
		SensoryCrimeLoop.Phase.RESOLVE:
			return "Resolve"
		_:
			return ""



func _reset_investigation() -> void:
	investigation_phase = InvestigationPhase.Observe
	investigation_clue_idx = 0
	investigation_emitted = false
	investigation_cooldown = INVESTIGATION_COOLDOWN()
	_reset_investigation_visuals()


func _reset_investigation_visuals() -> void:
	if tire_clue:
		tire_clue.modulate.a = 0.0


func _on_reset() -> void:
	focus_active = false
	stream_id_requested = false
	meter.reset()
	sensory = meter.sensory
	_reset_investigation()


func _on_focus_changed(active: bool) -> void:
	if active:
		meter.add_load(6.0)
	else:
		stream_id_requested = false
	focus_active = active


func _on_stim_released(strength: float) -> void:
	var drop := strength * 18.0
	meter.reduce_load(drop)
	sensory = meter.sensory


func _on_rhythm_pulse(intensity: float) -> void:
	presence_target = min(presence_target + intensity * 0.1 * (1.0 - chaos * 0.8), 1.0)
	_try_advance_investigation_on_pulse()


func _update_world_listeners(delta: float) -> void:
	var calm := smoothstep(0.0, 1.0, presence)
	world_listeners_updated.emit(presence)
	calm_changed.emit(calm)
	if observer_light:
		observer_light.apply_calm(calm, delta)
	if npc_regular:
		npc_regular.apply_presence(presence)
	if smudge_resolver:
		smudge_resolver.apply_presence(presence)
	if neon_clue:
		neon_clue.apply_presence(presence)


func _on_chaos(strength: float) -> void:
	chaos = min(chaos + strength, 1.0)
	_update_disruption_overlay()
	_try_advance_investigation_on_chaos(strength)


func _on_chaos_rich(strength: float, duration: float, band: String) -> void:
	_on_chaos(strength)
	if audio_manager and audio_manager.has_method("apply_chaos_band"):
		audio_manager.apply_chaos_band(band, strength)
	_apply_antagonist_lore_for(band)


func _update_disruption_overlay() -> void:
	if disruption_overlay:
		disruption_overlay.chaos = chaos


func _apply_antagonist_lore(disruptor_node: Disruptor) -> void:
	if not disruptor_node or not disruptor_node.variant:
		return
	var text := disruptor_node.variant.lore_text
	if text == "":
		return
	print("[Lore] %s" % text)


func _apply_antagonist_lore_for(band: String) -> void:
	print("[Lore] Unidentified %s-band disruption." % band)


func _setup_evidence_board() -> void:
	evidence_board = EvidenceBoard.new()
	evidence_board.name = "EvidenceBoard"
	add_child(evidence_board)
	if smudge_resolver:
		evidence_board.register_clue(smudge_resolver.clue_data, smudge_resolver)
	if neon_clue:
		evidence_board.register_clue(neon_clue.clue_data, neon_clue)
	evidence_board.deduction_progress.connect(_on_deduction_progress)
	evidence_board.contradiction_detected.connect(_on_contradiction_detected)


func _on_deduction_progress(progress: float, insight_text: String) -> void:
	deduction_updated.emit(progress, insight_text)


func _on_contradiction_detected(clue_a: String, clue_b: String) -> void:
	contradiction_noted.emit(clue_a, clue_b)


func _setup_investigation_beat() -> void:
	investigation_beat = InvestigationBeat.new()
	investigation_beat.name = "InvestigationBeat"
	investigation_beat.required_progress = 0.75
	add_child(investigation_beat)
	investigation_beat.start(self)


func _setup_investigation_ui() -> void:
	investigation_ui = InvestigationUI.new()
	investigation_ui.name = "InvestigationUI"
	add_child(investigation_ui)
	if investigation_beat:
		investigation_beat.beat_resolved.connect(_on_beat_resolved)
		reset_requested.connect(_reset_investigation)


func _on_beat_resolved(insight_text: String) -> void:
	if investigation_ui:
		investigation_ui.show_insight(insight_text)


func _reset_investigation() -> void:
	if investigation_ui:
		investigation_ui.hide_insight()


func _input_map_add_or_replace(action: String, key: Key) -> void:
	if InputMap.has_action(action):
		InputMap.action_erase_events(action)
	InputMap.add_action(action)
	var e := InputEventKey.new()
	e.keycode = key
	e.physical_keycode = key
	InputMap.action_add_event(action, e)


# === Track + smear + odor locator ===

func build_track() -> void:
	track_points.clear()
	var size := get_rect().size
	for i in range(track_steps):
		var t := float(i) / float(track_steps - 1)
		var x := size.x * 0.22 + t * size.x * 0.56
		var y := size.y * 0.78 - sin(t * PI * 2.4) * size.y * 0.18 - t * size.y * 0.11
		track_points.append(Vector2(x, y))


func _trail_for(base_points: PackedVector2Array, offset_y: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	out.resize(base_points.size())
	for i in range(base_points.size()):
		out[i] = base_points[i] + Vector2(0, offset_y)
	return out


func _midpoint_series(points: PackedVector2Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	if points.size() < 2:
		return out
	for i in range(points.size() - 1):
		out.append((points[i] + points[i + 1]) / 2.0)
	return out


func _update_trail_legibility(delta: float) -> void:
	var focus_bonus := 0.28 if investigation_phase == InvestigationPhase.TuneIn else 0.0
	var density := clamp(presence * 0.8 + focus_bonus, 0.2, 1.0)
	trail_target_len = TRAIL_MIN_POINTS + int(floor(density * float(TRAIL_STEP_POINTS)))
	trail_target_len = clamp(trail_target_len, TRAIL_MIN_POINTS, TRAIL_MIN_POINTS + TRAIL_STEP_POINTS)
	trail_current_len = lerp(float(trail_current_len), float(trail_target_len), 1.0 - exp(-HIGHLIGHT_SMOOTH * delta))
	trail_current_len = clamp(trail_current_len, float(TRAIL_MIN_POINTS), float(TRAIL_MIN_POINTS + TRAIL_STEP_POINTS))
	trail_dash_step = int(lerp(float(TRAIL_DASH_MAX_STEP), maxf(6.0, TRAIL_DASH_MAX_STEP / 3.0), density))
	trail_highlight_strength = clamp(density + (0.3 if focus_active else 0.0), 0.0, 1.0)
	trail_shape_idx = (trail_shape_idx + 1) % TRAIL_SHAPE_COUNT if delta > 0.0 else trail_shape_idx


func _computed_trail_points() -> PackedVector2Array:
	var all := PackedVector2Array()
	all.append_array(_trail_for(hazard, trail_offset))
	all.append_array(_trail_for(SMELL, -16.0))
	all.append_array(_trail_for(odor_points, -22.0))
	all.append_array(_midpoint_series(_trail_for(SMELL, -16.0)))
	var limit := int(clamp(trail_current_len, float(TRAIL_MIN_POINTS), float(all.size())))
	limit = max(limit, 14)
	var pts := PackedVector2Array()
	pts.resize(limit)
	for i in range(limit):
		pts[i] = all[i]
	return pts


# === Rain ===

func init_drops() -> void:
	var size := get_rect().size
	drops.clear()
	for i in range(drop_count):
		drops.append({
			"x": randf() * size.x,
			"y": randf() * size.y,
			"vy": 80 + randf() * 240,
			"len": 14 + randf() * 26,
			"alpha": 0.03 + randf() * 0.16
		})


func _rain(delta: float) -> void:
	var size := get_rect().size
	for d in drops:
		d["y"] += d["vy"] * delta
		if d["y"] > size.y + d["len"]:
			d["y"] = -20
			d["x"] = randf() * size.x


# === UI ===

func _setup_ui() -> void:
	sensory = clamp(sensory, 0.0, 100.0)
	if meter_bar:
		meter_bar.max_value = 100.0
		meter_bar.value = sensory
		meter_bar.texture_progress = preload("res://assets/sprites/meter_fill.png")
		meter_bar.show_percentage = false
	if tire_smudge:
		tire_smudge.texture = preload("res://assets/sprites/tire_smudge.png")
	if tire_clue:
		tire_clue.texture = preload("res://assets/sprites/tire_clue.png")


func _update_ui() -> void:
	sensory = clamp(meter.sensory, 0.0, 100.0)
	var mode := meter.mode_name()
	var focus_text := FOCUS_TEXT_ACTIVE if focus_active else FOCUS_TEXT_INACTIVE
	if state_label:
		var chaos_note := "" if chaos <= 0.01 else " — static %.0f%%" % (chaos * 100.0)
		state_label.text = "%s · %s%s — %.0f%%" % [focus_text, mode, chaos_note, sensory]
		_stl_colorblind_safe(mode, state_label, focus_active)
	if meter_bar:
		meter_bar.value = sensory
	if sensory_label:
		var chaos_suffix := " — chaos %.0f%%" % (chaos * 100.0)
		if chaos <= 0.01:
			chaos_suffix = ""
		sensory_label.text = "Sensory Load %.0f%s" % [sensory, chaos_suffix]
	if stim_indicator:
		stim_indicator.visible = stim.holding
	if tire_clue:
		if investigation_phase == InvestigationPhase.TuneIn:
			var clamped_idx := min(investigation_clue_idx, 3)
			var target_a := 0.22 + clamped_idx * 0.18 + (0.18 if investigation_emitted else 0.0)
			tire_clue.modulate.a = move_toward(tire_clue.modulate.a, min(target_a, 0.96), get_process_delta_time() * 4.0)
		elif investigation_phase == InvestigationPhase.Resolved:
			tire_clue.modulate.a = move_toward(tire_clue.modulate.a, 0.98, get_process_delta_time() * 5.0)
		else:
			var clue_target := 0.18
			if focus_active or mode != METER_MODE_BASELINE:
				clue_target = 0.8 if mode == METER_MODE_OVERLOAD else 0.72
			if stream_id_requested:
				clue_target = maxf(clue_target, 0.95)
			tire_clue.modulate.a = move_toward(tire_clue.modulate.a, clue_target, get_process_delta_time() * 4.0)
	if tire_smudge:
		var smudge_target := 0.08 if focus_active or mode != METER_MODE_BASELINE else 0.75
		tire_smudge.modulate.a = move_toward(tire_smudge.modulate.a, smudge_target, get_process_delta_time() * 5.0)


func _stl_colorblind_safe(mode: String, label: Label, is_focused: bool) -> void:
	if is_focused:
		label.add_theme_font_size_override("font_size", 16)
		label.add_theme_color_override("font_color", Color(0.251, 0.549, 0.753))
		label.text = "%s · %s — %.0f%%" % ["FOCUS", mode, sensory]
	else:
		label.add_theme_font_size_override("font_size", 14)
		label.text = "%s · %s — %0.f%%" % [FOCUS_TEXT_INACTIVE, mode, sensory]
		if mode == METER_MODE_BASELINE:
			label.add_theme_color_override("font_color", Color(0.518, 0.506, 0.471))
		elif mode == METER_MODE_HYPERFOCUS:
			label.add_theme_color_override("font_color", Color(1.0, 0.78, 0.2))
		else:
			label.add_theme_color_override("font_color", Color(0.96, 0.27, 0.24))


static func maxf(a: float, b: float) -> float:
	return a if a > b else b
