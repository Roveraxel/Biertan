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
	level.build()
	var W = load("res://scripts/world/world_builder.gd")
	W.L = level; W.root = Node3D.new(); level.add_child(W.root); W.wall_ends.clear()
	for f in ["_ground", "_roads", "_decals", "_prep_houses", "_blocks", "_trees", "_wilds"]:
		var t0 := Time.get_ticks_msec()
		if f == "_blocks":
			W._static.clear()
			for b in level.blocks: W._block(b)
			for k in W._static: W._static[k].commit(W.root, "Stones")
		else: W.call(f)
		print(f, " ms ", Time.get_ticks_msec() - t0)
	quit()
