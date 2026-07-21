extends Node
class_name SensoryCrimeLoop

signal phase_changed(from: int, to: int)
signal loop_resolved(insight_text: String)

enum Phase { OBSERVE, OVERLOAD, STIM, TUNE_IN, RESOLVE }

@export var auto_reset: bool = false
@export var reset_delay: float = 1.0

var _reset_source: Object
var _beat: InvestigationBeat
var current_phase := Phase.OBSERVE
var _reset_timer: float = 0.0


func _process(delta: float) -> void:
	if auto_reset and current_phase == Phase.RESOLVE:
		_reset_timer += delta
		if _reset_timer >= reset_delay:
			_reset_timer = 0.0
			reset_loop()


func bind(reset_source: Object = null, beat_node: InvestigationBeat = null) -> void:
	_reset_source = reset_source
	_beat = beat_node
	_add_watch_signals()


func trigger_overload() -> void:
	_try_advance(Phase.OVERLOAD)


func trigger_stim() -> void:
	_try_advance(Phase.STIM)


func trigger_tune_in() -> void:
	_try_advance(Phase.TUNE_IN)


func reset_loop() -> void:
	var prev := current_phase
	current_phase = Phase.OBSERVE
	_reset_timer = 0.0
	if prev != current_phase:
		phase_changed.emit(prev, current_phase)


func _try_advance(next: int) -> void:
	if not _is_legal(current_phase, next):
		return
	var prev := current_phase
	current_phase = next
	phase_changed.emit(prev, current_phase)


func _is_legal(from: int, to: int) -> bool:
	match from:
		Phase.OBSERVE:
			return to == Phase.OVERLOAD
		Phase.OVERLOAD:
			return to == Phase.STIM
		Phase.STIM:
			return to == Phase.TUNE_IN
		Phase.TUNE_IN:
			return to == Phase.RESOLVE
		Phase.RESOLVE:
			return false
		_:
			return false


func _add_watch_signals() -> void:
	if _beat and _beat.has_signal("beat_resolved"):
		if not _beat.is_connected("beat_resolved", _on_beat_resolved):
			_beat.beat_resolved.connect(_on_beat_resolved)
	if _reset_source and _reset_source.has_signal("reset_requested"):
		if not _reset_source.is_connected("reset_requested", reset_loop):
			_reset_source.reset_requested.connect(reset_loop)


func _on_beat_resolved(insight_text: String) -> void:
	if current_phase == Phase.TUNE_IN:
		var prev := current_phase
		current_phase = Phase.RESOLVE
		phase_changed.emit(prev, current_phase)
		loop_resolved.emit(insight_text)
