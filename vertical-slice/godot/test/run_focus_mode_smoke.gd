extends SceneTree

func _init():
	var smoke := load("res://test/focus_mode_smoke.gd").new()
	get_root().add_child(smoke)
