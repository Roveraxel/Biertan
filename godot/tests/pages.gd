extends SceneTree
func _initialize() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main); current_scene = main
	_run()
func _run() -> void:
	var G = root.get_node("G"); var Loader = root.get_node("Loader"); var HM = root.get_node("HudMap")
	G.instant = true
	await process_frame
	HM.open_bestiary()
	for i in 40:
		HM.key(KEY_DOWN, false); await process_frame
	G.state = G.State.PLAY
	for f in ["map_unlocked", "seen_viscri", "vis_job", "token_cellar_key", "cr_job", "cr_done"]: G.side_add(f)
	Loader.enter("malcrypt")
	HM.open(true)
	for i in 12:
		HM.key(KEY_RIGHT, false); await process_frame
	HM.key(KEY_TAB, false)
	for i in 12:
		HM.key(KEY_DOWN, false); await process_frame
	HM.key(KEY_TAB, false); HM.sel = 1; await process_frame
	HM.key(KEY_ENTER, true)
	for i in 30: await process_frame
	print("pages ok; entries=", HM.entries.size(), " now in ", G.current)
	quit()
