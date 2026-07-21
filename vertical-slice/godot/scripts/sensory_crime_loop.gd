extends Node
class_name SensoryCrimeLoop

signal phase_changed(from: int, to: int)
signal loop_resolved(insight_text: String)

enum Phase { OBSERVE, OVERLOAD, STIM, TUNE_IN, RESOLVE }

@export var auto_reset: bool = false
@export var reset_delay: float = 1.0

var focus_main: FocusModeMain
var investigation_beat: InvestigationBeat
var current_phase := Phase.OBSERVE
var _reset_timer: float = 0.0


func _process(delta: float) -> void:
	if auto_reset and current_phase == Phase.RESOLVE:
		_reset_timer += delta
		if _reset_timer >= reset_delay:
			_reset_timer = 0.0
			reset_loop()


func bind(focus_node: FocusModeMain, beat_node: InvestigationBeat) -> void:
	focus_main = focus_node
	investigation_beat = beat_node
	_snapshot_start_phase()
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


func _snapshot_start_phase() -> void:
	if focus_main:
		current_phase = _map_focus_phase(focus_main.investigation_phase)
	else:
		current_phase = Phase.OBSERVE


func _map_focus_phase(phase: int) -> int:
	if not focus_main:
		return Phase.OBSERVE
	match phase:
		focus_main.InvestigationPhase.Observe:
			return Phase.OBSERVE
		focus_main.InvestigationPhase.TuneIn:
			return Phase.TUNE_IN
		focus_main.InvestigationPhase.Resolve, focus_main.InvestigationPhase.Resolved:
			return Phase.RESOLVE
		_:
			return Phase.OBSERVE


func _add_watch_signals() -> void:
	if investigation_beat and investigation_beat.has_signal("beat_resolved"):
		if not investigation_beat.is_connected("beat_resolved", _on_beat_resolved):
			investigation_beat.beat_resolved.connect(_on_beat_resolved)
	if focus_main and focus_main.has_signal("reset_requested"):
		if not focus_main.is_connected("reset_requested", reset_loop):
			focus_main.reset_requested.connect(reset_loop)


func _on_beat_resolved(insight_text: String) -> void:
	if current_phase == Phase.TUNE_IN:
		var prev := current_phase
		current_phase = Phase.RESOLVE
		phase_changed.emit(prev, current_phase)
		loop_resolved.emit(insight_text)
