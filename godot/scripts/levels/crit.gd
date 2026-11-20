## Criț (Deutsch-Kreuz), from the real village: the fortified church on its hill, the long streets, the old
## Orthodox graveyard down the road past the still, the mill and the hay meadow. Quest: The Friday Curse.
extends Village

var poppy_at := Vector2.ZERO

func build() -> void:
	title = "CRIȚ"
	subtitle = "Deutsch-Kreuz · The Friday Curse"
	quest = CritQuest.new()
	arrive_flag = "cr_arrive"
	standard("crit", 1270)
	for c in m.boxes("churches"): add_church(c, 78.0 if c.area > 250.0 else 56.0, c.area > 250.0, 0.75, 190.0)
	add_houses(44.0, 60.0)
	add_yard_walls()
	spawn = free_spot(Vector2(13000, 8800), 120.0)   # the road from Viscri comes in from the south-east
	_graves()
	plant_trees(400.0, 280.0, 0.55, 80.0, Vector2(13000, 8800))
	_quest_things()
	edge_walls()
	_road_stops()
	add_street_dressing()
	plant_gardens(9001, garden_ok)
	add_troita(quiet_spot(centre_spot()))   # last, so it can stand clear of the market, the carts and Floarea's yard

func _quest_things() -> void:
	var done := G.side_has("cr_done")
	var house := free_spot(Vector2(7500, 6950), 50.0)
	add_prop("npc", "floarea", "Floarea", house, "E   Speak with Floarea", Color("c8b8a0"))
	add_decor(house + Vector2(-50, -10), "bench", 20.0)
	add_prop("npc", "mother", "Floarea's mother", free_spot(house + Vector2(140, -60), 40.0), "E   Speak with Floarea's mother", Color("5a3a30"))
	add_torch(house + Vector2(60, -60), 220.0, Color(1, 0.6, 0.3), 0.6)
	var line := free_spot(house + Vector2(260, 40), 40.0)
	if not done:
		add_decor(line, "laundry"); add_decor(line + Vector2(70, 10), "linen")
	add_prop("clue", "laundry", "Laundry", line + Vector2(0, 30), "E   Look at the laundry")
	var well := free_spot(house + Vector2(-420, 120), 40.0)
	add_decor(well, "well", 45.0)
	add_decor(well + Vector2(60, 20), "lye")
	add_decor(well + Vector2(-60, 25), "washtub", 18.0)
	add_prop("npc", "rada", "Baba Rada", free_spot(well + Vector2(-130, 50), 30.0), "E   Speak with Baba Rada", Color("3a3430"))
	add_prop("task", "windlass", "Well windlass", well + Vector2(0, 60), "E   Tie a red knot")
	add_prop("clue", "lye", "Lye bucket", well + Vector2(60, 50), "E   Look at the bucket")
	var garden := free_spot(house + Vector2(-150, -320), 80.0)
	if near_road(garden, 85.0): garden = free_spot(house + Vector2(-240, -360), 80.0)
	add_decor(garden, "apples", 25.0); add_decor(garden + Vector2(110, 20), "apples", 25.0, true)
	add_decor(garden + Vector2(50, 60), "plums")
	add_prop("task", "apples", "Garden", garden + Vector2(50, 90), "E   Pick fruit")
	for w in [["baba_ana", "Baba Ana", Vector2(6000, 7300)], ["baba_safta", "Baba Safta", Vector2(9200, 6300)], ["baba_veta", "Baba Veta", Vector2(5000, 9200)]]:
		var p := free_spot(w[2], 40.0)
		add_prop("npc", w[0], w[1], p, "E   Speak with " + w[1], Color("3a3430"))
		add_decor(p + Vector2(-40, -10), "bench", 20.0)
	# the edge of the village: ribbons on the trees, an orchard/forest edge, and the old path into the forest
	var rib := free_spot(Vector2(11800, 5300), 40.0)
	add_decor(rib, "ribbons"); add_decor(rib + Vector2(90, -40), "ribbons", 0.0, true)
	for o in [Vector2(-110, -70), Vector2(140, -110), Vector2(40, -140), Vector2(-150, 60)]:
		var tp: Vector2 = free_spot(rib + o, 30.0)
		if not near_road(tp, 70.0) and not near_building(tp, 50.0): add_tree(tp, true)
	add_decor(free_spot(rib + Vector2(-80, 40), 25.0), "plum_tree", 20.0)
	add_decor(free_spot(rib + Vector2(130, 30), 25.0), "apples", 20.0)
	add_prop("clue", "ribbons", "Ribbons", rib + Vector2(0, 30), "E   Look at the ribbons")
	var gate := free_spot(Vector2(size.x - 220.0, 5600), 60.0)
	CritQuest.forest_gate = gate
	var path := free_spot(gate + Vector2(-260, 80), 30.0)
	add_path([rib + Vector2(40, 40), rib.lerp(gate, 0.5) + Vector2(0, 60), gate], 70.0)
	add_decor(path + Vector2(-70, -50), "stubs"); add_decor(path + Vector2(60, 70), "logs", 20.0)
	add_decor(gate + Vector2(-40, -90), "ribbons", 0.0, true)
	add_prop("clue", "path", "Old path", path, "E   Look at the path")
	add_prop("task", "forest", "Forest path", gate, "E   Follow the path into the forest")
	add_trigger(Rect2(size.x - 70.0, gate.y - 260.0, 70, 520), func(): Loader.goto_level("critforest"))
	# the old graveyard by the Orthodox church, poppies between the graves
	var cems := m.lines("cemeteries")
	var cem := centre(cems[0]) if not cems.is_empty() else Vector2(13900, 14600)
	poppy_at = free_spot(cem + Vector2(-60, 40), 30.0)
	if not G.side_has("cr_poppy"):
		add_decor(poppy_at, "poppies"); add_decor(poppy_at + Vector2(50, 20), "poppies", 0.0, true)
	else: add_decor(poppy_at, "petals")
	add_prop("task", "poppies", "Poppies", poppy_at + Vector2(20, 30), "E   Pick the poppies")
	for g in [Vector2(-150, -60), Vector2(120, -90), Vector2(-40, 140)]: add_decor(free_spot(poppy_at + g, 20.0), "grave_cross", 14.0)
	# the road north to Saschiz, and a troiță where the Viscri road comes in
	add_prop("task", "road", "Road to Saschiz", free_spot(Vector2(5500, 420), 40.0), "E   Take the road north")

func raise_the_dead() -> void:
	Audio.sfx("shriek", -6.0, 0.85)
	Hud.banner("THE DEAD RISE", "Something has been sleeping under the poppies.")
	add_decor(poppy_at + Vector2(-90, -30), "open_grave")
	var left := [3]
	var down := func(_e):
		left[0] -= 1
		if left[0] == 0:
			Hud.toast("The graveyard is quiet again.")
			G.side_add("cr_dead_rest")
	var s := spawn_enemy("strigoi", poppy_at + Vector2(-90, -30))
	s.state = "chase"
	s.died.connect(down)
	for o in [Vector2(160, 60), Vector2(-200, 120)]:
		var mo := spawn_enemy("moroi", poppy_at + o)
		mo.aggro = 600.0
		mo.died.connect(down)

## Along the road from Floarea's house to the graveyard: the țuică still, the mill, the hay meadow, the crossroads shrine.
func _road_stops() -> void:
	var from := Vector2(7500, 6950)
	var cem := centre(m.lines("cemeteries")[0])
	var on_road := func(t: float) -> Vector2:
		var want := from.lerp(cem, t); var best := want; var bd := 1e9
		for road in m.lines("roads"):
			for i in road.size() - 1:
				for k in 5:
					var q: Vector2 = road[i].lerp(road[i + 1], k * 0.25)
					if q.distance_to(want) < bd:
						bd = q.distance_to(want); best = q
		return best
	var side := (cem - from).normalized()
	side = Vector2(-side.y, side.x)
	var beside := func(t: float, off: float) -> Vector2: return free_spot(on_road.call(t) + side * off, 60.0)
	# 1. the țuică still: October is distilling time
	var still: Vector2 = beside.call(0.28, 230.0)
	add_decor(still, "cauldron", 22.0); add_decor(still + Vector2(70, 10), "barrel", 14.0); add_decor(still + Vector2(-80, 20), "bench", 10.0)
	add_decor(still + Vector2(30, 50), "tuica"); add_decor(still + Vector2(-40, -70), "firewood", 14.0)
	add_decor(still + Vector2(150, -60), "plum_tree", 20.0); add_decor(still + Vector2(-170, -40), "plum_tree", 20.0, true); add_decor(still + Vector2(110, 60), "plums")
	add_torch(still, 200.0, Color(1, 0.55, 0.25), 0.6)
	add_prop("npc", "distiller", "Nea Toma", free_spot(still + Vector2(-60, 70), 30.0), "E   Speak with Nea Toma", Color("5a4a3a"))
	# 2. the mill on the brook
	var mill: Vector2 = beside.call(0.5, -240.0)
	var bd := 1e9; var want: Vector2 = on_road.call(0.5)
	for st in m.lines("streams"):
		for q in st:
			var d: float = q.distance_to(want)
			if d < bd and d < 1400.0:
				bd = d; mill = free_spot(q + Vector2(90, 60), 60.0)
	add_decor(mill, "wheel", 20.0); add_decor(mill + Vector2(80, 20), "sacks", 14.0); add_decor(mill + Vector2(-70, 40), "sacks", 14.0, true)
	add_decor(mill + Vector2(120, 70), "handcart", 18.0); add_decor(mill + Vector2(-130, 80), "washtub", 12.0); add_decor(mill + Vector2(-200, 50), "clothesline")
	add_prop("npc", "millwife", "The miller's wife", free_spot(mill + Vector2(-110, 110), 30.0), "E   Speak with the miller's wife", Color("5a3a30"))
	add_prop("npc", "gerda", "Gerda · Miller's apprentice", free_spot(mill + Vector2(150, 130), 30.0), "E   Speak with Gerda", Color("6a5a4a"))
	if not G.side_has("cr_sub_found"):
		add_prop("task", "distaff", "Millrace", free_spot(mill + Vector2(20, 110), 30.0), "E   Look into the millrace")
	# 3. the hay meadow
	var hay: Vector2 = beside.call(0.7, 260.0)
	add_decor(hay, "haystack_plain", 26.0); add_decor(hay + Vector2(170, 40), "haystack_plain", 26.0, true); add_decor(hay + Vector2(-150, 70), "haystack_plain", 26.0)
	add_decor(hay + Vector2(40, 120), "haycart", 22.0); add_decor(hay + Vector2(-60, -90), "wheat_shock", 14.0); add_decor(hay + Vector2(110, -80), "wheat_shock", 14.0)
	# 4. the crossroads before the graveyard
	var cross_at: Vector2 = beside.call(0.88, -170.0)
	add_decor(cross_at, "shrine", 20.0); add_decor(cross_at + Vector2(34, 26), "candle"); add_decor(cross_at + Vector2(-40, 30), "petals")
	add_torch(cross_at, 170.0, Color(1, 0.6, 0.3), 0.5)
	add_prop("task", "crossroads", "Wayside shrine", cross_at + Vector2(0, 40), "E   Look at the shrine")

## Rows of wooden crosses and grassed mounds: the old Orthodox graveyard, a wattle fence round it and a few old trees.
func _graves() -> void:
	var n := 0
	for cem in m.lines("cemeteries"):
		var bb := bounds(cem)
		var x := bb.position.x + 60.0
		while x < bb.end.x and n < 70:
			var y := bb.position.y + 60.0
			while y < bb.end.y and n < 70:
				var p := Vector2(x + rng.f() * 24.0, y + rng.f() * 16.0)
				y += 150.0
				if not inside(p, cem) or near_building(p, 30.0) or near_road(p, 20.0): continue
				add_decor(p, "grave_mound")
				add_decor(p + Vector2(0, -22), "grave_cross", 10.0, rng.f() < 0.5)
				n += 1
			x += 130.0
		for i in cem.size():
			var a0: Vector2 = cem[i]; var a1: Vector2 = cem[(i + 1) % cem.size()]
			var length := a0.distance_to(a1)
			if length < 30.0: continue
			if ModelKit.exists("fence_post_rail"):
				var dir := (a1 - a0) / length
				var ang := rad_to_deg(-dir.angle())
				var count := maxi(1, int(round(length / 110.0)))
				var pw := length / float(count)
				for k in count:
					var q := a0.lerp(a1, (k + 0.5) / float(count))
					if not near_road(q, 55.0): add_block_rotated(q, Vector2(pw, 14.0), ang, "fence_rail", 18.0, true)
			else:
				var d := 0.0
				while d < length:
					var q := a0.lerp(a1, d / length)
					d += 58.0
					if not near_road(q, 60.0): add_decor(q, "wattle_fence", 12.0, i % 2 == 0)
		for k in 4:
			var t := Vector2(lerpf(bb.position.x, bb.end.x, 0.2 + 0.2 * k), lerpf(bb.position.y, bb.end.y, 0.15 if k % 2 == 0 else 0.85))
			if inside(t, cem) and not near_road(t, 60.0): add_tree(t, k % 2 == 1)
