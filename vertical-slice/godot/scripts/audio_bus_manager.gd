extends Node
class_name AudioBusManager

## Owns the SFX bus, bandpass/lowpass/highpass filters, and cafe ambience playback.
## FocusModeMain calls update_targets(mode, stim_holding, tune_active, focus_active, delta).

const GLIDE_SPEED: float = 2.0
const DEFAULT_CUTOFF: float = 20000.0
const DEFAULT_RESONANCE: float = 0.5
const SFX_BUS_NAME := "SFX"

var _effects := {}
var _cafe_player: AudioStreamPlayer
var _cafe_playback: AudioStreamGeneratorPlayback

var _current_low_cutoff: float = 180.0
var _current_low_q: float = 0.7
var _current_high_cutoff: float = 1200.0
var _current_high_q: float = 0.5
var _current_band_cutoff: float = 1200.0
var _current_band_q: float = 0.6

var _target_low_cutoff: float = 180.0
var _target_low_q: float = 0.7
var _target_high_cutoff: float = 1200.0
var _target_high_q: float = 0.5
var _target_band_cutoff: float = 1200.0
var _target_band_q: float = 0.6


func _ready() -> void:
	_setup_audio_bus()
	_start_cafe_ambience()
	_reset_targets()


func _setup_audio_bus() -> void:
	var sfx_idx := AudioServer.get_bus_index(SFX_BUS_NAME)
	if sfx_idx == -1:
		push_warning("AudioBusManager: %s bus not found — audio effects inactive" % SFX_BUS_NAME)
		return

	_effects["lowpass"] = _find_effect_by_name(sfx_idx, "LowPassFilter")
	if not _effects["lowpass"]:
		var fx := AudioEffectLowPassFilter.new()
		fx.cutoff_hz = 180.0
		fx.resonance = 0.7
		AudioServer.add_bus_effect(sfx_idx, fx)
		_effects["lowpass"] = _find_effect_by_name(sfx_idx, "LowPassFilter")

	_effects["highpass"] = _find_effect_by_name(sfx_idx, "HighPassFilter")
	if not _effects["highpass"]:
		var fx := AudioEffectHighPassFilter.new()
		fx.cutoff_hz = 1200.0
		fx.resonance = 0.5
		AudioServer.add_bus_effect(sfx_idx, fx)
		_effects["highpass"] = _find_effect_by_name(sfx_idx, "HighPassFilter")

	_effects["bandpass"] = _find_effect_by_name(sfx_idx, "BandPassFilter")
	if not _effects["bandpass"]:
		var fx := AudioEffectBandPassFilter.new()
		fx.cutoff_hz = 1200.0
		fx.Q = 0.6
		AudioServer.add_bus_effect(sfx_idx, fx)
		_effects["bandpass"] = _find_effect_by_name(sfx_idx, "BandPassFilter")

	if not _effects["lowpass"]:
		push_warning("AudioBusManager: LowPassFilter not found on %s bus — cutoffs inactive" % SFX_BUS_NAME)
	if not _effects["highpass"]:
		push_warning("AudioBusManager: HighPassFilter not found on %s bus — cutoffs inactive" % SFX_BUS_NAME)
	if not _effects["bandpass"]:
		push_warning("AudioBusManager: BandPassFilter not found on %s bus — tune-in inactive" % SFX_BUS_NAME)


func _find_effect_by_name(bus_idx: int, name: String) -> AudioEffect:
	for i in range(AudioServer.get_bus_effect_count(bus_idx)):
		var effect := AudioServer.get_bus_effect(bus_idx, i)
		if effect and effect.resource_name == name:
			return effect
	return null


func _reset_targets() -> void:
	var lowpass := _effects["lowpass"] as AudioEffectLowPassFilter
	var highpass := _effects["highpass"] as AudioEffectHighPassFilter
	var bandpass := _effects["bandpass"] as AudioEffectBandPassFilter

	if lowpass:
		_target_low_cutoff = lowpass.cutoff_hz
		_target_low_q = lowpass.resonance
	if highpass:
		_target_high_cutoff = highpass.cutoff_hz
		_target_high_q = highpass.resonance
	if bandpass:
		_target_band_cutoff = bandpass.cutoff_hz if bandpass.get("cutoff_hz") != null else bandpass.frequency
		_target_band_q = bandpass.Q

	_current_low_cutoff = _target_low_cutoff
	_current_low_q = _target_low_q
	_current_high_cutoff = _target_high_cutoff
	_current_high_q = _target_high_q
	_current_band_cutoff = _target_band_cutoff
	_current_band_q = _target_band_q


func _start_cafe_ambience() -> void:
	var stream := AudioStreamGenerator.new()
	stream.mix_rate = 44100
	_cafe_player = AudioStreamPlayer.new()
	_cafe_player.bus = SFX_BUS_NAME
	_cafe_player.stream = stream
	_cafe_player.autoplay = true
	add_child(_cafe_player)
	_cafe_playback = _cafe_player.get_stream_playback()
	_cafe_player.play()


func update_targets(mode: String, stim_holding: bool, tune_active: bool, focus_active: bool) -> void:
	match mode:
		"Baseline":
			_target_low_cutoff = 180.0
			_target_high_cutoff = 1200.0
			_target_low_q = 0.7
			_target_high_q = 0.5
		"Hyperfocus":
			_target_low_cutoff = 230.0
			_target_high_cutoff = 640.0
			_target_low_q = 0.7
			_target_high_q = 0.5
		_:
			_target_low_cutoff = 280.0
			_target_high_cutoff = 2800.0
			_target_low_q = 1.4
			_target_high_q = 7.0

	if stim_holding:
		_target_low_cutoff = clampf(_target_low_cutoff - 90, 80.0, 480.0)
		_target_high_cutoff = clampf(_target_high_cutoff - 500, 420.0, 1400.0)
		_target_high_q = 0.5
		_target_low_q = 0.7

	if tune_active:
		_target_band_cutoff = 980.0
		_target_band_q = 1.1
	elif focus_active:
		_target_band_cutoff = 820.0
		_target_band_q = 0.9
	else:
		_target_band_cutoff = 1200.0
		_target_band_q = 0.6


func _glide_filters(delta: float) -> void:
	var lowpass := _effects["lowpass"] as AudioEffectLowPassFilter
	var highpass := _effects["highpass"] as AudioEffectHighPassFilter
	var bandpass := _effects["bandpass"] as AudioEffectBandPassFilter
	if not lowpass or not highpass or not bandpass:
		return
	var factor := 1.0 - exp(-GLIDE_SPEED * delta)
	_current_low_cutoff = lerpf(_current_low_cutoff, _target_low_cutoff, factor)
	_current_low_q = lerpf(_current_low_q, _target_low_q, factor)
	_current_high_cutoff = lerpf(_current_high_cutoff, _target_high_cutoff, factor)
	_current_high_q = lerpf(_current_high_q, _target_high_q, factor)
	_current_band_cutoff = lerpf(_current_band_cutoff, _target_band_cutoff, factor)
	_current_band_q = lerpf(_current_band_q, _target_band_q, factor)
	lowpass.cutoff_hz = _current_low_cutoff
	lowpass.resonance = _current_low_q
	highpass.cutoff_hz = _current_high_cutoff
	highpass.resonance = _current_high_q
	bandpass.cutoff_hz = _current_band_cutoff
	bandpass.Q = _current_band_q


func _process(delta: float) -> void:
	_fill_cafe_buffer(delta)
	_glide_filters(delta)


func _fill_cafe_buffer(delta: float) -> void:
	if not _cafe_playback:
		return
	var frames := int(delta * 44100)
	if frames <= 0:
		return
	var buffer := PackedVector2Array()
	buffer.resize(frames)
	for i in range(frames):
		var sample := _generate_sample()
		buffer[i] = Vector2(sample, sample)
	_cafe_playback.push_buffer(buffer)


var _time: float = 0.0
var _chatter_state: float = 0.0
var _clink_timer: float = 0.0
var _clink_amp: float = 0.0


func _generate_sample() -> float:
	_time += 1.0 / 44100.0
	var room := 0.24 * (
		sin(TAU * 72.0 * _time) +
		0.45 * sin(TAU * 43.0 * _time) +
		0.7 * sin(TAU * 111.0 * _time) +
		0.35 * sin(TAU * 142.0 * _time)
	)
	_chatter_state += 0.008
	var noise := randf() * 2.0 - 1.0
	var chatter := 0.42 * (0.78 * noise + 0.22 * sin(_chatter_state * 2100.0))
	_clink_timer -= 1.0 / 44100.0
	if _clink_timer <= 0.0:
		_clink_timer = randf_range(0.08, 0.7)
		_clink_amp = randf_range(0.08, 0.52)
	var env := exp(-maxf(_clink_timer, 0.0) * 22.0)
	var clink := _clink_amp * env * 0.28 * sin(TAU * randf_range(3200.0, 6200.0) * _time)
	return clampf(room + chatter + clink, -1.0, 1.0)

