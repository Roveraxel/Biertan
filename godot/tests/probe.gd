## Headless smoke test: godot --headless -s tests/probe.gd  (plays the prologue with no fades)
extends SceneTree

func _initialize() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	current_scene = main
	_run()

func _run() -> void:
	var G = root.get_node("G"); var Loader = root.get_node("Loader")
	G.test_mode = true
	await process_frame
	G.start_game()
	for i in 600: await process_frame
	var L = G.level
	print("level=", G.current, " state=", G.state, " step=", L.step, " trees=", L.trees.size(), " decors=", L.decors.size(), " cows=", L.cows.size(), " world_children=", L.get_node("World").get_child_count())
	print("player=", G.player.pos, " frozen=", G.player.frozen, " azorel=", L.azorel.pos, " dlg=", G.dlg_speaker)
	while G.state == G.State.DIALOGUE:
		G.advance_dialogue()
		await process_frame
	for i in 30: await process_frame
	print("after wake: step=", L.step, " frozen=", G.player.frozen)
	# teleport the herd in, close the gate, kill the wolves
	for c in L.cows: c.pos = L.FOLD.get_center() + Vector2(randf_range(-100, 100), randf_range(-100, 100))
	for i in 10: await process_frame
	print("penned=", L.penned(), " objective=", L.objective(), " target=", L.target())
	G.player.pos = L.GATE + Vector2(-60, 0)
	L.use(L.gate)
	for i in 400: await process_frame
	print("step=", L.step, " wolves=", L.wolves.size(), " decors=", L.decors.size())
	for n in 2000:
		await process_frame
		for w in L.wolves:
			if is_instance_valid(w) and w.hp > 0: w.hurt(50, Vector2.RIGHT)
		if G.state == G.State.DIALOGUE: G.advance_dialogue()
		if G.current != "stana" or L.step == 3 and G.side_has("prologue_done"): break
	print("end: step=", L.step if is_instance_valid(L) else -1, " side=", G.side.keys(), " hp=", G.player.hp, " coins=", G.player.coins)
	quit()
