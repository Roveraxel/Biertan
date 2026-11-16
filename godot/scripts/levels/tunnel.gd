## The old way under the hills, from the Wolf Forest to the cellars of Viscri: the road the baron took, and a
## maze: centuries of quarrymen, salt-thieves and people hiding from Tatars each cut their own passages.
## A small pale dog walks ahead of the hunter. He is Cățelul pământului, the earth dog, who lives under the
## ground by the graves and barks to warn the living. The sexton has been burying stolen grave earth down here,
## in the dog's own ground, tied with church candle wick that no creature of the earth can touch. He needs
## hands. So he fetched the man the dead of Apold spoke well of, and he keeps him alive as far as the last bag.
## Off the dog's road: rotten floors, nests of moroi, bats, and the dark. He carries the only light.
extends Level

const W := 13
const H := 8
const ROOM := 280.0
const WALL := 140.0
const DOG_COL := Color(0.9, 0.92, 0.85)

var open := {}                   # Vector2i tile -> true, on the (2W+1) x (2H+1) lattice
var way: Array[Vector2] = []     # the dog's road, room centre to room centre
var bag_at: Array[int] = []      # indices into `way`
var pit_at: Array[int] = []
var fall_at: Array[int] = []     # where the roof is waiting to come down
var pits: Array[Vector2] = []    # every rotten floor, on his road and off it
var dog: Decor
var dog_fig: PixelFigure     # his walking figure, riding on the decor
var _dog_last := Vector2.ZERO
var _dog_face := Vector2(0, 1)
var dog_light: OmniLight3D
var at_i := 0                    # the point he is walking to
var waiting := ""                # "bag" / "pit" while he stands and barks
var bark_t := 0.0
var dug := 0
var fell_t := 0.0
var lost_t := 0.0
var falls: Array[Dictionary] = []
var fallen := {}
var _arrive_t := 0.0

func ambient() -> Color:
	return Color(0.1, 0.1, 0.14)

## Left or top edge of lattice line k: walls at even k, rooms at odd.
static func _edge(k: int) -> float:
	return (k / 2) * (ROOM + WALL) + (WALL if k % 2 == 1 else 0.0)

static func _room(c: Vector2i) -> Vector2:
	return Vector2(_edge(c.x * 2 + 1) + ROOM / 2.0, _edge(c.y * 2 + 1) + ROOM / 2.0)

func build() -> void:
	title = "UNDER THE HILLS"
	subtitle = "The old way to Viscri"
	size = Vector2(_edge(W * 2) + WALL, _edge(H * 2) + WALL)
	ground = Color("1c1a18")
	tile = ""
	rng = NetRandom.new(1415)
	var start := Vector2i(0, H / 2); var goal := Vector2i(W - 1, H / 2)
	spawn = _room(start) + Vector2(-60, 0)
	# carve: a wandering depth-first maze, then a few walls knocked through so that it loops
	var seen := {start: true}
	var stack: Array[Vector2i] = [start]
	var links := {}              # cell -> [neighbour cells]
	var dirs: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	while not stack.is_empty():
		var c: Vector2i = stack[stack.size() - 1]
		var free: Array[Vector2i] = []
		for d in dirs:
			var n := c + d
			if n.x >= 0 and n.y >= 0 and n.x < W and n.y < H and not seen.has(n): free.append(n)
		if free.is_empty():
			stack.pop_back()
			continue
		var n: Vector2i = free[rng.i(free.size())]
		seen[n] = true
		_link(links, c, n)
		stack.append(n)
	for k in 9:
		var c := Vector2i(rng.i(W - 1), rng.i(H - 1))
		_link(links, c, c + (Vector2i(1, 0) if rng.f() < 0.5 else Vector2i(0, 1)))
	# his road: the shortest way through
	var prev := {start: start}
	var queue: Array[Vector2i] = [start]
	while not queue.is_empty():
		var c: Vector2i = queue.pop_front()
		if c == goal: break
		for n in links.get(c, []):
			if not prev.has(n):
				prev[n] = c
				queue.append(n)
	var cells: Array[Vector2i] = []
	var c := goal
	while c != start:
		cells.push_front(c)
		c = prev[c]
	cells.push_front(start)
	for cc in cells: way.append(_room(cc))
	var on_way := {}
	for cc in cells: on_way[cc] = true
	var n_way := way.size()
	bag_at = [int(n_way * 0.25), int(n_way * 0.55), n_way - 3]
	pit_at = [int(n_way * 0.4), int(n_way * 0.72)]
	fall_at = [int(n_way * 0.33), int(n_way * 0.63), int(n_way * 0.82)]
	# rock
	for ty in H * 2 + 1:
		for tx in W * 2 + 1:
			if open.has(Vector2i(tx, ty)): continue
			var r := Rect2(_edge(tx), _edge(ty), WALL if tx % 2 == 0 else ROOM, WALL if ty % 2 == 0 else ROOM)
			add_block(r, "rock", 80.0 + rng.f() * 30.0)
	scatter(Rect2(Vector2.ZERO, size), 420, [Color("26231f"), Color("141210"), Color("302a24")])
	# what waits off his road
	for y in H:
		for x in W:
			var cell := Vector2i(x, y)
			if on_way.has(cell): continue
			var at := _room(cell)
			var dead_end: bool = links.get(cell, []).size() == 1
			var roll := rng.f()
			if dead_end and roll < 0.3:
				if not G.side_has("tn_coin_%d_%d" % [x, y]):
					add_decor(at + Vector2(0, -20), "crate")
					add_prop("task", "coin_%d_%d" % [x, y], "An old strongbox", at + Vector2(0, 30), "E   Open it")
			elif roll < 0.45:
				pits.append(at)
			elif roll < 0.75:
				for o in [Vector2(-50, -20), Vector2(60, 30)]: spawn_enemy("moroi", at + o)
			elif roll < 0.9:
				for o in [Vector2(-40, 0), Vector2(40, -30), Vector2(10, 50)]: spawn_enemy("bat", at + o)
			if rng.f() < 0.3: add_decor(at + Vector2(70, -60), "bone" if rng.f() < 0.6 else "chains")
	for i in pit_at: pits.append(way[i] + _side(i) * -60.0)
	for p in pits: add_decal(true, p, Vector2(150, 120), Color("050505"), -990)
	for i in bag_at:
		if not G.side_has("tn_bag%d" % i):
			add_prop("task", "bag%d" % i, "Loose earth", way[i] + Vector2(0, 40), "E   Dig")
	add_prop("task", "back", "Back up to the forest", way[0] + Vector2(-100, 0), "E   Climb back up")
	add_decor(way[n_way - 1] + Vector2(60, -60), "crypt_stairs")
	add_prop("task", "up", "Stairs up", way[n_way - 1] + Vector2(60, 10), "E   Climb up into Viscri")
	add_torch(way[n_way - 1], 300.0, Color(1, 0.7, 0.4), 0.5)
	dog = add_decor(way[0] + Vector2(90, 0), "earth_dog")
	dog.set_solid(false)
	dog_fig = PixelFigure.make("earth_dog", 0.75)
	if dog_fig:
		if dog.sprite: dog.sprite.visible = false
		dog.add_child(dog_fig)
	dog_light = add_torch(dog.pos, 520.0, Color(0.8, 0.9, 0.75), 1.1)   # he is the only light down here
	add_prop("task", "dog", "A small dog", dog.pos, "E   Look at the dog")
	if G.side_has("tn_done"):
		at_i = n_way
		dog.pos = way[n_way - 1] + Vector2(-70, 40)

func _link(links: Dictionary, a: Vector2i, b: Vector2i) -> void:
	if not links.has(a): links[a] = []
	if not links.has(b): links[b] = []
	if not b in links[a]:
		links[a].append(b); links[b].append(a)
	open[a * 2 + Vector2i.ONE] = true
	open[b * 2 + Vector2i.ONE] = true
	open[a + b + Vector2i.ONE] = true   # the wall tile between them

## Sideways from the road at one of its points (he passes a pit on this side).
func _side(i: int) -> Vector2:
	var d: Vector2 = (way[mini(i + 1, way.size() - 1)] - way[maxi(i - 1, 0)]).normalized()
	if d == Vector2.ZERO: d = Vector2.RIGHT
	return Vector2(-d.y, d.x)

func target() -> Array:
	if at_i >= way.size() and waiting == "": return [spots["up"], "The stairs up"]
	if waiting == "bag": return [way[at_i] + Vector2(0, 40), "Where he is barking"]
	return [dog.pos, "The dog"]

func objective() -> String:
	if at_i >= way.size() and waiting == "": return "Stairs, going up. Viscri is overhead."
	if waiting == "bag": return "He will not go on. Dig where he is barking."
	if waiting == "pit": return "He has stopped at the edge of something. Go where he goes, and only there."
	return "Follow the little dog. He knows the way, and what is wrong with it."

func pending(p: Prop) -> bool:
	return p.id.begins_with("bag") and waiting == "bag" and p.id == "bag%d" % at_i

func _process(dt: float) -> void:
	super(dt)
	if not is_instance_valid(G.player) or not is_instance_valid(dog): return
	spots["dog"] = dog.pos
	if dog_fig and dt > 0.0:
		var v := (dog.pos - _dog_last) / dt
		if v.length() > 600.0: v = Vector2.ZERO
		if v.length() > 5.0: _dog_face = v.normalized()
		elif waiting != "": _dog_face = (G.player.pos - dog.pos).normalized()
		dog_fig.tick("move", v, _dog_face, dt)
		_dog_last = dog.pos
	if not G.side_has("tn_arrive") and G.state == G.State.PLAY and not G.transitioning:
		_arrive_t += dt
		if _arrive_t > 0.6:
			G.side_add("tn_arrive")
			G.start_dialogue("Under the hills", [
				"(Not one passage. Dozens: quarrymen, salt-thieves, people hiding from the Tatars, each cut their own, and they all look alike. Cold. No light at all. The smell of the bags.)",
				"(The barking you have been hearing under your feet since Biertan is here, and it is small. A small pale dog, sitting in the middle of the passage, looking at you as if you were late.)",
				"(Cățelul pământului. The earth dog, who keeps the ground the dead lie in. Your grandmother said: if you hear him bark under the earth, somebody is being warned. She never said he might wait for you.)",
				"(There is a faint light about him, like a rotten stump. It is the only light down here. He gets up, walks ten paces, and looks back.)"])
	if G.state != G.State.PLAY: return
	var pl: Player = G.player
	fell_t = maxf(0.0, fell_t - dt)
	# a rotten floor takes whoever does not walk where the dog walked
	dog_light.position = Fx.to3(dog.pos, 1.0)
	for pit in pits:
		if fell_t <= 0.0 and pl.pos.distance_to(pit) < 58.0 and pl.inv_t <= 0.0:
			fell_t = 1.5
			pl.hurt(14.0, Vector2.ZERO)
			pl.pos = dog.pos + Vector2(-50, 20)
			pl.vel = Vector2.ZERO
			Fx.shake(0.3)
			Hud.toast("The floor goes. Something small drags you out by the collar, a long way from where you fell.")
	# the roof, where it has been waiting: he barks, then it comes down
	for i in fall_at:
		if not fallen.has(i) and at_i >= i and pl.pos.distance_to(way[i]) < 150.0:
			fallen[i] = true
			Fx.text(dog.pos, "HAM!", DOG_COL, 70.0)
			Audio.sfx_at("bark", dog.pos, -4.0, 1.5)
			for k in 5:
				var at: Vector2 = way[i] + Vector2.from_angle(randf() * TAU) * sqrt(randf()) * 120.0
				Fx.ring(at, Color(0.8, 0.7, 0.6, 0.6), 60.0, 1.1)
				falls.append({at = at, t = 1.1 + k * 0.12})
	for f in falls.duplicate():
		f.t -= dt
		if f.t > 0.0: continue
		falls.erase(f)
		Fx.shake(0.2)
		Fx.ring(f.at, Color(0.6, 0.55, 0.5, 0.9), 70.0, 0.3)
		Audio.sfx_at("hit", f.at, -2.0, 0.5)
		add_decor(f.at, "rubble" if ResourceLoader.exists("res://sprites/Props/rubble.png") else "bone")
		if pl.pos.distance_to(f.at) < 62.0 and pl.inv_t <= 0.0: pl.hurt(16.0, (pl.pos - f.at).normalized())
	# out of his light for long, a man is simply lost
	if dog.pos.distance_to(pl.pos) > 700.0:
		lost_t += dt
		if lost_t > 9.0:
			lost_t = 0.0
			Fx.text(pl.pos, "(far off: ham! ham!)", DOG_COL, 80.0)
			Hud.toast("You cannot see your own hands. Somewhere behind you, he is barking.")
	else: lost_t = 0.0
	if waiting != "":
		bark_t -= dt
		if bark_t <= 0.0:
			bark_t = 1.3
			Fx.text(dog.pos, "ham! ham!", DOG_COL, 60.0)
			Audio.sfx_at("bark", dog.pos, -8.0, 1.5)
		if waiting == "pit" and pl.pos.distance_to(dog.pos) < 110.0: waiting = ""   # he waits on the far side until the man is across
		return
	if at_i >= way.size(): return
	# he keeps a little ahead, and waits if the man falls behind
	if dog.pos.distance_to(pl.pos) > 330.0: return
	var goal: Vector2 = way[at_i] + (Vector2(-90, 30) if at_i == way.size() - 1 else Vector2.ZERO)
	if at_i in pit_at: goal += _side(at_i) * 75.0
	var to := goal - dog.pos
	if to.length() > 6.0:
		dog.pos += to.limit_length(175.0 * dt)
		if dog.sprite and absf(to.x) > 1.0: dog.sprite.flip_h = to.x < 0.0
		return
	if at_i in bag_at and not G.side_has("tn_bag%d" % at_i):
		waiting = "bag"; bark_t = 0.0
	elif at_i in pit_at:
		waiting = "pit"; bark_t = 0.0
		at_i += 1
	else: at_i += 1

func use(p: Prop) -> void:
	if p.id.begins_with("bag"):
		var i := int(p.id.substr(3))
		if waiting != "bag" or i != at_i:
			G.start_dialogue("Loose earth", ["A patch of floor that has been dug and trodden down again. The dog is not interested in it yet, so neither are you."])
			return
		dug += 1
		G.side_add("tn_bag%d" % i)
		remove_prop(p)
		Audio.sfx("blip", -6.0, 0.6)
		var lines: Array = [
			["(You dig with your hands. A linen bag, tied with candle wick, a hand's depth down. Round it the floor is scored with small claw marks, years of them: he has dug at this himself, and never once touched it.)", "(Grave earth, stolen and buried in his ground, knotted with wick from a church candle. Nothing that belongs to the earth can lay a paw on that. It wants a pair of hands.)", "(So that is what you are for. He watches until you have it out, sneezes, and goes on.)"],
			["(Another. Under it the earth is packed hard by feet: this passage has been walked every month for years, by one man, in good boots.)"],
			["(The last. This one is fresh, the knot still stiff. And beside it in the dust, going east at a run: a narrow old-fashioned shoe, and dragging next to it, a woman's heel marks.)", "(Then the heel marks stop dragging. Then, a little further on, the shoe prints get a great deal less steady, as if somebody had bitten him.)"],
		][mini(dug - 1, 2)]
		G.start_dialogue("A buried bag", lines, func():
			waiting = ""
			at_i += 1
			# what the earth was keeping quiet gets up
			for o in [Vector2(-160, -40), Vector2(170, 30)]:
				var e := spawn_enemy("moroi", way[i] + o)
				e.state = "chase"; e.aggro = 3000.0)
		return
	if p.id.begins_with("coin_"):
		G.side_add("tn_" + p.id)
		remove_prop(p)
		G.player.coins += 15
		Audio.sfx("coin", -4.0)
		Hud.toast("Somebody hid this from the Tatars and never came back for it. +15 coins")
		return
	match p.id:
		"dog":
			G.start_dialogue("Cățelul pământului", ["(He is the colour of a root and about the size of a loaf. He lets you look. He does not let you pat him.)"] if dug == 0 else ["(The dead of Apold sat down to their supper this year because of you. Word of that goes down as well as up. He did not pick the first man with hands; he picked this one.)"])
		"back": Loader.goto_level("forest", Vector2(5950, 2030))
		"up":
			if at_i < way.size() or waiting != "": G.start_dialogue("Stairs up", ["He is still back there, barking. He has not barked at nothing yet."])
			else:
				G.start_dialogue("Stairs up", [
					"(Steps, cut in the rock, and at the top a slab you know from the other side: the cellars under Viscri's churchyard.)",
					"(The dog sits down at the bottom step. This is as far as he goes; up there is not his. He barks once, not a warning this time.)",
				], func():
					G.side_add("tn_done")
					Loader.goto_level("viscri", VisQuest.crypt_door + Vector2(0, 120) if VisQuest.crypt_door != Vector2.ZERO else null))
