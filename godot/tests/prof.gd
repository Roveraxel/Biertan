extends SceneTree
func _initialize() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main); current_scene = main
	_run()
func _run() -> void:
	var G = root.get_node("G")
	G.instant = true
	await process_frame
	var id: String = OS.get_cmdline_user_args()[0]
	var level = load("res://scripts/levels/%s.gd" % id).new()
	level.id = id; G.current = id; G.level = level
	root.add_child(level)
	var t0 := Time.get_ticks_msec()
	level.build()
	print("build ms ", Time.get_ticks_msec() - t0, " blocks ", level.blocks.size(), " decors ", level.decors.size(), " trees ", level.trees.size()); t0 = Time.get_ticks_msec()
	load("res://scripts/world/world_builder.gd").build(level)
	print("world ms ", Time.get_ticks_msec() - t0)
	quit()
