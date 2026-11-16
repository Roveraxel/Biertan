## Under Viscri's churchyard: the store vault, the bell chamber where the spellbound sexton waits, Matei's cell,
## and a tunnel bricked up long ago and opened again.
extends Level

const OPEN := [Rect2(100, 500, 300, 300), Rect2(400, 600, 100, 100), Rect2(500, 300, 600, 600), Rect2(1100, 500, 100, 200),
	Rect2(1200, 200, 700, 700), Rect2(1400, 900, 100, 100), Rect2(1300, 1000, 400, 300), Rect2(1900, 500, 100, 100), Rect2(2000, 450, 500, 200)]
const THINGS := [[560, 350, "barrel_rot"], [700, 340, "barrels"], [1050, 360, "barrel_rot"], [560, 860, "sacks"],
	[820, 860, "scraps"], [960, 820, "bone"], [640, 620, "bone"], [1040, 860, "crate"],
	[1240, 250, "chains"], [1840, 260, "chains"], [1600, 260, "bellrope"], [1860, 840, "barrel_rot"],
	[1250, 840, "lantern_iron"], [1340, 1050, "chains"], [1660, 1050, "chains"], [1660, 1250, "hay"],
	[2470, 550, "barrel_rot"], [2080, 620, "lantern_iron"]]

func build() -> void:
	title = "UNDER THE CHURCHYARD"
	subtitle = "Viscri"
	size = Vector2(2600, 1400)
	spawn = Vector2(260, 650)
	ground = Color("22201e")
	tile = ""
	quest = VisQuest.new()
	rng = NetRandom.new(1185)
	var beaten := G.side_has("vis_crypt")
	for yi in 14:
		for xi in 26:
			var c := Rect2(xi * 100.0, yi * 100.0, 100, 100)
			var open := false
			for r in OPEN:
				if r.has_point(c.get_center()):
					open = true
					break
			if not open: add_block(c, "stone", 70.0)
	add_block(Rect2(-200, -200, 3000, 200), "hidden", 0)
	add_block(Rect2(-200, 1400, 3000, 200), "hidden", 0)
	add_block(Rect2(-200, -200, 200, 1800), "hidden", 0)
	add_block(Rect2(2600, -200, 200, 1800), "hidden", 0)
	# the stair up
	for k in 4: add_decal(false, Vector2(106.0 + k * 14.0, 650), Vector2(14, 180), Color8(0x5a - k * 8, 0x52 - k * 8, 0x48 - k * 8), -988)
	add_torch(Vector2(150, 560), 200.0, Color(0.85, 0.8, 0.7), 0.55)
	add_trigger(Rect2(100, 560, 30, 180), func(): Loader.goto_level("viscri", VisQuest.crypt_door + Vector2(0, 70)))
	spots["stairs"] = Vector2(115, 650)
	for th in THINGS: add_decor(Vector2(th[0], th[1]), th[2], 0.0, rng.f() < 0.5)
	add_torch(Vector2(800, 600), 240.0, Color(1, 0.55, 0.28), 0.6)
	add_torch(Vector2(1550, 550), 280.0, Color(1, 0.5, 0.25), 0.75)
	add_torch(Vector2(1500, 1150), 200.0, Color(1, 0.55, 0.3), 0.5)
	add_torch(Vector2(2250, 550), 220.0, Color(0.7, 0.75, 1), 0.3)
	# the tunnel's mouth is rubble and brick; the far end is still blocked
	add_block(Rect2(2480, 450, 20, 200), "stone", 50.0)
	add_prop("task", "chalk", "Chalk sign", Vector2(2200, 480), "E   Look at the chalk sign")
	add_decor(Vector2(2200, 462), "chalk_sign", 0.0, rng.f() < 0.5)
	add_prop("task", "mapscrap", "Torn map", Vector2(2400, 610), "E   Pick up the torn map")
	add_decor(Vector2(2400, 600), "map_scrap", 0.0, rng.f() < 0.5)
	var matei := add_prop("npc", "matei", "Matei", Vector2(1500, 1200), "E   Speak with Matei", Color("6a5a40"))
	if G.side_has("vis_matei") and not G.side_has("vis_done"): matei.follow(true)
	if beaten: return
	for p in [Vector2(700, 450), Vector2(950, 700), Vector2(620, 780)]: spawn_enemy("thrall", p)
	for p in [Vector2(820, 400), Vector2(560, 700), Vector2(1000, 520), Vector2(880, 820), Vector2(1600, 1150), Vector2(1400, 1250)]: spawn_enemy("rat", p)
	for p in [Vector2(1350, 350), Vector2(1350, 800)]: spawn_enemy("thrall", p)
	var sexton := spawn_enemy("sexton", Vector2(1650, 550))
	spots["sexton"] = Vector2(1650, 550)
	sexton.call_thralls.connect(func(_s):
		for p in [Vector2(1260, 300), Vector2(1820, 300), Vector2(1820, 820)]: spawn_enemy("thrall", p)
		Hud.banner("THE BELL", "The sexton hauls on his rope. Footsteps come out of the dark."))
	sexton.died.connect(func(_s): _on_sexton())

func _on_sexton() -> void:
	G.side_add("vis_crypt")
	Audio.sfx("bell", -10.0, 0.8)
	Hud.banner("THE SEXTON FALLS", "The rope slips from his hands. Whatever held him lets go.")
	# the spellbound wake as themselves, dazed, and stumble back up to the village
	for e in Enemy.all.duplicate() + Enemy.fainted_ones.duplicate():
		if is_instance_valid(e) and e.kind == "thrall": e.queue_free()
	G.start_dialogue("The sexton", [
		"(The sexton blinks up at you like a man woken in a strange bed.) Where... this is my cellar. Why am I in my own cellar?",
		"I remember a voice. From the tunnel, from the west. It said the dogs must sleep. It said bring the boy.",
		"(He crosses himself. His hands are soft and clean, and his boots are new. Nobody in Viscri has new boots.)",
		"God forgive me. The boy is in the old cell. Go to him."])
