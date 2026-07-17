extends Control
class_name MainGame

# Sensory state
var sensory := 18.0
var focus := false
var stim_holding := false
var stim_charge := 0.0
var stim_cd := 0.0

# Audio
var audio_ready := false
var audio_unlocked := false
var audio_low_player: AudioStreamPlayer
var audio_high_player: AudioStreamPlayer
var low_bus_idx := -1
var high_bus_idx := -1
var low_filter: AudioEffectLowPassFilter
var high_filter: AudioEffectHighPassFilter
var target_low_cutoff := 180.0
var target_high_cutoff := 1200.0
var target_low_q := 0.7
var target_high_q := 0.5

# Track
var track_points: PackedVector2Array
var track_steps := 260

# Rain
var drops := []
var drop_count := 140

# Elapsed
var elapsed := 0.0

# UI
var ui_card: PanelContainer
var ui_meter: ProgressBar
var ui_state: Label
var ui_audio: Label


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_setup_ui()
	build_track()
	init_drops()
	set_process(true)


func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.pressed:
			if event.keycode == KEY_F:
				focus = not focus
			elif event.keycode == KEY_SPACE:
				if stim_cd <= 0:
					stim_holding = true
					stim_charge = 0.0
		else:
			if event.keycode == KEY_SPACE:
				stim_holding = false
	elif event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			sensory = min(100.0, sensory + 9.0)
			if not audio_ready:
				init_audio()


func _process(delta: float) -> void:
	delta = min(delta, 0.05)
	elapsed += delta
	
	# Stim
	if stim_holding and stim_cd <= 0:
		stim_charge = min(1.0, stim_charge + delta * 0.6)
		sensory = max(0.0, sensory - 18.0 * delta)
	elif not stim_holding and stim_charge > 0:
		var release := stim_charge * 14.0
		sensory = max(0.0, sensory - release)
		stim_charge = 0.0
		stim_cd = 0.5
	if stim_cd > 0:
		stim_cd = max(0.0, stim_cd - delta)
	
	# Focus drain
	if focus:
		sensory = min(100.0, sensory + 6.0 * delta)
	
	# Rain
	var size := get_rect().size
	for d in drops:
		d["y"] += d["vy"] * delta
		if d["y"] > size.y + d["len"]:
			d["y"] = -20.0
			d["x"] = randf() * size.x
	
	# Audio
	_update_audio_targets()
	_lerp_audio(delta)
	
	# UI
	_update_ui()
	
	queue_redraw()


func _draw() -> void:
	var size := get_rect().size
	
	# Background
	draw_rect(Rect2(0, 0, size.x, size.y), Color(0.043, 0.059, 0.086))
	draw_rect(Rect2(0, size.y * 0.68, size.x, size.y * 0.32), Color(0.055, 0.082, 0.12))
	
	# Puddles
	draw_ellipse(size * Vector2(0.55, 0.82), size.x * 0.18, size.y * 0.04, Color(0.039, 0.137, 0.216, 0.85))
	draw_ellipse(size * Vector2(0.3, 0.9), size.x * 0.08, size.y * 0.015, Color(0.039, 0.137, 0.216, 0.85))
	
	# Per-state
	var peripheral := 1.0
	var clue_alpha := 0.25
	if sensory >= 40 and sensory < 75:
		peripheral = 0.45
		clue_alpha = 0.7
	elif sensory >= 75:
		peripheral = 0.18
		clue_alpha = 0.95
	
	# Rain
	for d in drops:
		var a := d["alpha"] * peripheral
		draw_line(
			Vector2(d["x"], d["y"]),
			Vector2(d["x"], d["y"] + d["len"]),
			Color(0.35, 0.77, 0.9, a),
			1.2
		)
	
	# Smudge / clue
	var smudge_a := 0.18 * clue_alpha
	var intensity := 0.9 if focus else 0.18
	var clue_a := intensity * clue_alpha
	
	_draw_track(smudge_a, true)
	_draw_track(clue_a, false)
	
	if focus and clue_a > 0.5:
		var t := (sin(elapsed * 4.9) * 0.5 + 0.5)
		var idx := int(clamp(t * float(track_points.size() - 1), 0, track_points.size() - 1))
		var p := track_points[idx]
		var pulse := 1.0 + sin(elapsed * 3.8) * 0.18
		draw_circle(p, 3.6 * pulse, Color(1, 1, 1, clue_a))
		_try_draw_label(p + Vector2(10, -6))
	
	# Vignette
	_draw_vignette(sensory / 100.0 * (0.3 if not focus else 0.6))


# === Helpers ===

func _draw_track(alpha: float, smudge: bool) -> void:
	if track_points.size() < 2:
		return
	var col := Color(0.71, 0.67, 0.63, alpha) if smudge else Color(0.0, 0.94, 1.0, alpha)
	var width := 16.0 if smudge else 3.0
	for i in range(1, track_points.size()):
		draw_line(track_points[i - 1], track_points[i], col, width)


func _try_draw_label(pos: Vector2) -> void:
	var font = ThemeDB.fallback_font
	if not font:
		font = get_theme_font("font", "Label")
	if font:
		draw_string(font, pos, "tire tread — investigate", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1.0, 1.0, 1.0, 0.85))


func draw_ellipse(center: Vector2, radius_x: float, radius_y: float, color: Color, segments := 48) -> void:
	var pts := PackedVector2Array()
	for i in range(segments):
		var angle = TAU * float(i) / segments
		pts.append(center + Vector2(cos(angle) * radius_x, sin(angle) * radius_y))
	draw_colored_polygon(pts, color)


func _draw_vignette(strength: float) -> void:
	var size := get_rect().size
	var r := min(size.x, size.y) * (0.55 + strength * 0.22)
	var edge := size - Vector2(r, r)
	var g := Color(0, 0, 0, 0.15 + strength * 0.55)
	draw_rect(Rect2(0, 0, size.x, max(0, edge.y / 2)), g)                    # top
	draw_rect(Rect2(0, (size.y + r) / 2, size.x, max(0, edge.y / 2)), g)    # bottom
	draw_rect(Rect2(0, 0, max(0, edge.x / 2), size.y), g)                  # left
	draw_rect(Rect2((size.x + r) / 2, 0, max(0, edge.x / 2), size.y), g)  # right


# === Track ===

func build_track() -> void:
	track_points.clear()
	var size := get_rect().size
	for i in range(track_steps):
		var t := float(i) / float(track_steps)
		var x := size.x * 0.22 + t * size.x * 0.56
		var y := size.y * 0.78 - sin(t * PI * 2.3) * size.y * 0.18 - t * size.y * 0.12
		track_points.append(Vector2(x, y))


# === Rain ===

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

func init_audio() -> void:
	if audio_ready:
		return
	audio_ready = true
	
	# Buses
	low_bus_idx = AudioServer.bus_count
	AudioServer.add_bus()
	AudioServer.set_bus_name(low_bus_idx, "Low")
	low_filter = AudioEffectLowPassFilter.new()
	AudioServer.add_bus_effect(low_bus_idx, low_filter)
	
	high_bus_idx = AudioServer.bus_count
	AudioServer.add_bus()
	AudioServer.set_bus_name(high_bus_idx, "High")
	high_filter = AudioEffectHighPassFilter.new()
	AudioServer.add_bus_effect(high_bus_idx, high_filter)
	
	# Players
	audio_low_player = AudioStreamPlayer.new()
	audio_low_player.bus = "Low"
	audio_low_player.stream = _make_noise_stream()
	audio_low_player.volume_db = -10
	audio_low_player.autoplay = true
	audio_low_player.loop = true
	add_child(audio_low_player)
	
	audio_high_player = AudioStreamPlayer.new()
	audio_high_player.bus = "High"
	audio_high_player.stream = _make_noise_stream()
	audio_high_player.volume_db = -15
	audio_high_player.autoplay = true
	audio_high_player.loop = true
	add_child(audio_high_player)
	
	_update_audio_targets()
	_lerp_audio(0.0)


func _update_audio_targets() -> void:
	if sensory < 40:
		target_low_cutoff = 180.0
		target_high_cutoff = 1200.0
		target_high_q = 0.5
	elif sensory < 75:
		target_low_cutoff = 220.0
		target_high_cutoff = 600.0
		target_high_q = 0.5
	else:
		target_low_cutoff = 260.0
		target_high_cutoff = 2600.0
		target_high_q = 6.0


func _lerp_audio(delta: float) -> void:
	if not audio_ready or not low_filter or not high_filter:
		return
	var t := 1.0 - exp(-3.0 * delta)
	low_filter.cutoff_frequency = lerp(low_filter.cutoff_frequency, target_low_cutoff, t)
	high_filter.cutoff_frequency = lerp(high_filter.cutoff_frequency, target_high_cutoff, t)
	high_filter.resonance = lerp(high_filter.resonance, target_high_q, t)


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


# === UI ===

func _setup_ui() -> void:
	ui_card = PanelContainer.new()
	ui_card.offset_left = 16.0
	ui_card.offset_top = 16.0
	ui_card.offset_right = 296.0
	ui_card.offset_bottom = 140.0
	add_child(ui_card)
	
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	ui_card.add_child(vbox)
	
	var state_label := Label.new()
	state_label.text = "SENSORY METER"
	state_label.add_theme_color_override("font_color", Color(0.478, 0.655, 0.792))
	vbox.add_child(state_label)
	
	ui_meter = ProgressBar.new()
	ui_meter.max_value = 100.0
	ui_meter.value = sensory
	ui_meter.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(ui_meter)
	
	ui_state = Label.new()
	vbox.add_child(ui_state)
	
	ui_audio = Label.new()
	vbox.add_child(ui_audio)


func _update_ui() -> void:
	var mode := "Baseline"
	if sensory >= 40: mode = "Hyperfocus"
	if sensory >= 75: mode = "Overload"
	var focus_text := "Focus" if focus else "Baseline"
	
	if ui_meter: ui_meter.value = sensory
	if ui_state: ui_state.text = "%s · %s — %.0f%%" % [focus_text, mode, sensory]
	if ui_audio: ui_audio.text = "Audio: %s" % ("on" if audio_ready else "off")
