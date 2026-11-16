## The forest above Criț: the old path past the wild roses, where a wolf pack lies up, to Sfânta Vineri's shrine.
extends Level

const TRAIL := [Vector2(160, 2600), Vector2(900, 2450), Vector2(1700, 2700), Vector2(2500, 2400), Vector2(3300, 2200), Vector2(4200, 2350),
	Vector2(5000, 2650), Vector2(5800, 2500), Vector2(6600, 2300), Vector2(7300, 2450), Vector2(7900, 2500)]
const CLEARING := Vector2(7950, 2500)
const ROSES := Vector2(4300, 2200)

var pack: Array[Enemy] = []

func build() -> void:
	title = "THE FOREST ABOVE CRIȚ"
	subtitle = "The old path to Sfânta Vineri"
	size = Vector2(9000, 5000)
	spawn = Vector2(320, 2580)
	ground = Color("22281c")
	tile = ""
	quest = CritQuest.new()
	rng = NetRandom.new(1271)
	scatter(Rect2(Vector2.ZERO, size), 500, [Color("2e3422"), Color("262a1e"), Color("3a3022")])
	add_path(TRAIL, 90.0)
	# the wood: thick everywhere but the trail, the rose thicket and the clearing
	var x := 80.0
	while x < size.x - 60.0:
		var y := 80.0
		while y < size.y - 60.0:
			var p := Vector2(x + (rng.f() - 0.5) * 120.0, y + (rng.f() - 0.5) * 120.0)
			y += 150.0
			if _trail_dist(p) < 170.0 or p.distance_to(CLEARING) < 620.0 or p.distance_to(ROSES) < 420.0: continue
			if rng.f() < 0.25: continue
			add_tree(p, rng.f() < 0.25)
		x += 150.0
	add_wall(Vector2(size.x / 2.0, -20), Vector2(size.x, 40))
	add_wall(Vector2(size.x / 2.0, size.y + 20), Vector2(size.x, 40))
	add_wall(Vector2(-20, size.y / 2.0), Vector2(40, size.y))
	add_wall(Vector2(size.x + 20, size.y / 2.0), Vector2(40, size.y))
	# the way back to the village
	add_prop("task", "exit", "Back to Criț", Vector2(200, 2600), "")
	add_trigger(Rect2(0, 2300, 60, 600), func():
		Loader.goto_level("crit", CritQuest.forest_gate + Vector2(-200, 0) if CritQuest.forest_gate != Vector2.ZERO else null))
	add_decor(Vector2(260, 2480), "ribbons")
	# wild roses, and the pack lying up among them
	var picked := G.side_has("cr_roses")
	for o in [Vector2(-160, -60), Vector2(120, -120), Vector2(200, 90), Vector2(-90, 130), Vector2(20, -10)]:
		add_decor(ROSES + o, "rose_bare" if picked and o == Vector2(20, -10) else "rose_bush")
	add_prop("task", "roses", "Wild roses", ROSES + Vector2(20, 30), "E   Cut wild roses")
	if not picked:
		for o in [Vector2(-330, -150), Vector2(320, -220), Vector2(360, 230), Vector2(-280, 260)]:
			var w := spawn_enemy("wolf", ROSES + o)
			w.aggro = 1.0
			pack.append(w)
		add_trigger(Rect2(ROSES.x - 300, ROSES.y - 260, 600, 520), _wake_pack)
	# the clearing and the shrine
	add_decor(CLEARING + Vector2(0, -40), "shrine")
	add_decor(CLEARING + Vector2(-110, -20), "ribbons")
	add_decor(CLEARING + Vector2(120, -30), "ribbons", 0.0, true)
	add_decor(CLEARING + Vector2(30, 10), "candle")
	if G.side_has("cr_shrine"): add_decor(CLEARING + Vector2(-30, 20), "basket")
	add_prop("task", "shrine", "Sfânta Vineri's shrine", CLEARING + Vector2(0, 40), "E   Lay the offering at the shrine")
	add_torch(CLEARING, 300.0, Color(1, 0.85, 0.6), 0.55)
	add_torch(Vector2(4300, 2300), 260.0, Color(0.7, 0.75, 1), 0.25)

func _trail_dist(p: Vector2) -> float:
	var best := INF
	for k in TRAIL.size() - 1: best = minf(best, dist_to_segment(p, TRAIL[k], TRAIL[k + 1]))
	return best

func _wake_pack() -> void:
	var any := false
	for w in pack:
		if is_instance_valid(w) and w.aggro < 10.0:
			w.aggro = 2000.0; w.state = "chase"; any = true
	if any:
		Audio.sfx("howl", -6.0)
		Hud.toast("The undergrowth comes alive.")

func offering() -> void:
	add_decor(CLEARING + Vector2(-30, 20), "basket")
	# she stands in front of her shrine, beside the hunter, where the camera sees her
	var at := CLEARING + Vector2(75, 25)
	if is_instance_valid(G.player) and G.player.pos.x > CLEARING.x: at = CLEARING + Vector2(-75, 25)
	var vineri := add_prop("npc", "vineri", "Sfânta Vineri", at, "", Color("e8e0c8"))
	vineri.facing = (G.player.pos - at).normalized() if is_instance_valid(G.player) else Vector2(0, 1)
	var glow := add_torch(at + Vector2(0, -20), 360.0, Color(1, 0.95, 0.8), 1.1)
	Audio.sfx("bell", -14.0, 1.6)
	G.start_dialogue("Sfânta Vineri", [
		"(You set the basket down: apples and plums, wild roses, red poppies. The candle flame stands up straight. Then the clearing fills with a soft light, and in it, a woman in red, very old and very calm.)",
		"It has been a long time since anyone walked my path. The young ones have forgotten me, and the old ones are too tired to come.",
		"The girl worked on my day. I do not forgive that lightly. But she worked for love, and her mother worked her for pride.",
		"Tell that house to rest on my day, every one of them. The mother first. Then the girl's hands will heal before the wedding.",
		"(She draws a red ribbon from the roof of the shrine and ties it round your wrist.) Take this, so they believe you.",
		"(The light goes out. The candle is still burning.)",
	], func():
		G.side_add("cr_shrine")
		remove_prop(vineri)
		glow.queue_free()
		Hud.toast("A red ribbon from the shrine. Go back to Floarea's mother."))
