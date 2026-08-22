extends SceneTree

## Golden-path smoke check for audio ducking (issue #51).
## Run: godot --headless --path . --script res://test/test_audio_ducker.gd
## Asserts: duck engages on push, reaches target within duck_in_seconds,
## releases to base after pop + release window, nested pushes hold until
## the last pop, and config values are honored.

const DUCKER := preload("res://scripts/audio_ducker.gd")


func _init() -> void:
	var failures := 0
	# AudioBusManager owns SFX bus creation; instantiate it first so the
	# bus exists before the ducker's _ready caches the index.
	root.add_child(load("res://scripts/audio_bus_manager.gd").new())
	var d: Node = DUCKER.new()
	d.duck_amount_db = -8.0
	d.duck_in_seconds = 0.1
	d.duck_release_seconds = 0.2
	root.add_child(d)
	await process_frame

	var sfx := AudioServer.get_bus_index("SFX")
	if sfx == -1:
		print("DUCK FAIL: no SFX bus")
		quit(1)
		return

	var started := [false]
	var ended := [false]
	d.duck_started.connect(func() -> void: started[0] = true)
	d.duck_ended.connect(func() -> void: ended[0] = true)

	# 1. Push ducks toward base + amount.
	d.push_duck()
	if not started[0]:
		print("DUCK FAIL: duck_started not emitted on first push")
		failures += 1
	await create_timer(d.duck_in_seconds * 3.0).timeout
	var expected: float = -8.0
	var got: float = AudioServer.get_bus_volume_db(sfx)
	if absf(got - expected) > 0.5:
		print("DUCK FAIL: volume %f dB, expected ~%f" % [got, expected])
		failures += 1

	# 2. Nested push holds; single pop does not release.
	d.push_duck()
	d.pop_duck()
	if not d.is_ducking():
		print("DUCK FAIL: is_ducking() false while a request is outstanding")
		failures += 1
	await create_timer(d.duck_release_seconds * 2.0).timeout
	got = AudioServer.get_bus_volume_db(sfx)
	if absf(got - expected) > 0.5:
		print("DUCK FAIL: released early with outstanding request (%f dB)" % got)
		failures += 1

	# 3. Final pop releases back to base.
	d.pop_duck()
	if not ended[0]:
		print("DUCK FAIL: duck_ended not emitted on final pop")
		failures += 1
	await create_timer(d.duck_release_seconds * 3.0).timeout
	got = AudioServer.get_bus_volume_db(sfx)
	if absf(got) > 0.5:
		print("DUCK FAIL: did not return to base 0 dB (got %f)" % got)
		failures += 1

	d.queue_free()

	if failures > 0:
		print("DUCK FAIL: %d failure(s)" % failures)
		quit(1)
	else:
		print("DUCK PASS")
		quit(0)
