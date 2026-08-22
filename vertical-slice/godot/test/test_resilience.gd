extends SceneTree

## Verification for resilience fallbacks (issue #59).
## Run: godot --headless --path . --script res://test/test_resilience.gd
## Asserts: FallbackNode no-ops are safe to call, current_charge() returns
## a sane value, for_missing() names/logs the gap, and FocusModeMain's
## installer substitutes fallbacks when a slot is empty.

const FN := preload("res://scripts/fallback_node.gd")


func _init() -> void:
	var failures := 0

	# 1. for_missing() builds a named fallback and reports the gap.
	var f: Node = FN.for_missing("StimTool", "StimTool")
	root.add_child(f)
	await process_frame
	if f.name != "StimTool":
		print("RES FAIL: fallback name %s != StimTool" % str(f.name))
		failures += 1

	# 2. Every documented no-op is safe to call.
	f.apply_presence(0.5)
	f.register_clue(null, null)
	f.resolve_clue("x")
	f.update_targets("Baseline", false, false, false)
	f.apply_chaos_band("low", 0.5)
	f.set_world_calm(0.5)
	f.press()
	f.update(0.016)
	f.release()
	f.disrupt(0.5)
	f.add_load(5.0)
	f.reduce_load(5.0)
	f.reset()
	f.toggle()
	await process_frame
	print("RES NOTE: all no-op calls completed without error")

	# 3. Queries return sane values.
	if f.current_charge() != 0.0:
		print("RES FAIL: current_charge() should be 0.0 on fallback")
		failures += 1

	# 4. Installer: a FocusModeMain with the stim slot cleared gets a
	#    fallback substituted rather than a null-deref crash later.
	var scene_res := load("res://scenes/focus_mode.tscn")
	if scene_res == null:
		print("RES FAIL: cannot load focus_mode.tscn")
		quit(1)
		return
	var scene: Node = (scene_res as PackedScene).instantiate()
	root.add_child(scene)
	for i in range(5):
		await process_frame
	# Simulate a missing node: free the stim tool, then run the installer.
	var stim: Node = scene.get("stim")
	if stim:
		stim.queue_free()
		scene.set("stim", null)
	scene._install_fallbacks_for_missing_nodes()
	var replaced: Node = scene.get("stim")
	if replaced == null or not is_instance_valid(replaced):
		print("RES FAIL: installer did not substitute a fallback for missing stim")
		failures += 1
	elif not replaced.has_method("press"):
		print("RES FAIL: substituted object lacks the no-op surface")
		failures += 1
	else:
		replaced.press()
		replaced.release()
		await process_frame
		print("RES NOTE: degraded stim path exercised without crash")

	scene.queue_free()
	f.queue_free()

	if failures > 0:
		print("RES FAIL: %d failure(s)" % failures)
		quit(1)
	else:
		print("RES PASS")
		quit(0)
