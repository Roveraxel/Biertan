## godot --headless -s tests/load.gd -- <level> [<level> ...] : builds each level and prints what stands in it
extends SceneTree
func _initialize() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main); current_scene = main
	_run()
func _run() -> void:
	var G = root.get_node("G"); var Loader = root.get_node("Loader")
	G.instant = true
	await process_frame
	for id in OS.get_cmdline_user_args():
		var t0 := Time.get_ticks_msec()
		G.state = G.State.PLAY
		Loader.unload()
		Loader.enter(id)
		var L = G.level
		for i in 20: await process_frame
		print("%s: %d ms  size=%s spawn=%s blocks=%d trees=%d decors=%d props=%d interact=%d cut=%d  objective=%s target=%s" % [id, Time.get_ticks_msec() - t0, L.size, L.spawn, L.blocks.size(), L.trees.size(), L.decors.size(), L.props.size(), get_nodes_in_group('interact').size(), L.cutaways.size(), (L.quest if L.quest else L).objective(), (L.quest if L.quest else L).target()])
		print("   spots: ", L.spots)
	quit()
