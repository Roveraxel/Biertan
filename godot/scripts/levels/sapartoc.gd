## Șapartoc, the village of three churches (Orthodox, Catholic, Reformed) on one little hill, nearly empty.
## A light walks between the churches at night. Pastures with cows on every side, and a bull who minds them.
## Quest: The Three Churches.
extends Village

var lamp_at: Array[Vector2] = []
var lamp_decor: Array = []
var lamp_light: Array = []
var ana_at := Vector2.ZERO
var sheep_at := Vector2.ZERO
var canteen_at := Vector2.ZERO
var concert_at := Vector2.ZERO
var bull_home := Vector2.ZERO
var priest: Prop
var _sleeper: Decor
var bull: Bull

func _church(church_name: String) -> Vector2:
	for c in m.boxes("churches"):
		if c.name == church_name: return c.c
	return m.boxes("churches")[0].c

static func _before(church: Vector2) -> Vector2:
	return church + Vector2(0, 260)

func build() -> void:
	title = "ȘAPARTOC"
	subtitle = "The village of three churches"
	quest = SpQuest.new()
	arrive_flag = "sp_arrive"
	standard("sapartoc", 1390)
	for c in m.boxes("churches"): add_church(c, 78.0 if c.area > 250.0 else 56.0, c.area > 250.0, 0.75, 190.0)
	for b in m.boxes("houses"):
		var sz: Vector2 = b.size
		var tries := 0
		while tries < 3 and blocks_street(b.c, sz, b.angle):
			sz *= 0.8; tries += 1
		if blocks_street(b.c, sz, b.angle): continue
		if blocked(b.c, minf(sz.x, sz.y) * 0.45): continue   # drawn closer together than in life: no house on top of another
		add_block_rotated(b.c, sz, b.angle, "house", 60.0 if b.style == "barn" else 44.0 + rng.f() * 12.0)
	spawn = free_spot(m.at(-64, 28), 120.0)   # the lane from Saschiz comes in from the north
	plant_trees(400.0, 280.0, 0.55, 80.0, spawn)
	_hillside()
	_quest_things()
	edge_walls()
	plant_gardens(9001, garden_ok)

func _hillside() -> void:
	var v := m.village
	var n := 0
	var x := 100.0
	while x < size.x - 100.0:
		var y := 100.0
		while y < size.y - 100.0:
			var p := Vector2(x + (rng.f() - 0.5) * 220.0, y + (rng.f() - 0.5) * 220.0)
			y += 300.0
			var edge := minf(minf(p.x, size.x - p.x), minf(p.y, size.y - p.y))
			if v.has_point(p) or (edge > 1400.0 and rng.f() < 0.85) or rng.f() < 0.35: continue   # woods thicken toward the hilltops
			if near_road(p, 60.0) or p.distance_to(spawn) < 400.0: continue
			add_tree(p, rng.f() < 0.25)
			n += 1
			if n > 400: break
		x += 300.0
	# the pastures: one on each side of the village, a few cows in each, hay and a trough
	var mid := v.get_center()
	var pastures := [Vector2(v.position.x - 1100.0, mid.y - 900.0), Vector2(v.end.x + 1100.0, mid.y), Vector2(mid.x + 900.0, v.end.y + 1100.0), Vector2(mid.x - 1200.0, v.position.y - 1000.0)]
	for c in pastures:
		var at := free_spot(c, 80.0)
		add_decor(free_spot(at + Vector2(-220, -160), 40.0), "hay", 30.0)
		add_decor(free_spot(at + Vector2(240, 120), 30.0), "trough", 25.0)
		for i in 4:
			var cow := spawn_enemy("cow", free_spot(at + Vector2((rng.f() - 0.5) * 600.0, (rng.f() - 0.5) * 500.0), 40.0))
			cow.home = at
			cow.hurted.connect(_on_cow_hit)
	bull_home = free_spot(pastures[1] + Vector2(500, -300), 80.0)

func _on_cow_hit(cow: Enemy) -> void:
	if is_instance_valid(bull) or G.side_has("sp_bull"): return
	var pl: Vector2 = G.player.pos
	var from := (pl - (pl - cow.pos).normalized() * 900.0).clamp(Vector2(200, 200), size - Vector2(200, 200))
	bull = spawn_enemy("bull", from, Bull)
	bull.beaten.connect(func(): G.side_add("sp_bull"); bull = null)

func _quest_things() -> void:
	var has := func(f: String) -> bool: return G.side_has(f)
	var catholic := _church("Biserica Romano-Catolica"); var orthodox := _church(""); var reformed := _church("Biserica reformată")
	var radu := _in_front_of(m.at(168, -489))   # Radu's blue house at the south end of the village
	add_prop("npc", "radu", "Radu · Innkeeper", radu, "E   Speak with Radu", Color("3a5a8a"))
	add_decor(radu + Vector2(-80, -30), "geraniums"); add_decor(radu + Vector2(90, -30), "logs", 25.0)
	add_torch(radu + Vector2(0, -60), 240.0, Color(1, 0.62, 0.3), 0.7)
	var horia := free_spot(m.at(148, -236), 50.0)
	add_prop("npc", "horia", "Horia · Mayor", horia, "E   Speak with Horia", Color("4a4a5a"))
	add_decor(horia + Vector2(70, -20), "letters")
	add_prop("clue", "light", "The light", free_spot(catholic.lerp(orthodox, 0.5) + Vector2(250, 0), 30.0), "E   Watch the light")
	add_prop("clue", "door", "The door", free_spot(_before(reformed), 40.0), "E   Watch the door")
	# the lamp brackets along the path: Catholic church, past the Orthodox, to the Reformed
	var bc := _before(catholic); var bo := _before(orthodox); var br := _before(reformed)
	var path := [bc.lerp(bo, 0.2), bc.lerp(bo, 0.5), bc.lerp(bo, 0.8), bo.lerp(br, 0.4), bo.lerp(br, 0.85)]
	for i in SpQuest.LAMPS:
		lamp_at.append(free_spot(path[i], 40.0))
		lamp_light.append(null)
		var lit: bool = has.call("sp_ana") or has.call("sp_lamp%d" % i)
		lamp_decor.append(add_decor(lamp_at[i], "lamp_lit" if lit else "lamp_post", 12.0))
		if lit: _light_at(i)
		add_prop("task", "lamp%d" % i, "Lamp", lamp_at[i] + Vector2(0, 30), "E   Light the lamp")
	ana_at = free_spot(bo + Vector2(-160, 0), 40.0)
	if has.call("sp_ana") and not has.call("sp_done"): _show_ana()
	elif has.call("sp_done"):
		add_decor(ana_at + Vector2(0, -40), "hammock"); add_decor(ana_at + Vector2(40, -20), "book")
	var barn := free_spot(m.at(-28, -100), 50.0)
	add_decor(barn, "planks", 25.0)
	add_prop("task", "materials", "Old barn", barn + Vector2(0, 40), "E   Take planks and tools")
	canteen_at = free_spot(bc + Vector2(200, 0), 40.0)
	add_prop("task", "canteen", "The Catholic church", canteen_at, "E   Set up the canteen")
	if has.call("sp_canteen"): canteen()
	concert_at = free_spot(br + Vector2(200, 0), 40.0)
	add_prop("task", "concert", "The Reformed church", concert_at, "E   Set up the concert hall")
	if has.call("sp_concert"): concert()
	add_prop("task", "mass", "The Orthodox church", free_spot(bo + Vector2(160, 0), 40.0), "E   The first mass")
	sheep_at = free_spot(Vector2(m.village.position.x - 700.0, m.at(0, -160).y), 60.0)
	for it in [[Vector2(-120, -40), "sheep_lie"], [Vector2(110, -60), "sheep_graze"], [Vector2(40, 100), "sheep_lie"], [Vector2(-150, 90), "sheep_graze"], [Vector2(170, 60), "sheep_graze"]]:
		add_decor(sheep_at + it[0], it[1], 14.0, rng.f() < 0.5)
	if not has.call("sp_priest"):
		priest = add_prop("npc", "traveller", "A man among the sheep", sheep_at, "E   Wake him", Color("2a2a2a"))
		if priest.fig: priest.fig.visible = false   # lying down, snoring: the drawing below, not the standing figure
		_sleeper = add_decor(sheep_at + Vector2(0, 4), "priest_sleep")
		add_decor(sheep_at + Vector2(30, -20), "wine_jug")
	else:
		priest = add_prop("npc", "traveller", "Father Bálint", free_spot(bo + Vector2(80, 60), 30.0), "E   Speak with Father Bálint", Color("2a2a2a"))
	add_prop("task", "road", "The road south", free_spot(Vector2(m.at(-96, -560).x, size.y - 260.0), 40.0), "E   Take the road south")
	add_troita(centre_spot())

func _in_front_of(g: Vector2) -> Vector2:
	var best: Dictionary = m.boxes("houses")[0]; var bd := INF
	for b in m.boxes("houses"):
		if g.distance_to(b.c) < bd:
			bd = g.distance_to(b.c); best = b
	return free_spot(best.c + Vector2(0, maxf(best.size.x, best.size.y) * 0.5 + 70.0), 40.0)

func _light_at(i: int) -> void:
	if lamp_light[i] == null: lamp_light[i] = add_torch(lamp_at[i] + Vector2(0, -40), 200.0, Color(1, 0.7, 0.35), 0.7)

func light_lamp(i: int) -> void:
	remove_decor(lamp_decor[i])
	lamp_decor[i] = add_decor(lamp_at[i], "lamp_lit", 12.0)
	_light_at(i)

func lamps_out() -> void:
	for i in SpQuest.LAMPS:
		remove_decor(lamp_decor[i])
		lamp_decor[i] = add_decor(lamp_at[i], "lamp_post", 12.0)
		if lamp_light[i] != null:
			lamp_light[i].queue_free()
			lamp_light[i] = null

func summon() -> void:
	# the light of the lamps runs down the path, lamp to lamp, and gathers in front of the hunter
	G.player.frozen = true
	var pp: Vector2 = G.player.pos
	ana_at = free_spot(pp + G.player.facing * 110.0 + Vector2(0, 10), 30.0)
	var wisp := add_torch(lamp_at[0] + Vector2(0, -40), 240.0, Color(0.75, 0.88, 1.0), 1.2)
	Audio.sfx("bell", -14.0, 1.8)
	for i in lamp_at.size():
		var tw := create_tween()
		tw.tween_property(wisp, "position", Fx.to3(lamp_at[i], 1.2), 0.35)
		await tw.finished
		Fx.ring(lamp_at[i], Color(0.75, 0.88, 1.0, 0.7), 60.0)
		Audio.sfx("blip", -10.0, 1.4 + i * 0.1)
	var tw2 := create_tween()
	tw2.tween_property(wisp, "position", Fx.to3(ana_at, 1.2), 0.6)
	await tw2.finished
	for k in 3:
		Fx.ring(ana_at, Color(0.8, 0.9, 1.0, 0.8 - k * 0.2), 40.0 + k * 30.0)
		await G.wait(0.15)
	wisp.queue_free()
	Audio.sfx("bell", -12.0, 1.5)
	Hud.banner("ANA", "Manole's wife, walled up to guard a holy place.")
	_show_ana()
	G.player.frozen = false
	G.start_dialogue("Ana", [
		"(The light stops in front of you and stretches into the shape of a woman, pale, with mortar in her hair.)",
		"You lit my lamps. Nobody has done that in years.",
		"My name is Ana. Manole walled me into the wall to protect the holy place. But he never said which one.",
		"Then they built two more, and now I have to guard all three so they don't fall down. Up and down the hill, all night, every night. Do you know how tiring that is?",
		"The people left because of me. I didn't want that. I only want the churches to stand.",
	], func(): G.side_add("sp_ana"); Hud.toast("Tell Radu what the ghost said."))

func _show_ana() -> void:
	add_prop("npc", "ana", "Ana", ana_at, "E   Speak with Ana", Color("d8e0f0"))
	add_torch(ana_at + Vector2(0, -40), 260.0, Color(0.7, 0.85, 1), 0.8)

func ana_retires() -> void:
	for p in props:
		if p.id == "ana": p.pos = ana_at + Vector2(0, -30)
	add_decor(ana_at + Vector2(0, -40), "hammock")
	add_decor(ana_at + Vector2(40, -20), "book")

func canteen() -> void:
	add_decor(canteen_at + Vector2(-140, 40), "table", 30.0); add_decor(canteen_at + Vector2(140, 40), "table", 30.0, true)
	add_decor(canteen_at + Vector2(0, 120), "pot_fire", 20.0)
	add_torch(canteen_at + Vector2(0, 100), 220.0, Color(1, 0.55, 0.25), 0.8)

func concert() -> void:
	add_decor(concert_at + Vector2(-100, 30), "music_stand", 10.0); add_decor(concert_at + Vector2(0, 50), "music_stand", 10.0); add_decor(concert_at + Vector2(100, 30), "music_stand", 10.0, true)
	add_torch(concert_at + Vector2(0, 20), 200.0, Color(1, 0.75, 0.45), 0.6)

func priest_to_church() -> void:
	var dest := free_spot(_before(_church("")) + Vector2(80, 60), 30.0)
	if is_instance_valid(_sleeper): remove_decor(_sleeper)   # up out of the grass
	if priest.fig: priest.fig.visible = true
	priest.walk(find_path(priest.pos, dest, 8.0, priest, 500.0), 60.0)   # mostly straight
	priest.display = "Father Bálint"
	if priest.label: priest.label.text = "Father Bálint"
	spots["traveller"] = dest
