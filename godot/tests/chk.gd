extends SceneTree
func _initialize() -> void:
	_run()
func _run() -> void:
	await process_frame
	for f in OS.get_cmdline_user_args():
		var s = load(f)
		print(f, " -> ", s, " can_instantiate=", s.can_instantiate() if s else false)
	quit()
