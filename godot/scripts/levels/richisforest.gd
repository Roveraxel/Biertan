## The wood above Richiș: a pack by the path, wormwood in a glade and an old walnut at the far end.
extends Level

const TRAIL := [Vector2(160, 2600), Vector2(1000, 2400), Vector2(1900, 2650), Vector2(2800, 2450), Vector2(3700, 2250), Vector2(4600, 2500), Vector2(5500, 2600), Vector2(6300, 2450)]
const DEN := Vector2(2900, 2450)
const WORMWOOD := Vector2(4300, 1900)
const WALNUT := Vector2(6500, 2450)

var pack: Array[Enemy] = []

func build() -> void:
	title = "THE WOOD ABOVE RICHIȘ"
	subtitle = "Wormwood and walnut"
	size = Vector2(7200, 5000)
	spawn = Vector2(320, 2580)
	ground = Color("22281e")
	tile = ""
	quest = RcQuest.new()
	rng = NetRandom.new(1501)
	scatter(Rect2(Vector2.ZERO, size), 420, [Color("2e3426"), Color("262a22"), Color("444844")])
	add_path(TRAIL, 90.0)
	var x := 80.0
	while x < size.x - 60.0:
		var y := 80.0
		while y < size.y - 60.0:
			var p := Vector2(x + (rng.f() - 0.5) * 120.0, y + (rng.f() - 0.5) * 120.0)
			y += 150.0
			if _trail_dist(p) < 170.0 or p.distance_to(DEN) < 380.0 or p.distance_to(WORMWOOD) < 420.0 or p.distance_to(WALNUT) < 480.0: continue
			if rng.f() < 0.25: continue
			add_tree(p, rng.f() < 0.3)
		x += 150.0
	add_wall(Vector2(size.x / 2.0, -20), Vector2(size.x, 40))
	add_wall(Vector2(size.x / 2.0, size.y + 20), Vector2(size.x, 40))
	add_wall(Vector2(-20, size.y / 2.0), Vector2(40, size.y))
	add_wall(Vector2(size.x + 20, size.y / 2.0), Vector2(40, size.y))
	add_prop("task", "exit", "Back to Richiș", Vector2(200, 2600), "")
	add_trigger(Rect2(0, 2300, 60, 600), leave)
	if not G.side_has("rc_pack"):
		for o in [Vector2(-260, -220), Vector2(240, -240), Vector2(300, 220), Vector2(-220, 250), Vector2(0, 330)]:
			var w := spawn_enemy("wolf", DEN + o)
			w.aggro = 1.0; w.flee_low = true
			w.fled.connect(func(_e): _pack_fled())
			pack.append(w)
		add_trigger(Rect2(DEN.x - 380, DEN.y - 340, 760, 680), _wake_pack)
	for o in [Vector2(-120, -40), Vector2(110, 30), Vector2(-20, 90)]: add_decor(WORMWOOD + o, "wormwood")
	if not G.side_has("rc_wormwood"): add_prop("task", "wormwood", "Wormwood", WORMWOOD + Vector2(0, 60), "E   Cut wormwood")
	add_tree(WALNUT + Vector2(0, -140))
	add_decor(WALNUT, "walnut_leaves")
	if not G.side_has("rc_walnut"): add_prop("task", "walnut", "Walnut leaves", WALNUT + Vector2(0, 60), "E   Gather walnut leaves")
	add_torch(WORMWOOD, 240.0, Color(0.75, 0.85, 1), 0.25)
	add_torch(WALNUT, 260.0, Color(0.75, 0.85, 1), 0.3)

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

func _pack_fled() -> void:
	for w in pack:
		if is_instance_valid(w) and not w.fleeing: return
	if G.side_has("rc_pack"): return
	G.side_add("rc_pack")
	Hud.toast("The pack breaks and runs. Muma's oath holds: none of hers dies by your hand.")

func pick(p: Prop) -> void:
	if G.side_has("rc_" + p.id): return
	G.start_dialogue(p.display, [
		"(Pelin. Grey-green and bitter enough to make your eyes water. The old women hang it in the doorways at Rusalii.)" if p.id == "wormwood" else "(Walnut leaves, still green underneath the frost. Nothing likes the smell of them: not flies, not Iele.)",
	], func():
		G.side_add("rc_" + p.id)
		remove_prop(p)
		Audio.sfx("blip", -6.0, 1.2)
		Hud.toast("Protective plants %d/%d" % [RcQuest.herbs_have(), RcQuest.HERBS.size()]))

func leave() -> void:
	if G.state != G.State.PLAY or G.transitioning: return
	Loader.goto_level("richisvillage", RcQuest.forest_gate + Vector2(0, 150) if RcQuest.forest_gate != Vector2.ZERO else null)
