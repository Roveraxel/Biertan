## godot --headless --fixed-fps 30 -s tests/bot.gd -- <level> <until_flag> [flag,flag,...] [max_frames]
## Plays the road by following the quest pointer: stands on the target, presses E, reads every line,
## and knocks down whatever attacks. Prints each new objective, so a stuck quest shows as the last line.
extends SceneTree
func _initialize() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main); current_scene = main
	_run()
func _run() -> void:
	var G = root.get_node("G"); var Loader = root.get_node("Loader")
	var Enemy = load("res://scripts/actors/enemy.gd"); var Interact = load("res://scripts/actors/interact.gd"); var Quests = load("res://scripts/core/quests.gd")
	var a := OS.get_cmdline_user_args()
	G.instant = true
	await process_frame
	if a.size() > 2:
		for f in a[2].split(",", false): G.side_add(f)
	var max_frames := int(a[3]) if a.size() > 3 else 40000
	G.state = G.State.PLAY
	Loader.enter(a[0])
	var last := ""; var idle := 0; var sweep := 0.0; var stuck := 0
	for f in max_frames:
		await process_frame
		if G.side_has(a[1]):
			print("[%d] reached %s in %s" % [f, a[1], G.current])
			break
		if not is_instance_valid(G.level) or not is_instance_valid(G.player): continue
		G.player.hp = G.player.max_hp
		if G.state == G.State.DIALOGUE:
			if G.choosing_now(): G.dlg_sel = G.dlg_choices.size() - 1
			G.advance_dialogue()
			continue
		if G.transitioning or G.state != G.State.PLAY: continue
		var line: String = G.current + " | " + Quests.objective().split("(")[0]
		if line != last:
			last = line; stuck = 0
			print("[%d] %s" % [f, line])
		stuck += 1
		if stuck == 6000: print("   ...still there after 6000 frames; target=", Quests.target())
		if f % 6 == 0:
			for e in Enemy.all.duplicate():
				if is_instance_valid(e) and e.hp > 0.0 and e.kind != "cow": e.hurt(30.0, Vector2.RIGHT)
		if f % 15 != 0: continue
		var tg: Array = Quests.target()
		if tg.is_empty():
			# a boss with fires about: keep them lit and fight beside one, as anyone would
			var fires := get_nodes_in_group("interact").filter(func(n): return n.has_method("set_lit"))
			if is_instance_valid(G.boss) and not fires.is_empty():
				for n in fires:
					if n.can_interact(): n.interact()
				G.player.pos = fires[0].pos + Vector2(70, 0)
				continue
			idle += 1
			if idle > 8:   # nothing to point at: walk the middle of the place end to end, to trip whatever waits
				sweep = fmod(sweep + 90.0, G.level.size.x - 200.0)
				G.player.pos = Vector2(G.level.size.x - 100.0 - sweep, G.level.spawn.y)
			continue
		idle = 0
		G.player.pos = tg[0] + Vector2(0, 24)
		G.player.vel = Vector2.ZERO
		var n = Interact.nearest(G.player.pos)
		if n: n.interact()
		if tg[1].begins_with("Back") or tg[1].begins_with("The way back"):
			if G.level.has_method("leave"): G.level.leave()
			else: G.player.pos = Vector2(30, tg[0].y)   # step into the trigger at the map edge
	print("end: level=%s objective=%s target=%s coins=%d" % [G.current, Quests.objective(), Quests.target(), G.player.coins])
	var fl := []
	for k in G.side.keys():
		if not k.begins_with("seen_"): fl.append(k)
	print("flags: ", " ".join(fl))
	quit()
