class_name VineyardLevel
extends Level
## The Burnt Vineyards: terraced slopes of dead vines, burned cottages and an
## abandoned churchyard where the strigoi lie. Bats come with the dark.

var path_pts := [
	Vector2(60, 900), Vector2(500, 980), Vector2(900, 820), Vector2(1350, 900),
	Vector2(1800, 760), Vector2(2250, 860), Vector2(2700, 760), Vector2(3140, 780),
]
const YARD := Rect2(1500, 1100, 560, 380)
var graves: Array = []
var bat_t := 10.0


func build() -> void:
	title = "THE BURNT VINEYARDS"
	subtitle = "The dead of Moșna do not lie still."
	size = Vector2(3200, 1700)
	spawn = Vector2(120, 900)
	ground = Color("2e2a20")
	tile_tint = Color(0.75, 0.7, 0.55)
	rng.seed = 606
	scatter(Rect2(0, 0, 3200, 1700), 1000, [Color("3a3426"), Color("231f17"), Color("4a3e2a"), Color("1a1612")], [0, 1, 1, 2])
	add_block(Rect2(-200, -200, 3600, 200), "hidden", 0)
	add_block(Rect2(-200, 1700, 3600, 200), "hidden", 0)
	add_block(Rect2(-200, -200, 200, 2100), "hidden", 0)
	add_block(Rect2(3200, -200, 200, 2100), "hidden", 0)
	# vine terraces, broken where the road and the churchyard pass
	var y := 120.0
	while y < 1660.0:
		var x := 60.0
		while x < 3140.0:
			var seg := Rect2(x, y, rng.randf_range(160, 300), 14)
			var c := seg.get_center()
			if dist_to_path(c) > 140.0 and not YARD.grow(80).has_point(c):
				add_block(seg, "vine", 0)
			x += seg.size.x + rng.randf_range(60, 120)
		y += 95.0
	# burned cottages
	for r in [Rect2(700, 560, 160, 110), Rect2(2400, 1050, 170, 110), Rect2(2600, 420, 150, 100)]:
		add_block(r, "ruin", 22)
	# the churchyard
	add_block(Rect2(YARD.position.x, YARD.position.y, YARD.size.x, 20), "stone", 14)
	add_block(Rect2(YARD.position.x, YARD.end.y - 20, YARD.size.x, 20), "stone", 14)
	add_block(Rect2(YARD.position.x, YARD.position.y, 20, YARD.size.y), "stone", 14)
	add_block(Rect2(YARD.end.x - 20, YARD.position.y, 20, 140), "stone", 14)
	add_block(Rect2(YARD.end.x - 20, YARD.position.y + 240, 20, 140), "stone", 14)
	add_block(Rect2(1560, 1140, 120, 90), "ruin", 40)
	for gy in [1260.0, 1340.0, 1420.0]:
		for gx in [1720.0, 1820.0, 1920.0]:
			graves.append(Vector2(gx, gy))
	for i in graves.size():
		if i % 2 == 0:
			var e := spawn_enemy("strigoi", graves[i] + Vector2(0, 10))
			e.state = "dormant"
			e.aggro = 230.0
	# strigoi and wolves on the road
	for p in [Vector2(1100, 860), Vector2(2000, 820), Vector2(2650, 780)]:
		spawn_enemy("strigoi", p)
	for c in [Vector2(700, 950), Vector2(2300, 870)]:
		for i in 3:
			spawn_enemy("wolf", c + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(20, 60))
	for i in 5:
		spawn_enemy("bat", Vector2(1400 + i * 40, 500 + (i % 2) * 40))
	add_prop("cross", "cross", "", Vector2(1350, 830), Color.WHITE, "E   Pray at the wayside cross")
	add_prop("bones", "bones_v", "", Vector2(1800, 1220), Color.WHITE, "E   Search the open grave")
	add_prop("sign", "yard_sign", "", Vector2(2080, 1290), Color.WHITE, "E   Read the gate inscription")
	add_prop("sign", "quarry_sign", "", Vector2(3020, 700), Color.WHITE, "E   Read the waymark")
	add_torch(Vector2(1790, 1190), 260, Color(0.7, 0.8, 1.0), 0.35)
	add_trigger(Rect2(0, 780, 50, 240), main.leave_vineyard_west)
	add_trigger(Rect2(3150, 680, 50, 200), main.enter_gorge)


func dist_to_path(p: Vector2) -> float:
	var best := 1e9
	for i in range(path_pts.size() - 1):
		best = minf(best, p.distance_to(Geometry2D.get_closest_point_to_segment(p, path_pts[i], path_pts[i + 1])))
	best = minf(best, p.distance_to(Geometry2D.get_closest_point_to_segment(p, Vector2(1750, 790), Vector2(2140, 1290))))
	return best


func _process(delta: float) -> void:
	if main == null or main.state != "play" or G.dusk < 0.6:
		return
	bat_t -= delta
	if bat_t <= 0.0:
		bat_t = lerpf(14.0, 7.0, G.dusk)
		if get_tree().get_nodes_in_group("enemies").size() < 14:
			var p: Vector2 = main.player.global_position + Vector2.from_angle(randf() * TAU) * 520.0
			p = p.clamp(Vector2(60, 60), size - Vector2(60, 60))
			for i in 3:
				var e := spawn_enemy("bat", p + Vector2(i * 20, 0))
				e.state = "chase"
			main.toast("A swarm of bats comes out of the dusk.")
			G.sfx("bat", -6.0)


func draw_ground() -> void:
	super.draw_ground()
	draw_polyline(PackedVector2Array(path_pts), Color("2a2218"), 130.0, true)
	draw_polyline(PackedVector2Array(path_pts), Color("43382a"), 90.0, true)
	draw_line(Vector2(1750, 790), Vector2(2140, 1290), Color("3a3024"), 70.0)
	draw_rect(YARD, Color("26281e"))
	for g in graves:
		draw_rect(Rect2(g.x - 16, g.y - 6, 32, 16), Color("1a1410"))
		draw_rect(Rect2(g.x - 3, g.y - 34, 6, 28), Color("5d584f"))
		draw_rect(Rect2(g.x - 11, g.y - 28, 22, 5), Color("5d584f"))
	for i in 20:
		var p := Vector2(400 + i * 150, 300 + (i * 97) % 1200)
		draw_circle(p, 26, Color(0.05, 0.04, 0.03, 0.35))
