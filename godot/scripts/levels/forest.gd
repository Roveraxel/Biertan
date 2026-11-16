## The Wolf Forest, east of the vineyards, and the Moon Clearing at the end of it. The baron's wolves and worse
## hold the path. Snowdrops are out, in October, and the air smells of April: something that belongs to the
## spring is shut up in here. Its jailer is the Vârcolac, who eats the moon. Behind him, in a glade where
## it is still Maundy Thursday, is Joimărița.
extends Level

const TRAIL := [Vector2(160, 2000), Vector2(900, 1900), Vector2(1700, 2100), Vector2(2500, 1900), Vector2(3300, 2050), Vector2(4100, 1900), Vector2(4700, 2000)]
const MOON := Vector2(5400, 2000)       # the Moon Clearing
const R := 500.0
const GLADE := Vector2(5400, 1050)
const DROPS := [Vector2(1000, 1780), Vector2(2560, 2040), Vector2(3900, 1790)]
const HOLE := Vector2(6050, 2000)

var boss: Varcolac
var braziers: Array[Brazier] = []
var fought := false
var eclipse := 0.0
var moon_light: OmniLight3D
var glade_wall := {}
var pack: Array[Enemy] = []
var _arrive_t := 0.0

static func has(f: String) -> bool: return G.side_has(f)

func drops() -> int:
	var n := 0
	for i in DROPS.size():
		if has("wf_drop%d" % i): n += 1
	return n

func ambient() -> Color:
	return Color(0.95, 0.9, 0.82).lerp(Color(0.12, 0.14, 0.3), 0.7).lerp(Color(0.16, 0.05, 0.06), eclipse)

func build() -> void:
	title = "THE WOLF FOREST"
	subtitle = "Snowdrops in October"
	size = Vector2(6400, 4000)
	spawn = Vector2(320, 1990)
	ground = Color("1c2218")
	tile = ""
	rng = NetRandom.new(1466)
	scatter(Rect2(Vector2.ZERO, size), 520, [Color("2a3020"), Color("20241a"), Color("382c1e")])
	add_path(TRAIL + [MOON + Vector2(-R, 0)], 90.0)
	add_path([MOON + Vector2(R, 0), HOLE], 70.0)
	var x := 80.0
	while x < size.x - 60.0:
		var y := 80.0
		while y < size.y - 60.0:
			var p := Vector2(x + (rng.f() - 0.5) * 120.0, y + (rng.f() - 0.5) * 120.0)
			y += 150.0
			if _trail_dist(p) < 170.0 or p.distance_to(MOON) < R + 90.0 or p.distance_to(GLADE) < 430.0: continue
			if absf(p.x - MOON.x) < 150.0 and p.y > GLADE.y and p.y < MOON.y: continue          # the way up to the glade
			if absf(p.y - MOON.y) < 140.0 and p.x > MOON.x: continue                             # and on to the hole
			if rng.f() < 0.22: continue
			add_tree(p, rng.f() < 0.3)
		x += 150.0
	add_wall(Vector2(size.x / 2.0, -20), Vector2(size.x, 40))
	add_wall(Vector2(size.x / 2.0, size.y + 20), Vector2(size.x, 40))
	add_wall(Vector2(-20, size.y / 2.0), Vector2(40, size.y))
	add_wall(Vector2(size.x + 20, size.y / 2.0), Vector2(40, size.y))
	add_prop("task", "back", "Back to the vineyards", Vector2(200, 2000), "E   Go back to the vineyards")
	# what holds the path
	if not has("wf_done"):
		for g in [Vector2(1500, 1950), Vector2(1620, 2200), Vector2(1420, 2180)]: _beast("wolf", g, true)
		for g in [Vector2(2900, 1850), Vector2(3050, 2150)]: _beast("moroi", g, false)
		_beast("pricolici", Vector2(3600, 1950), false)
		for g in [Vector2(4300, 1800), Vector2(4400, 2100), Vector2(4200, 2150)]: _beast("wolf", g, true)
	# snowdrops, where there should be none
	for i in DROPS.size():
		for o in [Vector2.ZERO, Vector2(60, 30), Vector2(-50, 40)]: add_decor(DROPS[i] + o, "snowdrops", 0.0, o.x < 0)
		add_torch(DROPS[i], 160.0, Color(0.8, 1, 0.85), 0.25)
		add_prop("clue", "drop%d" % i, "Snowdrops", DROPS[i] + Vector2(0, 60), "E   Look at the flowers")
	# the Moon Clearing
	add_decal(true, MOON, Vector2.ONE * (R + 5.0) * 2.0, Color("5d584f"), -998)
	add_decal(true, MOON, Vector2.ONE * (R - 5.0) * 2.0, Color("232a1f"), -997)
	add_decal(true, MOON, Vector2.ONE * (R - 40.0) * 2.0, Color("2b3326"), -996)
	add_patch(MOON, Vector2.ONE * (R - 30.0) * 2.0, "px_grass", Color(0.55, 0.7, 0.55), 1.6, -995)   # moss over the clearing floor
	add_patch(MOON, Vector2.ONE * 300.0, "px_stone", Color(0.75, 0.78, 0.85), 1.2, -994)          # the old flagstones at its heart
	# the ring of old stones sunk in the moss
	for i in 14:
		var sa := i * TAU / 14.0 + 0.11
		if absf(sin(sa)) < 0.25 or sin(sa) < -0.93: continue   # keep the ways in and out open
		var sp := MOON + Vector2(cos(sa), sin(sa)) * (R - 70.0)
		add_block(Rect2(sp.x - 16, sp.y - 12, 32, 24), "stone", 34.0 + float(i % 3) * 10.0)
	for i in 36:
		var a := i * TAU / 36.0
		if absf(sin(a)) < 0.2 or (sin(a) < -0.96): continue   # gaps west and east, and north to the glade
		add_tree(MOON + Vector2(cos(a), sin(a)) * (R + 60.0 + rand(0, 40)), true)
	for a in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]: braziers.append(add_brazier(MOON + a * 300.0))
	moon_light = add_torch(MOON, 1100.0, Color(0.75, 0.82, 1), 0.7)
	# the glade where it is still spring, shut behind him
	add_decal(true, GLADE, Vector2.ONE * 620.0, Color("3a5a2a"), -996)
	add_decal(true, GLADE, Vector2.ONE * 420.0, Color("4a6c30"), -995)
	add_patch(GLADE, Vector2(820, 680), "px_spring", Color(0.62, 0.7, 0.55), 1.4, -994)   # a spring meadow, in October
	for i in 22:
		var fa := i * 2.39996
		var fp := GLADE + Vector2(cos(fa), sin(fa) * 0.8) * (60.0 + float(i) * 14.0)
		add_decor(fp, ["petals", "snowdrops", "flower_ring"][i % 3] if i % 7 != 0 else "rose_bush", 0.0, i % 2 == 0)
	for i in 14:
		var a := i * TAU / 14.0
		add_decor(GLADE + Vector2(cos(a), sin(a) * 0.8) * (120.0 + (i % 3) * 70.0), "snowdrops", 0.0, i % 2 == 0)
	add_torch(GLADE, 520.0, Color(0.85, 1, 0.8), 0.9)
	add_decor(GLADE + Vector2(0, -30), "joimarita", 20.0)
	add_prop("task", "joimarita", "Joimărița", GLADE + Vector2(0, 40), "E   Speak with her")
	for i in 5: add_decor(GLADE + Vector2.from_angle(i * TAU / 5.0 + 0.4) * 290.0, "sacks")   # the knots that held her
	if not has("wf_moon"):
		glade_wall = add_block(Rect2(MOON.x - 200, MOON.y - R - 140, 400, 60), "hidden", 0.0)
		add_trigger(Rect2(MOON.x - 380, MOON.y - 300, 760, 600), _begin)
	add_decor(HOLE + Vector2(0, -40), "trapdoor")
	add_prop("task", "hole", "A hole under the roots", HOLE + Vector2(0, 30), "E   Go down")

func _trail_dist(p: Vector2) -> float:
	var best := INF
	for k in TRAIL.size() - 1: best = minf(best, dist_to_segment(p, TRAIL[k], TRAIL[k + 1]))
	return minf(best, dist_to_segment(p, TRAIL[TRAIL.size() - 1], MOON))

func _beast(kind: String, g: Vector2, flees: bool) -> void:
	var e := spawn_enemy(kind, g)
	e.flee_low = flees
	pack.append(e)

# ------------------------------------------------------------------ pointer and objective

func target() -> Array:
	if has("wf_done"): return [spots["hole"], "The hole under the roots"]
	if has("wf_moon"): return [spots["joimarita"], "The glade"]
	if fought: return []
	return [MOON, "The Moon Clearing"]

func objective() -> String:
	if has("wf_done"): return "A hole under the roots east of the clearing, breathing cold. Something small is barking down there."
	if has("wf_moon"): return "The moon is back. North of the clearing it is, somehow, spring."
	if fought: return "The Vârcolac. Fire and noise drive it off; away from the fire it is only shadow."
	return "His trail goes east through the Wolf Forest." + (" The snowdrops are very late. (%d/3)" % drops() if drops() > 0 else "")

func pending(p: Prop) -> bool:
	return p.id.begins_with("drop") and not has("wf_" + p.id)

func _process(dt: float) -> void:
	super(dt)
	if not is_instance_valid(G.player): return
	if not has("wf_arrive") and G.state == G.State.PLAY and not G.transitioning:
		_arrive_t += dt
		if _arrive_t > 0.6:
			G.side_add("wf_arrive")
			G.start_dialogue("The Wolf Forest", [
				"(Old beech and hornbeam, the leaves down, the path black. Wolf sign everywhere, and fresher than you like.)",
				"(And under the leaf-rot, another smell altogether. Wet earth, and something sweet. You know it. You cannot place it, not in October.)"])
	var want := 1.0 if is_instance_valid(boss) and not boss.done and boss.phase >= 2 else 0.0
	if eclipse != want:
		eclipse = move_toward(eclipse, want, dt * 0.8)
		if is_instance_valid(moon_light): moon_light.light_color = Color(0.75, 0.82, 1).lerp(Color(0.9, 0.15, 0.12), eclipse)
		if int(eclipse * 10.0) != int((eclipse - dt * 0.8) * 10.0): WorldBuilder.apply_darkness(self)

# ------------------------------------------------------------------ the Vârcolac

func _begin() -> void:
	if fought or has("wf_moon"): return
	fought = true
	G.start_dialogue("The Moon Clearing", [
		"(A round clearing with a ring of old stones sunk in the moss, and four iron fire-baskets somebody still keeps filled. The moon is straight overhead, and huge.)",
		"(From it, thin as spider-silk, threads hang down into the trees. Something is climbing one. Then it lets go.)",
		"(It lands without a sound: a hound the height of a horse and the width of a plank, all ribs and jaw. It looks at you the way you look at a gate.)",
	], func():
		boss = spawn_enemy("varcolac", MOON + Vector2(0, -260), Varcolac)
		boss.arena = self
		boss.phase_changed.connect(_on_phase)
		boss.beaten.connect(_beaten)
		Audio.set_music("music_boss", -6.0)
		Hud.banner("THE VÂRCOLAC", "Eater of the moon. Somebody set him here to keep a door shut."))

func _on_phase(p: int) -> void:
	if p == 2:
		Hud.banner("IT CLIMBS THE THREADS TO THE MOON", "The moon bleeds. Light the fires: the vârcolac fears flame and noise.")
		for b in braziers:
			b.decays = true; b.set_lit(false)
	elif p == 3:
		Hud.banner("IT DEVOURS THE FIRES", "Let it gorge. When it grows heavy, its threads will snap.")

func boss_howl(b: Varcolac) -> void:
	Hud.toast("The vârcolac howls, and the hounds answer!")
	Audio.sfx("howl", 0.0, 0.8)
	Fx.ring(b.pos, Color(0.9, 0.9, 1, 0.7), 260.0, 0.8)
	var n := 0
	for e in Enemy.all:
		if is_instance_valid(e) and e.hp > 0.0 and not e.fleeing: n += 1
	if n >= 5: return
	for i in 2:
		var w := spawn_enemy("wolf", b.pos + Vector2.from_angle(randf() * TAU) * 90.0)
		w.state = "chase"; w.aggro = 3000.0; w.flee_low = true

func swallow_light(b: Varcolac) -> void:
	var lit := braziers.filter(func(x): return x.lit)
	if lit.is_empty(): return
	var br: Brazier = lit[randi() % lit.size()]
	br.set_lit(false)
	Fx.ring(br.pos, Color(0.2, 0.2, 0.4, 0.9), 140.0, 0.7)
	Hud.toast("The vârcolac swallows a flame!")
	b.gorge()

func _beaten() -> void:
	for e in Enemy.all.duplicate():
		if is_instance_valid(e) and e.kind == "wolf" and not e.fleeing:
			e.flee_low = true; e.hp = 1.0; e.hurt(0.1, Vector2.RIGHT)
	for b in braziers:
		b.decays = false; b.set_lit(true)
	G.start_dialogue("The Moon Clearing", [
		"(The last thread snaps. He hits the moss like a dropped ladder and lies there, gorged and sorry for himself, no bigger now than a big thin dog.)",
		"(Overhead the red goes out of the moon, the way blood goes out of water.)",
		"(He gets up, shakes himself, and slinks off west with his tail down. He will be back at the next eclipse. He always is.)",
		"(Behind where he stood, the trees have a gap in them that was not there before. Through it: green. Birdsong. In October.)",
	], func():
		G.side_add("wf_moon")
		if is_instance_valid(boss): boss.queue_free()
		if not glade_wall.is_empty(): remove_block(glade_wall)
		Audio.set_music("music_forest", -9.0)
		G.player.coins += 40
		Hud.banner("THE MOON COMES BACK", "And north of the clearing, somebody has been waiting since April."))

# ------------------------------------------------------------------ Joimărița

func use(p: Prop) -> void:
	if p.id.begins_with("drop"):
		var first := not has("wf_" + p.id)
		var n := drops()
		G.side_add("wf_" + p.id)
		var lines: Array = [
			["(Ghiocei. Snowdrops, a whole clump, pushed up through the dead leaves.)", "(In the last week of October.)"],
			["(More of them. And that smell again, stronger here: wet earth, violets, a kitchen with the window open.)", "(They are very late. Half a year late.)"],
			["(A third patch, and the leaf-mould round it is warm to the hand. Or very early, then. Something that belongs to the spring is close by, and has been for a long time.)"],
		][mini(n, 2)] if first else ["(Snowdrops. Still there. Still wrong.)"]
		G.start_dialogue("Snowdrops", lines)
		return
	match p.id:
		"back": Loader.goto_level("vineyard", Vector2(2800, 1670))
		"hole":
			if not has("wf_done"): G.start_dialogue("A hole under the roots", ["A hole under a fallen beech, breathing cold air. Not yet. Something in this forest smells of April."])
			else: Loader.goto_level("tunnel")
		"joimarita": _joimarita()

func _joimarita() -> void:
	if has("wf_done"):
		G.start_dialogue("Joimărița", ["Go on, go on. I will be along. I have a call to pay on whoever tied those knots, and I want to see his hands."])
		return
	G.start_dialogue("Joimărița", [
		"(A glade where it is April. Grass, snowdrops, a blackbird. And in the middle of it a young woman, barefoot, sleeves rolled, snowdrops and violets stuck anyhow in a great loose mass of hair, swinging a pot of live embers by its handle like a girl coming back from the well.)",
		"(Round the edge of the glade lie five little linen bags, tied with candle wick. The grass will not grow near them.)",
		"(The old women say she is a hag with a head like a cauldron. The old women were girls once, and had not finished their spinning.)",
		"Joimărița: Hands.",
		"(You hold them out before you have decided to. She turns them over. Crook calluses. Rope burn. A cut from somebody's snare. Flour, still, under one nail.)",
		"(She grins, sudden and wide.) They have worked. They will do.",
		"I am Joimărița. On the Thursday before Easter I go from house to house and look at what the girls have spun over the winter. The lazy ones I teach. (She tilts the pot. The embers hiss.)",
		"This year a man with a ring of keys met me on the road with a bag of grave dirt in each hand and a dog out of the sky at his heel. I have been sitting in Thursday ever since. Half a year of Thursday, boy.",
		"(You kick the five bags out of the circle, one after the other. The April in the glade lets out a breath, and begins, very slowly, to turn into autumn.)",
		"You opened the door, so: thank you. I do not say it often; do not let it go to your head.",
		"A man with keys and soft hands. I want to see those hands. Where you are going, I am going. I stop for every flower. Do not wait.",
	], func():
		G.side_add("wf_done"); G.side_add("favour_joimarita")
		Audio.sfx("coin", -4.0)
		Hud.toast("Joimărița is free. She has a call to pay on the sexton."))
