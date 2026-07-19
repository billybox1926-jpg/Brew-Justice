extends Control
class_name FocusModeMain

signal reset_requested()
signal investigation_passed()
signal investigation_blocked()
signal world_listeners_updated(presence: float)
signal calm_changed(calm: float)

# === State ===
var sensory := 18.0
var focus_active := false
var elapsed := 0.0
var peripheries := 1.0
var presence := 0.0
var presence_target := 0.0
var chaos := 0.0
var clue_alpha := 0.25
var stream_id_requested := false

# Investigation beat
enum InvestigationPhase { Observe, TuneIn, Resolve, Resolved }
var investigation_phase := InvestigationPhase.Observe
var investigation_cooldown := 0.0
var investigation_clue_idx := 0
var investigation_emitted := false
var investigation_resolve_duration := 0.0
func INVESTIGATION_COOLDOWN() -> float: return 3.0
func INVESTIGATION_RESOLVE_TIME() -> float: return 1.2

# Components
var meter: SensoryMeter
var focus: FocusToggle
var stim: StimTool
var disruption_overlay: DisruptionOverlay

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

# === Scent trail legibility ===
const TRAIL_MIN_POINTS := 14
const TRAIL_STEP_POINTS := 22
const TRAIL_DASH_MAX_STEP := 18
const TRAIL_DASH_LEN := 14
const TRAIL_SHAPE_COUNT := 3
const HIGHLIGHT_SMOOTH := 4.5
# Trail style is modulated by presence + focus state; color carries less meaning.
var trail_target_len := TRAIL_MIN_POINTS
var trail_current_len := TRAIL_MIN_POINTS
var trail_dash_step := TRAIL_DASH_MAX_STEP
var trail_shape_idx := 0
var trail_highlight_strength := 0.0

# Audio
var audio_ready := false
var sfx_bus_idx := -1
var low_filter: AudioEffectLowPassFilter
var high_filter: AudioEffectHighPassFilter
var bandpass_filter: AudioEffectBandPassFilter
var target_low_cutoff := 180.0
var target_high_cutoff := 1200.0
var target_low_q := 0.7
var target_high_q := 0.5
var target_bandpass_freq := 1200.0
var target_bandpass_q := 0.6
var cafe_stream_cache: AudioStreamWav

# Editor nodes
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
@onready var observer_light := $ObserverLight
@onready var npc_regular := $NpcRegular

# === Initialization ===

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

	build_track()
	build_trail()
	init_drops()
	_setup_audio()
	_setup_ui()
	disruption_overlay = disruption_overlay_node
	if disruptor and disruptor.has_signal("chaos_pulse"):
		disruptor.chaos_pulse.connect(_on_chaos)
	_update_disruption_overlay()


func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.pressed:
			if event.keycode == KEY_F:
				focus.toggle()
			elif event.keycode == KEY_SPACE:
				stim.press()
			elif event.keycode == KEY_R:
				_on_reset()
			elif event.keycode == KEY_C:
				_on_chaos(0.6)
		else:
			if event.keycode == KEY_SPACE:
				stim.release()
	elif event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			meter.add_load(9.0)
			_try_resolve_investigation()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		stim.release()


# === Main loop ===

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
	_audio_targets()
	_lerp_audio(delta)
	_update_world_listeners(delta)
	_update_trail_legibility(delta)
	_update_ui()
	queue_redraw()


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
		investigation_phase = InvestigationPhase.TuneIn
		investigation_clue_idx = 0
		investigation_emitted = false
		_reset_investigation_visuals()


func _try_advance_investigation_on_pulse() -> void:
	if not focus_active:
		return
	if investigation_phase == InvestigationPhase.TuneIn:
		investigation_clue_idx += 1
	if investigation_clue_idx >= 4:
		investigation_emitted = true


func _try_advance_investigation_on_chaos(strength: float) -> void:
	if investigation_phase == InvestigationPhase.TuneIn and strength <= 0.25:
		investigation_clue_idx = max(investigation_clue_idx - 1, 0)
		investigation_emitted = false


func _try_resolve_investigation() -> void:
	if investigation_phase != InvestigationPhase.TuneIn or investigation_emitted == false:
		return
	investigation_phase = InvestigationPhase.Resolved
	investigation_resolve_duration = INVESTIGATION_RESOLVE_TIME()
	investigation_passed.emit()
	focus_active = false


func _update_investigation(delta: float) -> void:
	if investigation_phase == InvestigationPhase.Resolved and investigation_resolve_duration > 0.0:
		investigation_resolve_duration = max(investigation_resolve_duration - delta, 0.0)
		if investigation_resolve_duration <= 0.0:
			_reset_investigation()


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
	# The room leans toward the player's calm — but chaos bleeds the leak.
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


func _on_chaos(strength: float) -> void:
	# A disruptor / hostile shift spikes the room's static.
	chaos = min(chaos + strength, 1.0)
	_update_disruption_overlay()
	_try_advance_investigation_on_chaos(strength)


func _update_disruption_overlay() -> void:
	if disruption_overlay:
		disruption_overlay.chaos = chaos


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


func build_trail() -> void:
	if hazard.is_empty():
		hazard = PackedVector2Array([
			Vector2(480,524),Vector2(520,512),Vector2(558,500),Vector2(604,510),
			Vector2(626,516)
		])

var hazard := PackedVector2Array([
	Vector2(462,572),Vector2(502,552),Vector2(534,528),Vector2(582,512),
	Vector2(618,518),Vector2(654,524),Vector2(694,510),Vector2(736,518)
])
var trail_offset := -6.0
var TRAIL := PackedVector2Array()

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
	trail_dash_step = int(lerp(float(TRAIL_DASH_MAX_STEP), max(6, TRAIL_DASH_MAX_STEP / 3), density))
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


func _render_trail(points: PackedVector2Array) -> void:
	var mode := meter.mode_name()
	var line_color := Color(0.961, 0.714, 0.18, 0.18)
	var line_width := 8.0
	if mode == "Baseline":
		line_color = Color(0.961, 0.714, 0.18, 0.08)
		line_width = 10.0
	elif mode == "Hyperfocus":
		line_color = Color(0.961, 0.714, 0.18, 0.24)
		line_width = 6.0
	else:
		line_color = Color(0.961, 0.714, 0.18, 0.18)
		line_width = 10.0

	if points.is_empty():
		return
	if trail_dash_step > 1:
		var dashed := PackedVector2Array()
		for i in range(0, points.size(), max(trail_dash_step, 1)):
			var nxt := min(i + TRAIL_DASH_LEN, points.size())
			if nxt > i:
				for j in range(i, nxt):
					dashed.append(points[j])
		draw_polyline(dashed, line_color, line_width)
	else:
		draw_polyline(points, line_color, line_width)


func _render_trail_highlights(points: PackedVector2Array, delta: float) -> void:
	if points.is_empty():
		return
	var q_mode := meter.mode_name()
	if q_mode == "Baseline" and trail_highlight_strength < 0.22:
		return
	var pulse_speed := 2.2 + presence * 3.0
	var pulse_base := 0.45 + trail_highlight_strength * 0.45
	var marker_color := Color(1.0, 0.82, 0.16, 0.8 * trail_highlight_strength)
	var marker_color_alt := Color(0.98, 0.35, 0.22, 0.75 * trail_highlight_strength)
	var step := max(6, points.size() / 8)
	for i in range(0, points.size(), step):
		var phase := elapsed * pulse_speed + i
		var pulse := sin(phase) * 0.5 + 0.5
		if pulse < 0.5:
			continue
		var p := points[i]
		var size := 2.4 + pulse * 2.4 * trail_highlight_strength
		var col := marker_color if trail_shape_idx == i % TRAIL_SHAPE_COUNT else marker_color_alt
		if trail_shape_idx == 1 and i % (step * 2) == 0:
			_draw_diamond(p, size, col)
		elif trail_shape_idx == 2 and i % (step * 2) == 0:
			_draw_square(p, size, col)
		else:
			draw_circle(p, size, col)


func _draw_diamond(p: Vector2, size: float, color: Color) -> void:
	var pts := PackedVector2Array([
		p + Vector2(0, -size),
		p + Vector2(size, 0),
		p + Vector2(0, size),
		p + Vector2(-size, 0)
	])
	draw_colored_polygon(pts, color)


func _draw_square(p: Vector2, size: float, color: Color) -> void:
	var center := size * 0.707
	draw_rect(Rect2(p - Vector2(center, center), Vector2(size, size)), color)


func _draw() -> void:
	var size := get_rect().size

	draw_rect(Rect2(Vector2.ZERO, size), Color(0.02, 0.02, 0.039))
	draw_rect(Rect2(0, size.y * 0.68, size.x, size.y * 0.32), Color(0.039, 0.039, 0.078))
	draw_rect(Rect2(48, 64, 720, 56), Color(0.02, 0.02, 0.039, 0.647))

	var mode := meter.mode_name()

	# Midground skyline
	var mid_x := 176.0
	var mid_y := 64.0
	draw_line(Vector2(320, 260), Vector2(360, 274), Color(0.071, 0.192, 0.275), 1.5)
	draw_line(Vector2(316, 354), Vector2(90, 564), Color(0.071, 0.192, 0.275), 2.0)

	# Smear + bind graphs
	_draw_graph(sensory, Color(0.741, 0.482, 0.024, 1.0), Color(0.89, 0.46, 0.02, 1.0), 25)
	var trail_pts := _computed_trail_points()
	_render_trail(trail_pts)
	_render_trail_highlights(trail_pts, delta if delta > 0.0 else 0.016)

	# Peripheral fade
	_vignette(1.0 - peripheries, presence)

	# Clue marker
	var hint_idx := int(clamp(elapsed * 9.0, 0.0, float(odor_points.size() - 1)))
	draw_circle(odor_points[hint_idx], 1.6, Color(1.0, 0.86, 0.1, 0.7 * clue_alpha))


func _draw_graph(sensory_value: float, up_color: Color, down_color: Color, bar_count: int) -> void:
	var size := get_rect().size
	var m := meter.mode_name()
	var base_x := 72.0
	var base_y := 88.0
	var bar_w := 10.0
	var gap := 3.0
	for i in range(bar_count):
		var t := float(i) / float(bar_count)
		var phase := t * PI * 2.5 + elapsed * 2.2
		var bar_h := (sin(phase) * 0.5 + 0.5) * 52.0
		bar_h = max(bar_h, 6.0)
		bar_h *= 0.2 + (sensory_value / 100.0) * 0.8
		bar_h = clamp(bar_h, 3.0, 60.0)
		var x := base_x + t * (bar_w + gap) * float(bar_count)
		var c := down_color if t > 0.5 else up_color
		c.a = 0.6 * peripheries
		draw_rect(Rect2(x, base_y, bar_w, -bar_h), c)


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


# === Audio ===

func _setup_audio() -> void:
	if audio_ready:
		return

	stream_id_requested = true

	sfx_bus_idx = AudioServer.bus_count
	AudioServer.add_bus()
	AudioServer.set_bus_name(sfx_bus_idx, "SFX")

	low_filter = AudioEffectLowPassFilter.new()
	low_filter.cutoff_hz = 180.0
	low_filter.resonance = 0.7
	AudioServer.add_bus_effect(sfx_bus_idx, low_filter)

	high_filter = AudioEffectHighPassFilter.new()
	high_filter.cutoff_hz = 1200.0
	high_filter.resonance = 0.5
	AudioServer.add_bus_effect(sfx_bus_idx, high_filter)

	bandpass_filter = AudioEffectBandPassFilter.new()
	bandpass_filter.frequency = target_bandpass_freq
	bandpass_filter.gain = 0.0
	bandpass_filter.Q = target_bandpass_q
	AudioServer.add_bus_effect(sfx_bus_idx, bandpass_filter)

	ambient.bus = "SFX"
	ambient.stream = _make_cafe_stream()
	ambient.volume_db = -11
	ambient.autoplay = true
	ambient.loop = true

	audio_ready = true


func _audio_targets() -> void:
	if not audio_ready:
		return
	var mode := meter.mode_name()
	if mode == "Baseline":
		target_low_cutoff = 180.0
		target_high_cutoff = 1200.0
		target_low_q = 0.7
		target_high_q = 0.5
	elif mode == "Hyperfocus":
		target_low_cutoff = 230.0
		target_high_cutoff = 640.0
		target_low_q = 0.7
		target_high_q = 0.5
	else:
		target_low_cutoff = 280.0
		target_high_cutoff = 2800.0
		target_low_q = 1.4
		target_high_q = 7.0

	if stim.holding:
		target_low_cutoff = clamp(target_low_cutoff - 90, 80.0, 480.0)
		target_high_cutoff = clamp(target_high_cutoff - 500, 420.0, 1400.0)
		target_high_q = 0.5
		target_low_q = 0.7

	if investigation_phase == InvestigationPhase.TuneIn and investigation_emitted:
		target_bandpass_freq = 980.0
		target_bandpass_q = 1.1
	elif focus_active:
		target_bandpass_freq = 820.0
		target_bandpass_q = 0.9
	else:
		target_bandpass_freq = 1200.0
		target_bandpass_q = 0.6


func _lerp_audio(delta: float) -> void:
	if not audio_ready:
		return
	var t := 1.0 - exp(-8.0 * delta)
	if low_filter:
		low_filter.cutoff_hz = lerp(low_filter.cutoff_hz, target_low_cutoff, t)
		low_filter.resonance = lerp(low_filter.resonance, target_low_q, t)
	if high_filter:
		high_filter.cutoff_hz = lerp(high_filter.cutoff_hz, target_high_cutoff, t)
		high_filter.resonance = lerp(high_filter.resonance, target_high_q, t)
	if bandpass_filter:
		bandpass_filter.frequency = lerp(bandpass_filter.frequency, target_bandpass_freq, t)
		bandpass_filter.Q = lerp(bandpass_filter.Q, target_bandpass_q, t)


func _make_cafe_stream() -> AudioStreamWav:
	var stream := AudioStreamWav.new()
	stream.mix_rate = 44100
	stream.stereo = true
	stream.format = AudioStreamWav.FORMAT_16_BITS
	var duration := 4.0
	var samples := int(stream.mix_rate * duration)
	var data := PackedByteArray()
	data.resize(samples * 4)
	var b0 := 0.0; var b1 := 0.0; var b2 := 0.0; var b3 := 0.0; var b4 := 0.0; var b5 := 0.0; var b6 := 0.0
	var clink_timer := 0.0
	var clink_amp := 0.0
	for i in range(samples):
		var t := float(i) / float(stream.mix_rate)
		# Layer 1: room tone low rumble.
		var room := 0.18 * sin(TAU * 72.0 * t + 0.3)
		room += 0.09 * sin(TAU * 111.0 * t - 0.5)
		room += 0.05 * sin(TAU * 142.0 * t + 1.1)
		# Layer 2: mid chatter via shaped noise.
		var white := randf() * 2.0 - 1.0
		b0 = 0.99886 * b0 + white * 0.0555179
		b1 = 0.99332 * b1 + white * 0.0750759
		b2 = 0.96900 * b2 + white * 0.1538520
		b3 = 0.86650 * b3 + white * 0.3104856
		b4 = 0.55000 * b4 + white * 0.5329522
		b5 = -0.7616 * b5 - white * 0.0168980
		var pinkish := b0 + b1 + b2 + b3 + b4 + b5 + b6 + white * 0.5362
		b6 = white * 0.115926
		var chatter := pinkish * 0.28
		# Layer 3: high clinks / movement.
		clink_timer -= 1.0 / float(stream.mix_rate)
		if clink_timer <= 0.0:
			clink_timer = 0.08 + randf() * 0.55
			clink_amp = 0.05 + randf() * 0.25
		var env := exp(-max(0.0, -clink_timer) * 14.0)
		var clink_freq := 2200.0 + randf() * 4200.0
		var clink := clink_amp * env * sin(TAU * clink_freq * t)
		var mixed := room + chatter + clink
		var v := int(clamp(mixed * 0.22, -1.0, 1.0) * 32767.0)
		data[i * 4 + 0] = v & 0xFF
		data[i * 4 + 1] = (v >> 8) & 0xFF
		data[i * 4 + 2] = v & 0xFF
		data[i * 4 + 3] = (v >> 8) & 0xFF
	stream.data = data
	return stream


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
	var focus_text := "Focus" if focus_active else "Baseline"

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
			# Progress clue presence by steady pulses; add a bonus once fully tuned.
			var clamped_idx := min(investigation_clue_idx, 3)
			var target_a := 0.22 + clamped_idx * 0.18 + (0.18 if investigation_emitted else 0.0)
			tire_clue.modulate.a = move_toward(tire_clue.modulate.a, min(target_a, 0.96), get_process_delta_time() * 4.0)
		elif investigation_phase == InvestigationPhase.Resolved:
			tire_clue.modulate.a = move_toward(tire_clue.modulate.a, 0.98, get_process_delta_time() * 5.0)
		else:
			var clue_target := 0.18
			if focus_active or mode != "Baseline":
				clue_target = 0.8 if mode == "Overload" else 0.72
			if stream_id_requested:
				clue_target = max(clue_target, 0.95)
			tire_clue.modulate.a = move_toward(tire_clue.modulate.a, clue_target, get_process_delta_time() * 4.0)

	if tire_smudge:
		var smudge_target := 0.08 if focus_active or mode != "Baseline" else 0.75
		tire_smudge.modulate.a = move_toward(tire_smudge.modulate.a, smudge_target, get_process_delta_time() * 5.0)


func _stl_colorblind_safe(mode: String, label: Label, is_focused: bool) -> void:
	if is_focused:
		label.add_theme_font_size_override("font_size", 16)
		label.add_theme_color_override("font_color", Color(0.251, 0.549, 0.753))
		label.text = "%s · %s — %.0f%%" % ["FOCUS", mode, sensory]
	else:
		label.add_theme_font_size_override("font_size", 14)
		label.text = "%s · %s — %0.f%%" % ["Baseline", mode, sensory]
		if mode == "Baseline":
			label.add_theme_color_override("font_color", Color(0.518, 0.506, 0.471))
		elif mode == "Hyperfocus":
			label.add_theme_color_override("font_color", Color(1.0, 0.78, 0.2))
		else:
			label.add_theme_color_override("font_color", Color(0.96, 0.27, 0.24))


# === Helpers ===

func _vignette(strength: float, calm: float = 0.0) -> void:
	# Presence should read as co-regulation: each steady rhythm pulse opens the
	# periphery instead of letting chaos collapse into a harsh tunnel.
	var regulated_strength := clamp(strength - calm * 0.7, 0.0, 1.0)
	var eased_strength := ease(regulated_strength, 0.5)
	var calm_glow := clamp(calm, 0.0, 1.0)
	var size := get_rect().size
	var r := min(size.x, size.y) * (0.55 + eased_strength * 0.3 + calm_glow * 0.04)
	var edge := size - Vector2(r, r)
	var alpha := 0.10 + eased_strength * 0.56 - calm_glow * 0.04
	# Keep the cue non-hue dependent: alpha and aperture carry the signal, while
	# the calm rim is a low-contrast value cue that reads as the room softening.
	var g := Color(0.035, 0.035, 0.032, clamp(alpha, 0.06, 0.66))
	var rim := Color(0.92, 0.88, 0.78, calm_glow * 0.08)
	var xf := max(0.0, edge.x / 2.0)
	var yf := max(0.0, edge.y / 2.0)
	draw_rect(Rect2(Vector2(0, 0), Vector2(size.x, yf)), g)
	draw_rect(Rect2(Vector2(0, (size.y + r) / 2.0), Vector2(size.x, yf)), g)
	draw_rect(Rect2(Vector2(0, 0), Vector2(xf, size.y)), g)
	draw_rect(Rect2(Vector2((size.x + r) / 2.0, 0), Vector2(xf, size.y)), g)
	if calm_glow > 0.0 and xf > 0.0 and yf > 0.0:
		var rim_width := 2.0 + calm_glow * 3.0
		draw_rect(Rect2(Vector2(xf - rim_width, yf - rim_width), Vector2(r + rim_width * 2.0, rim_width)), rim)
		draw_rect(Rect2(Vector2(xf - rim_width, yf + r), Vector2(r + rim_width * 2.0, rim_width)), rim)
		draw_rect(Rect2(Vector2(xf - rim_width, yf), Vector2(rim_width, r)), rim)
		draw_rect(Rect2(Vector2(xf + r, yf), Vector2(rim_width, r)), rim)
