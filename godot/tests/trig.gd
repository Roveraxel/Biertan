extends SceneTree
func _initialize() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main); current_scene = main
	_run()
func _run() -> void:
	var G = root.get_node("G"); var Loader = root.get_node("Loader")
	G.instant = true
	await process_frame
	G.state = G.State.PLAY
	Loader.enter("crit")
	for i in 5: await process_frame
	Loader.unload(); await process_frame
	Loader.enter("critforest")
	for i in 10: await process_frame
	G.player.pos = Vector2(30, 2600)
	for i in 30:
		await process_frame
		if i % 10 == 0: print(G.current, " ", G.player.pos, " tr=", G.transitioning, " st=", G.state)
	quit()
