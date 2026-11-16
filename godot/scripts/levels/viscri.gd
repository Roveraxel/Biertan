## Viscri (Deutsch-Weißkirch), laid out from the real village: the fortified church on its hill inside a ring
## wall, the church lane down to the junction, and the long main street of gable-fronted farmhouses. The hunter
## arrives on Vlad's cart from Sighișoara. Quest: The Silent Dogs.
extends Village

var fort: Array
var gate_c := Vector2.ZERO
var road_prop: Prop
var barn_at := Vector2.ZERO
var goose_at := Vector2.ZERO
var lane_top := Vector2.ZERO

func build() -> void:
	title = "VISCRI"
	subtitle = "Deutsch-Weißkirch · The village with the white church"
	load_map("viscri")
	quest = VisQuest.new()
	arrive_flag = "vis_arrive"
	ground = Color("2a3224")
	tile = "tile_grass_village"
	rng = NetRandom.new(1185)
	road_min_half = 40.0
	fort = m.lines("fort")[0]
	building_sets = [[m.boxes("houses"), 0.0], [m.boxes("church"), 60.0]]
	wall_lines = m.lines("yardwalls") + [fort]
	free_spot(Vector2(13250, 3560), 120.0, 40.0, 800.0)
	scatter(Rect2(Vector2.ZERO, size), 360, [Color("363e2a"), Color("2a2e22"), Color("444230")])
	var roads := m.lines("roads")
	for i in roads.size():
		var w: float = m.road_width[i]
		add_path(roads[i], w, Color.WHITE, -990, "Cobbles" if w >= 140.0 else "Path")
	# the church on the hill; every wall opens where a road or path runs through it: the gate under the tower, the yard gates
	var gate: Dictionary = m.boxes("towers")[0]
	gate_c = gate.c
	var gaps := crossings(fort)
	gaps.append([gate.c, 150.0])
	for run in cut_at(fort, gaps): add_curtain(run, 50.0, 50.0, "ring")
	add_block_rotated(gate.c, gate.size, gate.angle, "tower", 150.0, false)
	_gate_shoulders(gate)
	for c in m.boxes("church"): add_church(c, 80.0, true, 0.8, 210.0)
	for b in m.boxes("houses"):
		var sz: Vector2 = b.size
		var tries := 0
		while tries < 3 and blocks_street(b.c, sz, b.angle):
			sz *= 0.8; tries += 1
		if blocks_street(b.c, sz, b.angle): continue
		add_block_rotated(b.c, sz, b.angle, "house", 62.0 if b.style == "barn" else 46.0 + rng.f() * 12.0)
	# the low walls with their gates that join house to house along the street
	for w in m.lines("yardwalls"):
		for run in cut_at(w, crossings(w)): add_curtain(run, 16.0, 18.0, "ring")
	spawn = free_spot(Vector2(13250, 3560), 120.0, 40.0, 800.0)   # where the lane from Bunești meets the main street
	if Loader.direct_start:
		# dropped straight into the level (testing): start on the path in front of the church gate
		spawn = free_spot(gate.c + (gate.c - m.boxes("church")[0].c).normalized() * 320.0, 60.0, 40.0, 800.0)
		G.side_add("vis_arrive")
	add_graves()
	_trees()
	_quest_things()
	edge_walls()
	_fort_life()
	plant_gardens(9001, garden_ok)

func free_ok(p: Vector2, _from: Vector2) -> bool:
	return not near_wall(p, 40.0) and not inside(p, fort) and p.x > 80.0 and p.y > 80.0 and p.x < size.x - 80.0 and p.y < size.y - 80.0

func _free(g: Vector2, clear := 18.0) -> Vector2:
	return free_spot(g, clear, 40.0, 800.0)

func _trees() -> void:
	var n := 0
	var x := 120.0
	while x < size.x - 120.0:
		var y := 120.0
		while y < size.y - 120.0:
			if n >= 220: return
			var p := Vector2(x + (rng.f() - 0.5) * 260.0, y + (rng.f() - 0.5) * 260.0)
			y += 380.0
			var wood := false
			for w in m.lines("woods"):
				if inside(p, w):
					wood = true
					break
			if not wood and rng.f() < 0.6: continue
			if inside(p, fort) or near_road(p, 70.0) or near_building(p, 90.0) or near_wall(p, 100.0): continue
			if p.distance_to(spawn) < 300.0: continue
			add_tree(p, wood and rng.f() < 0.3)
			n += 1
		x += 380.0

func _ring_dist(p: Vector2) -> float:
	var best := INF
	for k in fort.size() - 1: best = minf(best, seg_dist(p, fort[k], fort[k + 1]))
	return best

func _inside_fort(g: Vector2) -> Vector2:
	var ok := func(p: Vector2) -> bool:
		var d := _ring_dist(p)
		return inside(p, fort) and not near_building(p, 30.0) and d > 50.0 and d < 140.0
	if ok.call(g): return g
	var r := 30.0
	while r <= 600.0:
		for k in 16:
			var p := g + Vector2.from_angle(k * PI / 8.0) * r
			if ok.call(p): return p
		r += 30.0
	return g

## The gate tower is walked through under its vault, so the tower itself is not solid; its two shoulders are,
## either side of a passage as wide as a cart, so nobody walks through its walls.
func _gate_shoulders(t: Dictionary) -> void:
	const PASS := 110.0
	var best := INF; var dir := Vector2.RIGHT
	for i in fort.size() - 1:
		var d := seg_dist(t.c, fort[i], fort[i + 1])
		if d < best and (fort[i + 1] - fort[i]).length_squared() > 1.0:
			best = d; dir = (fort[i + 1] - fort[i]).normalized()
	var wall_angle := rad_to_deg(atan2(-dir.y, dir.x))
	var span := maxf(t.size.x, t.size.y)
	var half := maxf(30.0, (span - PASS) / 2.0)
	for side in [-1.0, 1.0]:
		add_block_rotated(t.c + dir * side * (PASS / 2.0 + half / 2.0), Vector2(half, minf(t.size.x, t.size.y)), wall_angle, "hidden", 100.0)

var _lane := Vector2.ZERO
## Where Matei runs home to: down the main street.
func church_lane() -> Vector2: return _lane

func _quest_things() -> void:
	var done := G.side_has("vis_done")
	var barking := G.side_has("vis_crypt")
	# the main street runs south-west to north-east; its north-west side faces the church hill
	var sa := Vector2(10500, 6210); var sb := Vector2(13000, 3670)
	var d := (sb - sa).normalized()
	var nw := Vector2(-d.y, d.x)
	if nw.y > 0.0: nw = -nw
	var street := func(t: float, side: float) -> Vector2: return sa.lerp(sb, t) + nw * side
	_lane = street.call(0.25, 0.0)
	var lorena := _free(street.call(0.55, 120.0), 40.0)
	var taken := VisQuest.taken()   # the baron came up through the cellars and took her
	if taken:
		add_prop("task", "lorenagate", "Lorena's gate", lorena, "E   Look at the gate")
		add_decor(lorena + Vector2(-70, -20), "chair", 0.0, true)
		add_decor(lorena + Vector2(60, 10), "potlid")
		add_prop("task", "v3road", "The road to Sighișoara", _free(spawn + Vector2(60, 90), 40.0), "E   Take the road to Sighișoara")
	else: add_prop("npc", "lorena", "Lorena", lorena, "E   Speak with Lorena", Color("5a3a30"))
	# Azorel at the edge of the village until he goes to Lorena
	add_prop("npc", "azorel", "Azorel", _free(lorena + Vector2(70, 30), 40.0) if done else _free(spawn + Vector2(-90, 50), 50.0), "E   Azorel", Color("d8d0c0"))
	add_torch(lorena + Vector2(0, -40), 220.0, Color(1, 0.6, 0.3), 0.7)
	if G.side_has("vis_matei") and not done:   # the boy came up out of the cellar with you
		var m := add_prop("npc", "matei", "Matei", _free(spawn + Vector2(-40, 30), 30.0), "E   Speak with Matei", Color("6a5a40"))
		m.follow(true)
	# the witnesses
	var butcher := _free(Vector2(9580, 6830), 40.0)
	add_prop("npc", "vbutcher", "Hans · Butcher", butcher, "E   Speak with Hans", Color("6a3a30"))
	add_decor(butcher + Vector2(60, -10), "chopping_block", 20.0)
	add_decor(butcher + Vector2(-70, -20), "hams_rack", 30.0)
	add_torch(butcher + Vector2(0, -40), 200.0, Color(1, 0.6, 0.3), 0.55)
	var goose := _free(Vector2(6330, 6000), 60.0)
	add_prop("npc", "goosewife", "Katharina · Goose-keeper", _free(goose + Vector2(120, 60), 30.0), "E   Speak with Katharina", Color("5a4a5a"))
	add_decor(goose, "goose_pen", 50.0)
	add_decor(goose + Vector2(-30, 10), "goose" if barking else "goose_honk")
	add_decor(goose + Vector2(25, -8), "goose", 0.0, true)
	add_decor(goose + Vector2(5, 22), "goose")
	add_prop("clue", "geese", "Geese", goose + Vector2(0, 40), "E   Look at the geese")
	var caretaker := _free(gate_c + Vector2(260, 220), 40.0)
	add_prop("npc", "caretaker", "Michael · Church caretaker", caretaker, "E   Speak with Michael", Color("4a4a40"))
	add_torch(gate_c + Vector2(0, 120), 240.0, Color(1, 0.58, 0.28), 0.7)
	# the clues: dogs asleep on full bellies all down the street, scraps up the church lane
	var dog := _free(street.call(0.12, -130.0), 30.0)
	add_decor(dog, "dog_bark" if barking else "dog_sleep", 20.0)
	add_decor(dog + Vector2(50, 20), "kennel", 30.0)
	add_prop("clue", "dog", "Yard dog" if barking else "Sleeping dog", dog + Vector2(0, 30), "E   Look at the dog")
	for p in [Vector2(12400, 4300), Vector2(11700, 4900), Vector2(9000, 7100), Vector2(8000, 8200), Vector2(12900, 3900), Vector2(7400, 6400)]:
		add_decor(_free(p, 30.0), "dog_bark" if barking else "dog_sleep", 18.0, rng.f() < 0.5)
	var lane0 := Vector2(7700, 6700); var lane1 := gate_c + Vector2(300, 300)
	for i in 9:
		var p := lane0.lerp(lane1, i / 8.0) + Vector2((rng.f() - 0.5) * 60.0, (rng.f() - 0.5) * 60.0)
		if not barking or i % 3 == 0: add_decor(_free(p, 20.0), "scraps" if i % 2 == 0 else "bone")
	add_prop("clue", "scraps", "Meat scraps", _free(lane0.lerp(lane1, 0.25), 20.0), "E   Look at the scraps")
	# the old barn on the church lane, where the hunter keeps watch
	var barn := _free(Vector2(6670, 5830), 40.0)
	barn_at = barn; goose_at = goose; lane_top = lane1
	# the yard gate beside the barn, and the gate across the road out to Criț
	if gap_gate(barn, 600.0) == null: WoodGate.make(self, _free(barn + Vector2(0, 160), 60.0), 170.0, 0.0, "Yard gate")
	add_decor(barn, "hay", 40.0)
	add_decor(barn + Vector2(70, -20), "haycart", 55.0)
	add_prop("task", "barn", "Old barn", barn + Vector2(0, 40), "E   Watch the barn")
	# the cellar door, in the churchyard wall just inside the gate
	var near_door := _inside_fort(gate_c + (m.boxes("church")[0].c - gate_c).normalized() * 260.0 + Vector2(-180, 0))
	var door := wall_door(near_door, 900.0, func(q: Vector2) -> bool: return inside(q, fort)) + Vector2(0, 14)   # in the wall of a building in the churchyard
	VisQuest.crypt_door = door
	add_decor(door + Vector2(0, -6), "cellar_door")
	add_prop("task", "cryptdoor", "Cellar door", door + Vector2(0, 20), "E   Open the cellar door")
	add_decor(door + Vector2(40, 0), "lantern_iron")
	add_torch(door, 180.0, Color(1, 0.55, 0.25), 0.55)
	# a troiță where the lane from Bunești meets the street: with Lorena's map, roads to anywhere he has been
	var tr := _free(spawn + Vector2(160, -150), 40.0)
	add_decor(tr, "troita", 22.0)
	add_prop("troita", "troita", "Troiță", tr + Vector2(0, 30), "E   Pray at the troiță")
	# the road south to Criț
	var road := _free(Vector2(7420, size.y - 260.0), 40.0)
	road_prop = add_prop("task", "road", "Road to Criț", road, "E   Take the road south")
	road_gate(road + Vector2(0, -260), "Village gate")
	add_trigger(Rect2(road.x - 260.0, size.y - 70.0, 520, 70), func(): quest.use(road_prop))
	# a few villagers' things along the street
	for it in [[Vector2(12000, 4600), "barrel_rot"], [Vector2(11300, 5150), "firewood"], [Vector2(10100, 6300), "handcart"], [Vector2(9300, 6950), "trough"], [Vector2(8600, 7700), "well"], [Vector2(12600, 4150), "laundry"]]:
		add_decor(_free(it[0], 30.0), it[1], 0.0 if it[1] == "laundry" else 24.0)

## Life inside the church ring: the Speckturm where every family hangs its bacon, the grain stores along the
## wall, children and geese in the yard, and a smithy outside by the gate.
func _fort_life() -> void:
	var church: Vector2 = m.boxes("church")[0].c
	var inward := (church - gate_c).normalized(); var side := Vector2(-inward.y, inward.x)
	var ham := _inside_fort(church + Vector2(560, 10))   # the open yard east of the church: no wall or roof hides her
	add_decor(ham, "hams_rack", 24.0); add_decor(ham + Vector2(90, 6), "hams_rack", 24.0, true); add_decor(ham + Vector2(-70, 10), "ladder")
	add_decor(ham + Vector2(40, 60), "salt_barrel", 14.0); add_decor(ham + Vector2(-30, 64), "chopping_block", 10.0)
	add_torch(ham, 180.0, Color(1, 0.6, 0.3), 0.5)
	add_prop("npc", "hamkeeper", "Old Greta · Keeper of the bacon tower", ham + Vector2(20, 100), "E   Speak with Old Greta", Color("5a4a5a"))
	var store := _inside_fort(church - side * 330.0)
	add_decor(store, "sacks", 14.0); add_decor(store + Vector2(60, 14), "barrels", 16.0); add_decor(store + Vector2(-64, 10), "crate", 14.0)
	add_decor(store + Vector2(130, 30), "sacks", 14.0, true); add_decor(store + Vector2(-130, 30), "handcart", 18.0)
	add_prop("npc", "storeman", "Georg · Airing the grain", store + Vector2(10, 80), "E   Speak with Georg", Color("4a4a40"))
	var yard := _inside_fort(church + inward * 260.0 + side * 120.0)
	add_decor(yard, "goose"); add_decor(yard + Vector2(50, 24), "goose_honk", 0.0, true); add_decor(yard + Vector2(-46, 30), "goose", 0.0, true)
	add_prop("npc", "fortkid", "Children", yard + Vector2(10, 80), "E   Speak with the children", Color("6a5a40"))
	var smithy := _free(gate_c - inward * 330.0 + side * 260.0, 60.0)
	add_decor(smithy, "oven", 24.0); add_decor(smithy + Vector2(80, 30), "chopping_block", 10.0); add_decor(smithy + Vector2(-80, 30), "firewood", 14.0)
	add_decor(smithy + Vector2(130, 10), "wheel"); add_decor(smithy + Vector2(-140, 20), "barrel", 14.0)
	add_torch(smithy, 220.0, Color(1, 0.5, 0.2), 0.8)
	add_prop("npc", "vsmith", "Hannes · Smith", smithy + Vector2(20, 90), "E   Speak with the smith", Color("4a3a30"))

## The night watch from the barn, played out: the hooded sexton comes down the lane with his sack, feeds the
## dogs yard by yard, the geese scream, he drops his key and hurries back up to the churchyard.
func watch_barn(done: Callable) -> void:
	var pl: Player = G.player
	pl.frozen = true
	pl.pos = barn_at + Vector2(0, 10)
	var old_dusk := G.dusk
	G.dusk = 0.97
	var start := _free(Vector2(7700, 6700) + Vector2(380, 260), 30.0)
	var s := add_prop("npc", "watchsexton", "", start, "", Color("3a3430"))
	s.remove_from_group("interact")
	s.set_solid(false)
	G.cam_look = s
	var stops := [_free(Vector2(7400, 6450), 20.0), _free(barn_at + Vector2(260, 160), 20.0), _free(goose_at + Vector2(160, 40), 20.0)]
	for i in stops.size():
		await _walk_to(s, stops[i], 80.0)
		if not is_instance_valid(s): break
		# he scatters scraps from the sack; the dog eats and lies down again without a sound
		add_decor(stops[i] + Vector2(30, 24), "scraps")
		Fx.text(stops[i], "...", Color(0.75, 0.72, 0.68), 30.0)
		await get_tree().create_timer(1.1).timeout
	# the geese see him
	Audio.sfx("shriek", -4.0, 1.6)
	Fx.text(goose_at, "HONK! HONK!", Fx.AMBER, 50.0)
	Fx.shake(3.0)
	await get_tree().create_timer(0.5).timeout
	if is_instance_valid(s):
		add_decor(s.pos + Vector2(10, 18), "key_iron" if PixelFigure.exists("key_iron") else "bone")
		await _walk_to(s, lane_top, 210.0)
		remove_prop(s)
	G.cam_look = null
	G.dusk = old_dusk
	pl.frozen = false
	done.call()

func _walk_to(p: Prop, goal: Vector2, speed: float) -> void:
	var path := find_path(p.pos, goal, 9.0, p, 220.0)
	if path.is_empty(): path = [goal]
	var fin := [false]
	p.walk(path, speed, func(): fin[0] = true)
	var guard := 0.0
	while not fin[0] and guard < 30.0 and is_instance_valid(p):
		await get_tree().process_frame
		guard += get_process_delta_time()
