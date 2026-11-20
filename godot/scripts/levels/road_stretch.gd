## Playable exploration stretch on the road between two villages.
extends Level

static var route_key := "crit_saschiz"
static var next_dest := "saschiz"

var resolved := false
var stash_taken := false
var wolves_left := 0

func build() -> void:
	id = "road_stretch"
	size = Vector2(2600, 1400)
	ground = Color("2e3a24")
	tile = ""
	rng = NetRandom.new(hash(route_key) & 0x7fffffff)
	title = "ON THE ROAD"
	subtitle = _subtitle_for()
	scatter(Rect2(Vector2.ZERO, size), 280, [Color("364428"), Color("28341e"), Color("423c2c")])
	var road_pts := [Vector2(120, 720), Vector2(680, 680), Vector2(1300, 740), Vector2(1920, 690), Vector2(2480, 710)]
	add_path(road_pts, 125.0)
	var side_pts := [Vector2(1150, 720), Vector2(1240, 460), Vector2(1420, 320)]
	add_path(side_pts, 75.0)
	spawn = Vector2(220, 720)

	# Forest edges framing the road
	var x := 100.0
	while x < size.x - 80.0:
		for y_base in [150.0, 340.0, 1080.0, 1260.0]:
			var p := Vector2(x + rng.f_range(-60.0, 60.0), y_base + rng.f_range(-50.0, 50.0))
			if p.distance_to(Vector2(1420, 320)) < 240.0: continue
			if rng.f() < 0.25: continue
			add_tree(p, rng.f() < 0.4)
		x += 175.0

	add_wall(Vector2(size.x / 2.0, -20), Vector2(size.x, 40))
	add_wall(Vector2(size.x / 2.0, size.y + 20), Vector2(size.x, 40))
	add_wall(Vector2(-20, size.y / 2.0), Vector2(40, size.y))
	add_wall(Vector2(size.x + 20, size.y / 2.0), Vector2(40, size.y))

	add_troita(Vector2(980, 610))
	add_decor(Vector2(1420, 260), "campfire", 20.0)
	add_torch(Vector2(1420, 260), 220.0, Color(1, 0.65, 0.35), 0.7)
	add_prop("sack", "stash", "Abandoned pack", Vector2(1500, 310), "E   Search the pack")

	match route_key:
		"crit_saschiz":
			add_prop("task", "encounter", "Stolen parcel", Vector2(1380, 370), "E   Recover the parcel")
			var guard := spawn_enemy("wolf", Vector2(1320, 410))
			guard.died.connect(func(_e): Hud.toast("The clearing is safe. Grab the parcel!"))
		"saschiz_sapartoc":
			add_decor(Vector2(1350, 740), "bag_earth", 12.0)
			add_decor(Vector2(1420, 320), "shrine", 24.0)
			add_prop("task", "encounter", "Spilled dark earth", Vector2(1420, 380), "E   Inspect the dark earth")
			var ambush := spawn_enemy("strigoi", Vector2(1340, 360))
			ambush.died.connect(func(_e):
				resolved = true
				Hud.toast("The strigoi falls. Continue east down the road."))
		_:
			add_decor(Vector2(1360, 740), "fallen_log", 36.0)
			add_prop("task", "encounter", "Blocked culvert", Vector2(1290, 740), "E   Clear the fallen log")
			wolves_left = 2
			for wp in [Vector2(1420, 600), Vector2(1460, 860)]:
				var w := spawn_enemy("wolf", wp)
				w.died.connect(func(_e):
					wolves_left -= 1
					if wolves_left <= 0: Hud.toast("The wolves scatter. Clear the road!"))

	add_prop("task", "continue", "Road to %s" % G.NAMES.get(next_dest, next_dest.capitalize()), Vector2(2360, 710), "E   Continue to %s" % G.NAMES.get(next_dest, next_dest.capitalize()))
	add_trigger(Rect2(2460, 560, 120, 300), func(): _finish_road())
	finish()

func _subtitle_for() -> String:
	match route_key:
		"crit_saschiz": return "The Crossroads Troiță"
		"saschiz_sapartoc": return "A Trail of Dark Earth"
		_: return "The Blocked Culvert"

func objective() -> String:
	if not resolved:
		match route_key:
			"crit_saschiz": return "Explore the roadside clearing to recover the stolen parcel, or keep walking east."
			"saschiz_sapartoc": return "Follow the spilled dark earth off the road, or keep walking east."
			_: return "Clear the fallen log on the road."
	return "Follow the road east to %s." % G.NAMES.get(next_dest, next_dest.capitalize())

func use(p: Prop) -> void:
	match p.id:
		"stash":
			if not stash_taken:
				stash_taken = true
				G.player.coins += 15
				G.player.potions += 1
				remove_prop(p)
				Hud.toast("Found 15 coins and a tincture!")
		"encounter":
			if route_key == "apold_cris" and wolves_left > 0:
				Hud.toast("Drive off the wolves first!")
				return
			if not resolved:
				resolved = true
				G.player.coins += 15
				if route_key == "saschiz_sapartoc":
					G.player.salt_unlocked = true
					G.player.salt += 2
					Hud.toast("Found 15 coins and 2 salt pouches!")
				else:
					G.player.potions += 1
					Hud.toast("Road cleared! +15 coins, +1 tincture.")
				remove_prop(p)
		"continue":
			_finish_road()

func _finish_road() -> void:
	G.side_add("road_" + next_dest)
	Loader.goto_level(next_dest)
