extends Control
class_name FocusModeMain

var sensory: float = 18.0
var focus := false
var stim_holding := false
var stim_charge := 0.0
var stim_cd := 0.0
var elapsed := 0.0

# Components
var meter: SensoryMeter
var focus_toggle: FocusToggle
var stim_tool: StimTool

# Audio bus state
var audio_ready := false
var audio_low_player: AudioStreamPlayer
var audio_high_player: AudioStreamPlayer
var low_bus_idx := -1
var high_bus_idx := -1
var low_filter: AudioEffectLowPassFilter
var high_filter: AudioEffectHighPassFilter
var target_low_cutoff := 180.0
var target_high_cutoff := 1200.0
var target_high_q := 0.5
var target_low_q := 0.7

# Track
var track_points: PackedVector2Array
var track_steps := 260

# Rain
var drops := []
var drop_count := 140

# UI refs
var ui_card: PanelContainer
var ui_meter: ProgressBar
var ui_status: Label
var ui_audio: Label


func _enter_tree() -> void:
	meter = $SensoryMeter
	focus_toggle = $FocusToggle
	stim_tool = $StimTool


func _ready() -> void:
	_setup_ui()
	build_track()
	init_drops()
	
	focus_toggle.focus_changed.connect(_on_focus_changed)
	stim_tool.stim_released.connect(_on_stim_released)


func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.pressed:
			if event.keycode == KEY_F:
				focus_toggle.toggle()
			elif event.keycode == KEY_SPACE:
				stim_tool.press()
		else:
			if event.keycode == KEY_SPACE:
				stim_tool.release()
	elif event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			meter.add_load(9.0)
			sensory = meter.sensory
			if not audio_ready:
				_setup_audio()


func _process(delta: float) -> void:
	delta = min(delta, 0.05)
	elapsed += delta

	stim_tool.update(delta)

	# Focus drain
	if focus:
		meter.add_load(6.0 * delta)
		sensory = meter.sensory

	# Rain
	var size := get_rect().size
	for d in drops:
		d["y"] += d["vy"] * delta
		if d["y"] > size.y + d["len"]:
			d["y"] = -20.0
			d["x"] = randf() * size.x

	_update_audio_targets()
	_lerp_audio(delta)
	_update_ui()
	queue_redraw()


func _draw() -> void:
	var size := get_rect().size

	draw_rect(Rect2(Vector2(0, 0), size), Color(0.043, 0.059, 0.086))
	draw_rect(Rect2(0, size.y * 0.68, size.x, size.y * 0.32), Color(0.055, 0.082, 0.12))

	draw_ellipse(size * Vector2(0.55, 0.82), size.x * 0.18, size.y * 0.04, Color(0.039, 0.137, 0.216, 0.85))
	draw_ellipse(size * Vector2(0.3, 0.9), size.x * 0.08, size.y * 0.015, Color(0.039, 0.137, 0.216, 0.85))

	var peripheral := 1.0
	var clue_alpha := 0.25
	var mode := meter.mode_name()
	if mode == "Hyperfocus":
		peripheral = 0.45
		clue_alpha = 0.7
	elif mode == "Overload":
		peripheral = 0.18
		clue_alpha = 0.95

	sensory = meter.sensory

	for d in drops:
		var a := d["alpha"] * peripheral
		draw_line(Vector2(d["x"], d["y"]), Vector2(d["x"], d["y"] + d["len"]), Color(0.35, 0.77, 0.9, a), 1.2)

	var smudge_a := 0.18 * clue_alpha
	var intensity := 0.92 if focus else 0.18
	var clue_a := intensity * clue_alpha

	_draw_track(track_points, smudge_a, true)
	_draw_track(track_points, clue_a, false)

	if focus and clue_a > 0.5:
		var t := (sin(elapsed * 4.9) * 0.5 + 0.5)
		var idx := int(clamp(t * float(track_points.size() - 1), 0.0, float(track_points.size() - 1)))
		var p := track_points[idx]
		var pulse := 1.0 + sin(elapsed * 3.8) * 0.18
		draw_circle(p, 3.6 * pulse, Color(1.0, 1.0, 1.0, clue_a))
		if get_theme_font("font", "Label"):
			draw_string(get_theme_font("font", "Label"), p + Vector2(10, -6), "tire tread — investigate", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1.0, 1.0, 1.0, 0.85))

	var strength := sensory / 100.0 * (0.3 if not focus else 0.6)
	_draw_vignette(strength)


# === Helpers ===

func _draw_track(pts: PackedVector2Array, alpha: float, smudge: bool) -> void:
	if pts.size() < 2:
		return
	var col := Color(0.71, 0.67, 0.63, alpha) if smudge else Color(0.0, 0.94, 1.0, alpha)
	var width := 16.0 if smudge else 3.0
	draw_polyline(pts, col, width)


func draw_ellipse(center: Vector2, radius_x: float, radius_y: float, color: Color, segments := 48) -> void:
	var pts := PackedVector2Array()
	for i in range(0, segments):
		var angle = TAU * float(i) / float(segments)
		pts.append(center + Vector2(cos(angle) * radius_x, sin(angle) * radius_y))
	draw_colored_polygon(pts, color)


func _draw_vignette(strength: float) -> void:
	var size := get_rect().size
	var r := min(size.x, size.y) * (0.55 + strength * 0.22)
	var edge := size - Vector2(r, r)
	var g := Color(0, 0, 0, 0.15 + strength * 0.55)
	draw_rect(Rect2(0, 0, size.x, max(0.0, edge.y / 2.0)), g)
	draw_rect(Rect2(0, (size.y + r) / 2.0, size.x, max(0.0, edge.y / 2.0)), g)
	draw_rect(Rect2(0, 0, max(0.0, edge.x / 2.0), size.y), g)
	draw_rect(Rect2((size.x + r) / 2.0, 0, max(0.0, edge.x / 2.0), size.y), g)


func build_track() -> void:
	track_points.clear()
	var size := get_rect().size
	for i in range(track_steps):
		var t := float(i) / float(track_steps)
		var x := size.x * 0.22 + t * size.x * 0.56
		var y := size.y * 0.78 - sin(t * PI * 2.3) * size.y * 0.18 - t * size.y * 0.12
		track_points.append(Vector2(x, y))


func init_drops() -> void:
	drops.clear()
	var size := get_rect().size
	for i in range(drop_count):
		drops.append({
			"x": randf() * size.x,
			"y": randf() * size.y,
			"vy": 110.0 + randf() * 240.0,
			"len": 12.0 + randf() * 18.0,
			"alpha": 0.06 + randf() * 0.12
		})


# === Audio ===

func _setup_audio() -> void:
	if audio_ready:
		return
	audio_ready = true

	low_bus_idx = AudioServer.bus_count
	AudioServer.add_bus()
	AudioServer.set_bus_name(low_bus_idx, "Low")
	low_filter = AudioEffectLowPassFilter.new()
	low_filter.cutoff_hz = 180.0
	low_filter.resonance = 0.7
	AudioServer.add_bus_effect(low_bus_idx, low_filter)

	high_bus_idx = AudioServer.bus_count
	AudioServer.add_bus()
	AudioServer.set_bus_name(high_bus_idx, "High")
	high_filter = AudioEffectHighPassFilter.new()
	high_filter.cutoff_hz = 1200.0
	high_filter.resonance = 0.5
	AudioServer.add_bus_effect(high_bus_idx, high_filter)

	var low_player := AudioStreamPlayer.new()
	low_player.bus = "Low"
	low_player.stream = _make_noise_stream()
	low_player.volume_db = -10
	low_player.autoplay = true
	low_player.loop = true
	add_child(low_player)
	audio_low_player = low_player

	var high_player := AudioStreamPlayer.new()
	high_player.bus = "High"
	high_player.stream = _make_noise_stream()
	high_player.volume_db = -15
	high_player.autoplay = true
	high_player.loop = true
	add_child(high_player)
	audio_high_player = high_player


func _update_audio_targets() -> void:
	var mode := meter.mode_name()
	if mode == "Baseline":
		target_low_cutoff = 180.0
		target_high_cutoff = 1200.0
		target_high_q = 0.5
		target_low_q = 0.7
	elif mode == "Hyperfocus":
		target_low_cutoff = 220.0
		target_high_cutoff = 600.0
		target_high_q = 0.5
		target_low_q = 0.7
	else:
		target_low_cutoff = 260.0
		target_high_cutoff = 2600.0
		target_high_q = 6.0
		target_low_q = 1.0


func _lerp_audio(delta: float) -> void:
	if not audio_ready or not low_filter or not high_filter:
		return
	var t := 1.0 - exp(-8.0 * delta)
	low_filter.cutoff_hz = lerp(low_filter.cutoff_hz, target_low_cutoff, t)
	high_filter.cutoff_hz = lerp(high_filter.cutoff_hz, target_high_cutoff, t)
	high_filter.resonance = lerp(high_filter.resonance, target_high_q, t)
	low_filter.resonance = lerp(low_filter.resonance, target_low_q, t)


func _make_noise_stream() -> AudioStreamWav:
	var stream := AudioStreamWav.new()
	stream.mix_rate = 44100
	stream.stereo = true
	stream.format = AudioStreamWav.FORMAT_16_BITS
	var duration := 2.0
	var sample_count := int(stream.mix_rate * duration)
	var data := PackedByteArray()
	data.resize(sample_count * 4)
	for i in range(sample_count):
		var val := int((randf() * 2.0 - 1.0) * 32767.0)
		data[i * 4 + 0] = val & 0xFF
		data[i * 4 + 1] = (val >> 8) & 0xFF
		data[i * 4 + 2] = val & 0xFF
		data[i * 4 + 3] = (val >> 8) & 0xFF
	stream.data = data
	return stream


# === Input callbacks ===

func _on_focus_changed(is_focused: bool) -> void:
	focus = is_focused
	if focus:
		meter.add_load(6.0)
		sensory = meter.sensory


func _on_stim_released(strength: float) -> void:
	var drop := strength * 14.0
	meter.reduce_load(drop)
	sensory = meter.sensory


# === UI ===

func _setup_ui() -> void:
	ui_card = $UICard
	ui_meter = ui_card.get_node("VBox/Meter") if ui_card else null
	ui_status = ui_card.get_node("VBox/StatusLabel") if ui_card else null
	ui_audio = ui_card.get_node("VBox/AudioLabel") if ui_card else null


func _update_ui() -> void:
	var mode := meter.mode_name()
	var focus_text := "Focus" if focus else "Baseline"
	if ui_meter:
		ui_meter.value = sensory
	if ui_status:
		ui_status.text = "%s · %s — %.0f%%" % [focus_text, mode, sensory]
	if ui_audio:
		ui_audio.text = "Audio: %s" % ("on" if audio_ready else "off")
