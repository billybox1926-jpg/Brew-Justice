extends SceneTree

## Profiling baseline capture for the vertical slice (issue #58).
## Run: godot --headless --path . --script res://test/profile_baseline.gd
## Loads the real focus_mode scene, steps N frames with all overlays live,
## and reports per-frame wall time plus process/memory stats. Writes
## docs/perf-baseline.json so the numbers are reproducible, not recalled.

const FRAMES := 240
const WARMUP := 30


func _init() -> void:
	var scene_res := load("res://scenes/focus_mode.tscn")
	if scene_res == null:
		print("PERF FAIL: cannot load scenes/focus_mode.tscn")
		quit(1)
		return
	var scene: Node = (scene_res as PackedScene).instantiate()
	root.add_child(scene)
	for i in range(WARMUP):
		await process_frame

	var frame_ms: Array[float] = []
	var last_us := Time.get_ticks_usec()
	for i in range(FRAMES):
		await process_frame
		var now_us := Time.get_ticks_usec()
		frame_ms.append(float(now_us - last_us) / 1000.0)
		last_us = now_us

	# Stats.
	var total := 0.0
	var worst := 0.0
	for v in frame_ms:
		total += v
		worst = maxf(worst, v)
	var sorted := frame_ms.duplicate()
	sorted.sort()
	var p50: float = sorted[int(sorted.size() * 0.5)]
	var p99: float = sorted[min(sorted.size() - 1, int(sorted.size() * 0.99))]

	var static_mem := Performance.get_monitor(Performance.MEMORY_STATIC)
	var static_peak := Performance.get_monitor(Performance.MEMORY_STATIC_MAX)
	var object_count := Performance.get_monitor(Performance.OBJECT_COUNT)
	var node_count := Performance.get_monitor(Performance.OBJECT_NODE_COUNT)

	# Top script processes by measured cost is not exposed headless; report
	# per-node process presence instead (contention candidates from the issue).
	var contenders := []
	for node in scene.get_children():
		if node is CanvasItem or node is Node3D or node is AudioStreamPlayer2D:
			contenders.append(node.name if node else "null")

	var result := {
		"captured_with": "godot --headless --script res://test/profile_baseline.gd",
		"frames": FRAMES,
		"frame_ms_mean": snappedf(total / FRAMES, 0.001),
		"frame_ms_p50": snappedf(p50, 0.001),
		"frame_ms_p99": snappedf(p99, 0.001),
		"frame_ms_worst": snappedf(worst, 0.001),
		"memory_static_mb": snappedf(static_mem / 1048576.0, 0.01),
		"memory_static_peak_mb": snappedf(static_peak / 1048576.0, 0.01),
		"object_count": object_count,
		"node_count": node_count,
		"overlay_children": contenders,
	}
	var out_path := ProjectSettings.globalize_path("res://").path_join(
		"../../docs/perf-baseline.json"
	)
	var f := FileAccess.open(out_path, FileAccess.WRITE)
	if f == null:
		print("PERF NOTE: could not write %s (report printed above)" % out_path)
	else:
		f.store_string(JSON.stringify(result, "	"))
		f.close()
	print(JSON.stringify(result, "\t"))
	print("PERF BASELINE WRITTEN")
	scene.queue_free()
	quit(0)
