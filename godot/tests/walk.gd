## godot --headless --fixed-fps 30 -s tests/walk.gd
## Meister Thomas walks to the Butchers' Tower without passing through anything; Matei follows the hunter.
extends SceneTree
func _initialize() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main); current_scene = main
	_run()
func _run() -> void:
	var G = root.get_node("G"); var Loader = root.get_node("Loader")
	G.instant = true; G.test_mode = true
	await process_frame
	G.state = G.State.PLAY
	print("enter"); Loader.enter("sighisoara"); print("entered")
	await process_frame
	var b = G.level.butcher
	var t0 := Time.get_ticks_msec()
	G.level.butcher_to_tower()
	print("thomas path ms ", Time.get_ticks_msec() - t0, " points ", b.walk_path.size())
	var hits := 0
	for i in 3000:
		await process_frame
		if not G.level.is_free(b.pos, 2.0, b): hits += 1
		if b.walk_path.is_empty(): break
	print("thomas arrived ", b.pos.distance_to(G.level.butcher_at_tower) < 2.0, " inside-something frames ", hits)
	for k in ["vis_job", "vis_key", "vis_crypt", "vis_matei"]: G.side[k] = true
	Loader.enter("crypt")
	await process_frame
	var m = G.level.prop_by_id("matei")
	G.player.pos = Vector2(1400, 1150)
	var far := 0.0
	for i in 600:
		await process_frame
		G.player.pos += Vector2(-1.5, -0.8)   # walk him back towards the stairs
		if i > 120: far = maxf(far, m.pos.distance_to(G.player.pos))
	print("matei following ", m.following, " max gap after 4 s ", int(far))
	quit()
