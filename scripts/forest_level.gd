class_name ForestLevel
extends Level
## The Wolf Forest between Saschiz and Richis.

var path_pts := [
	Vector2(80, 900), Vector2(600, 950), Vector2(1000, 820), Vector2(1400, 760),
	Vector2(1800, 900), Vector2(2300, 960), Vector2(2700, 840), Vector2(3300, 880),
]
var glades := [
	[Vector2(1150, 480), 130.0],
	[Vector2(1550, 480), 170.0],
	[Vector2(2000, 700), 120.0],
	[Vector2(1300, 1040), 120.0],
	[Vector2(2700, 1080), 120.0],
	# hidden corners: lost ewes, the hermit's spring, treasure ground
	[Vector2(560, 260), 110.0],
	[Vector2(2950, 260), 110.0],
	[Vector2(2200, 1560), 110.0],
	[Vector2(420, 1520), 150.0],
	[Vector2(1300, 180), 90.0],
	[Vector2(2550, 1380), 90.0],
	[Vector2(3200, 1600), 90.0],
]
const EWES := {"ewe1": Vector2(560, 260), "ewe2": Vector2(2950, 260), "ewe3": Vector2(2200, 1560)}
const TREASURES := {"tr1": Vector2(1300, 180), "tr2": Vector2(2550, 1380), "tr3": Vector2(3200, 1600)}
var voice_started := false
var voice_trapped := false
var voice_rewarded := false
var night_t := 0.0
var lurk_t := 5.0


func build() -> void:
	title = "THE WOLF FOREST"
	subtitle = "Keep to the path. Never answer a voice that knows your name."
	size = Vector2(3400, 1800)
	spawn = Vector2(160, 900)
	ground = Color("1f2a1c")
	rng.seed = 77
	scatter(Rect2(0, 0, 3400, 1800), 1100, [Color("2c3a24"), Color("17211a"), Color("3a4a2c")], [0, 0, 1, 2])
	scatter(Rect2(0, 0, 3400, 1800), 160, [Color("5a3a1c"), Color("7a4a1c")], [2])
	# invisible map border
	add_block(Rect2(-200, -200, 3800, 200), "hidden", 0)
	add_block(Rect2(-200, 1800, 3800, 200), "hidden", 0)
	add_block(Rect2(-200, -200, 200, 2200), "hidden", 0)
	add_block(Rect2(3400, -200, 200, 2200), "hidden", 0)
	# trees
	var y := 40.0
	while y < size.y:
		var x := 40.0
		while x < size.x:
			var p := Vector2(x + rng.randf_range(-35, 35), y + rng.randf_range(-35, 35))
			if dist_to_path(p) > 175.0 and not in_glade(p):
				add_tree(p)
			x += 100.0
		y += 90.0
	# ruined shepherd's hut, torn fleece and a coin sack
	add_block(Rect2(1480, 420, 100, 22), "ruin", 14)
	add_block(Rect2(1480, 420, 22, 90), "ruin", 14)
	add_prop("fleece", "fleece", "", Vector2(1630, 500), Color.WHITE, "E   Examine the fleece")
	add_prop("sack", "sack1", "", Vector2(1545, 520), Color.WHITE, "E   Take the coin sack")
	add_prop("sign", "sign", "", Vector2(3150, 840), Color.WHITE, "E   Read the carved post")
	# side quests
	if main.ewe_q >= 1:
		for id in EWES:
			if not main.side_has(id):
				add_prop("ewe", id, "", EWES[id], Color.WHITE, "E   Tie a cord to the lost ewe")
	add_prop("npc", "hermit", "Pafnutie · Hermit", Vector2(400, 1490), Color("4a3a28"), "E   Speak with the hermit")
	add_prop("spring", "spring", "", Vector2(470, 1560), Color.WHITE, "E   Drink from the spring")
	for id in TREASURES:
		if not main.side_has(id):
			add_prop("treasure", id, "", TREASURES[id], Color.WHITE, "E   Dig where the blue flame burns")
	add_torch(Vector2(430, 1530), 200, Color(0.6, 0.85, 1.0), 0.5)
	add_brazier(Vector2(3200, 800))
	add_brazier(Vector2(3200, 960))
	# enemies
	pack("wolf", Vector2(900, 880), 3)
	pack("wolf", Vector2(1550, 780), 3)
	pack("wolf", Vector2(2250, 960), 3)
	pack("wolf", Vector2(2900, 850), 3)
	pack("pricolici", Vector2(1800, 900), 1)
	pack("pricolici", Vector2(2500, 900), 1)
	pack("pricolici", Vector2(2950, 800), 1)
	pack("scarecrow", Vector2(1230, 700), 1)
	pack("scarecrow", Vector2(2010, 720), 1)
	pack("scarecrow", Vector2(1300, 1040), 1)
	pack("scarecrow", Vector2(2700, 1080), 1)
	# events and exits
	add_trigger(Rect2(0, 780, 60, 240), main.leave_forest_west)
	add_trigger(Rect2(3310, 760, 90, 240), main.enter_arena)
	add_trigger(Rect2(1040, 700, 80, 260), start_voice)
	add_trigger(Rect2(1070, 410, 170, 150), spring_trap)
	add_trigger(Rect2(1860, 780, 80, 260), reward_voice)


func dist_to_path(p: Vector2) -> float:
	var best := 1e9
	for i in range(path_pts.size() - 1):
		var a: Vector2 = path_pts[i]
		var b: Vector2 = path_pts[i + 1]
		var cp := Geometry2D.get_closest_point_to_segment(p, a, b)
		best = minf(best, p.distance_to(cp))
	return best


func in_glade(p: Vector2) -> bool:
	for g in glades:
		if p.distance_to(g[0]) < g[1]:
			return true
	return false


func pack(kind: String, c: Vector2, n: int) -> void:
	for i in n:
		var off := Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(20, 70)
		spawn_enemy(kind, c + off)


func start_voice() -> void:
	if voice_started:
		return
	voice_started = true
	main.voice("“…Wanderer… come, the fire is warm here…”  A woman's voice, calling from the trees.")


func spring_trap() -> void:
	if voice_trapped or not voice_started:
		return
	voice_trapped = true
	main.toast("You answered. Pale shades of the Iele rise from the grass!")
	for i in 3:
		spawn_enemy("shade", Vector2(1150, 480) + Vector2.from_angle(i * TAU / 3.0) * 90.0)


func reward_voice() -> void:
	if voice_started and not voice_trapped and not voice_rewarded:
		voice_rewarded = true
		main.player.coins += 30
		main.toast("You did not answer. The voice falls silent.  +30 coins")


func spawn_lurker() -> bool:
	var pl = main.player
	var cap := 4 if G.dusk > 0.8 else 3
	if get_tree().get_nodes_in_group("lurkers").size() >= cap:
		return false
	for i in 12:
		var p: Vector2 = pl.global_position + Vector2.from_angle(randf() * TAU) * randf_range(250.0, 420.0)
		if p.x < 80 or p.y < 80 or p.x > size.x - 80 or p.y > size.y - 80:
			continue
		if dist_to_path(p) < 130.0:
			continue
		var l := Lurker.new()
		l.position = p
		add_child(l)
		return true
	return false


func _process(delta: float) -> void:
	if main == null or main.state != "play":
		return
	lurk_t -= delta
	if lurk_t <= 0.0:
		lurk_t = lerpf(9.0, 3.5, G.dusk) + randf() * 3.0
		spawn_lurker()
	if G.dusk < 0.85:
		return
	night_t += delta
	if night_t > 7.0 and get_tree().get_nodes_in_group("enemies").size() < 10:
		night_t = 0.0
		var p: Vector2 = main.player.global_position + Vector2.from_angle(randf() * TAU) * 620.0
		p = p.clamp(Vector2(60, 60), size - Vector2(60, 60))
		spawn_enemy("wolf", p)
		main.toast("Night hunters stir in the dark...")
		G.sfx("howl", -6.0)


func draw_ground() -> void:
	super.draw_ground()
	draw_polyline(PackedVector2Array(path_pts), Color("3a2e20"), 150.0, true)
	draw_polyline(PackedVector2Array(path_pts), Color("4a3a28"), 100.0, true)
	for g in glades:
		draw_circle(g[0], g[1], Color("2a3524"))
	draw_circle(Vector2(470, 1570), 34, Color("2a4a5a"))
	draw_circle(Vector2(470, 1570), 26, Color("3a6a7a"))
