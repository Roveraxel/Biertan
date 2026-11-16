## Saschiz (Keisd), from the real village: the church with the clock tower the neighbours envy, the painted
## houses, the path up to the giants' fortress on the wooded hill. Quest: The Missing Children.
extends Village


var mob_at := Vector2.ZERO
var brawlers: Array[Enemy] = []

func build() -> void:
	title = "SASCHIZ"
	subtitle = "Keisd · The Missing Children"
	quest = SxQuest.new()
	arrive_flag = "sx_arrive"
	standard("saschiz", 1347)
	for c in m.boxes("churches"): add_church(c, 78.0 if c.area > 250.0 else 56.0, c.area > 250.0, 0.75, 190.0)
	for b in m.boxes("houses"):
		if b.name == "Turn cu Ceas":   # the clock tower the neighbours envy
			add_block_rotated(b.c, b.size, b.angle, "clocktower", 210.0)
			continue
		var sz: Vector2 = b.size
		var tries := 0
		while tries < 3 and blocks_street(b.c, sz, b.angle):
			sz *= 0.8; tries += 1
		if blocks_street(b.c, sz, b.angle): continue
		add_block_rotated(b.c, sz, b.angle, "house", 60.0 if b.style == "barn" else 44.0 + rng.f() * 12.0)
	add_yard_walls()
	spawn = free_spot(Vector2(6600, 15500), 120.0)   # the road from Criț comes in from the south
	add_graves(90, 80.0, 100.0, false)
	plant_trees(400.0, 280.0, 0.55, 80.0, Vector2(6600, 15500))
	_quest_things()
	edge_walls()
	plant_gardens(9001, garden_ok)

func _quest_things() -> void:
	var ilinca := free_spot(Vector2(6900, 6600), 50.0)
	add_prop("npc", "ilinca", "Ilinca · Potter", ilinca, "E   Speak with Ilinca", Color("5a6a8a"))
	add_decor(ilinca + Vector2(70, -20), "crate", 20.0)
	add_torch(ilinca + Vector2(0, -50), 220.0, Color(1, 0.6, 0.3), 0.6)
	mob_at = free_spot(Vector2(6150, 5900), 60.0)
	if not G.side_has("sx_brawl"):
		add_prop("npc", "mob", "Hannes the smith", mob_at, "E   Speak with Hannes", Color("6a3a30"))
		for o in [Vector2(-80, 40), Vector2(90, 30), Vector2(20, 90)]: add_decor(free_spot(mob_at + o, 20.0), "lantern")
	add_torch(mob_at, 260.0, Color(1, 0.55, 0.25), 0.7)
	add_prop("clue", "tracks", "Footprints", free_spot(Vector2(4200, 6900), 30.0), "E   Look at the footprints")
	add_prop("clue", "clayhorse", "Clay horse", free_spot(Vector2(3600, 8200), 30.0), "E   Look at the clay figure")
	var stones := free_spot(Vector2(2300, 6300), 80.0)
	for k in 3: add_block(Rect2(stones.x - 30.0 + k * 4.0, stones.y - 30.0 - k * 55.0, 60, 55), "stone", 30.0 + k * 24.0)
	add_prop("clue", "stones", "Stacked stones", stones + Vector2(0, 60), "E   Look at the stones")
	var carts := free_spot(Vector2(10000, 4000), 60.0)
	add_decor(carts, "haycart", 55.0); add_decor(carts + Vector2(160, 40), "haycart", 55.0, true); add_decor(carts + Vector2(70, 120), "handcart", 30.0)
	add_decor(free_spot(mob_at + Vector2(-140, -60), 30.0), "anvil", 16.0)
	add_decor(free_spot(mob_at + Vector2(-220, -40), 30.0), "blacksmith_forge", 22.0)
	var sq := centre_spot()
	add_decor(free_spot(sq + Vector2(-180, 90), 30.0), "market_counter", 20.0)
	add_decor(free_spot(sq + Vector2(-110, 110), 25.0), "market_produce", 18.0)
	add_decor(free_spot(sq + Vector2(-240, 120), 25.0), "market_textiles", 14.0)
	add_decor(free_spot(sq + Vector2(-140, 160), 20.0), "pig", 12.0)
	add_decor(free_spot(sq + Vector2(140, 120), 20.0), "wicker_baskets", 12.0)
	add_prop("task", "carts", "The neighbours' carts", carts + Vector2(60, 70), "E   Look at the carts")
	var hill := free_spot(Vector2(320, 2850), 40.0)
	SxQuest.hill_path = hill
	add_prop("task", "hill", "Path to the fortress", hill, "E   Climb to the fortress")
	add_trigger(Rect2(0, hill.y - 260.0, 70, 520), func(): if G.side_has("sx_brawl"): Loader.goto_level("uriasi"))
	add_prop("task", "road", "The road west", free_spot(Vector2(4400, 300), 40.0), "E   Take the road west")
	add_troita(centre_spot())
	if G.side_has("sx_giant"):   # the giant has set the children down on the square
		for i in 3: add_prop("npc", "kid%d" % (i + 1), ["Paul", "Ioana", "Andrei"][i], free_spot(ilinca + Vector2(-160 + i * 80, 120), 25.0), "E   Speak", Color("6a5a40"))

func brawl() -> void:
	Audio.sfx("hit", -4.0, 0.8)
	Hud.banner("A BRAWL", "Fists only. Nobody here wants to hurt anybody. Much.")
	for p in props.duplicate():
		if p.id == "mob": remove_prop(p)
	var left := [4]
	for o in [Vector2(-120, 0), Vector2(120, 20), Vector2(0, 120), Vector2(40, -110)]:
		var e := spawn_enemy("brawler", free_spot(mob_at + o, 20.0))
		brawlers.append(e)
		e.died.connect(func(_e):
			left[0] -= 1
			if left[0] == 0: _end_brawl())

func _end_brawl() -> void:
	await G.wait(1.2)
	for e in brawlers:
		if is_instance_valid(e): e.queue_free()
	brawlers.clear()
	quest.after_brawl()
