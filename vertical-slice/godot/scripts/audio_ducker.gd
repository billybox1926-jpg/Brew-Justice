extends Node
class_name AudioDucker

## Automatic audio ducking (issue #51): lowers ambient/SFX level while
## key audio (clue insight narration, dialogue) plays, then glides back.
## Amount and speed are configurable; the glide is exponential so it
## never clicks.

signal duck_started
signal duck_ended

const SFX_BUS_NAME := "SFX"

## How far ambient drops while ducked, in dB (negative = quieter).
@export var duck_amount_db: float = -8.0
## Seconds to reach full duck.
@export var duck_in_seconds: float = 0.15
## Seconds to release back to normal after key audio ends.
@export var duck_release_seconds: float = 0.6

var _bus_index: int = -1
var _base_db: float = 0.0
var _current_db: float = 0.0
var _target_db: float = 0.0
var _duck_requests: int = 0


func _ready() -> void:
	_bus_index = AudioServer.get_bus_index(SFX_BUS_NAME)
	if _bus_index == -1:
		push_warning("AudioDucker: no %s bus; ducking inactive" % SFX_BUS_NAME)
		return
	_base_db = AudioServer.get_bus_volume_db(_bus_index)
	_current_db = _base_db


## Call when key audio starts. Nestable: overlapping sources keep the duck
## until every one releases.
func push_duck() -> void:
	if _bus_index == -1:
		return
	_duck_requests += 1
	if _duck_requests == 1:
		_target_db = _base_db + duck_amount_db
		duck_started.emit()


## Call when a piece of key audio ends.
func pop_duck() -> void:
	if _bus_index == -1:
		return
	_duck_requests = maxi(_duck_requests - 1, 0)
	if _duck_requests == 0:
		_target_db = _base_db
		duck_ended.emit()


func is_ducking() -> bool:
	return _duck_requests > 0


func _process(delta: float) -> void:
	if _bus_index == -1 or is_equal_approx(_current_db, _target_db):
		return
	var speed := delta / duck_in_seconds if is_ducking() else delta / duck_release_seconds
	_current_db = move_toward(_current_db, _target_db, absf(duck_amount_db) * speed)
	AudioServer.set_bus_volume_db(_bus_index, _current_db)
