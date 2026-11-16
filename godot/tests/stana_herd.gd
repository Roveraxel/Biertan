## godot --headless --fixed-fps 30 -s tests/stana_herd.gd
## The cows: harmless, walk round the fence into the fold once the gate is open; Azorel never inside a fence.
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
	Loader.enter("stana")
	await process_frame
	var L = G.level
	L.step = 1; G.player.frozen = false; L.azorel_coming = false
	var c0 = L.cows[0]; var hp0: float = c0.hp
	c0.hurt(20.0, Vector2.RIGHT)
	print("cow hp unchanged ", c0.hp == hp0, "  unarmed ", G.player.unarmed)
	L._open_gate()
	for c in L.cows: L.roused[c] = true
	var stuck_dog := 0
	for i in 2400:
		await process_frame
		G.player.pos = Vector2(1500, 1270)   # stands out of the way, below the gate
		if not L.is_free(L.azorel.pos, 0.0, L.azorel): stuck_dog += 1
		if L.penned() == L.cows.size(): print("all penned after frames ", i); break
	print("penned ", L.penned(), "/", L.cows.size(), "  dog-in-something frames ", stuck_dog)
	for c in L.cows: if not L.FOLD.has_point(c.pos): print("  out: ", c.pos)
	quit()
