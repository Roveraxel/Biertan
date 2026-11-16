extends SceneTree
func _initialize() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main); current_scene = main
	_run()
func _run() -> void:
	var G = root.get_node("G")
	G.instant = true
	await process_frame
	G.start_game()
	for i in 100: await process_frame
	var L = G.level
	for i in 6000:
		await process_frame
		if G.state == G.State.DIALOGUE: G.advance_dialogue()
		if L.step == 1: break
	print("step=", L.step, " state=", G.state, " frozen=", G.player.frozen, " pos=", G.player.pos, " az=", L.azorel.pos)
	for dir in ["move_right", "move_down", "move_left", "move_up"]:
		Input.action_press(dir)
		for i in 60: await physics_frame
		Input.action_release(dir)
		print(dir, " -> ", G.player.pos, " vel=", G.player.vel, " cols=", G.player.get_slide_collision_count())
	quit()
