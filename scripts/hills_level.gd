class_name HillsLevel
extends Level
## The Hollow Hills: open meadow and standing stones, where the Iele dance in
## mushroom rings at dusk. Ends at the mouth of the Salt Caves.

var path_pts := [
	Vector2(60, 850), Vector2(500, 760), Vector2(950, 900), Vector2(1450, 780),
	Vector2(1900, 880), Vector2(2400, 760), Vector2(2800, 820), Vector2(3060, 800),
]
var rings := [
	[Vector2(900, 480), 3],
	[Vector2(1700, 1180), 3],
	[Vector2(2350, 420), 4],
]
var cross_used := false
var lurk_t := 6.0


func build() -> void:
	title = "THE HOLLOW HILLS"
	subtitle = "If you hear singing, do not dance."
	size = Vector2(3200, 1700)
	spawn = Vector2(120, 850)
	ground = Color("2a3322")
	tile_tint = Color(0.95, 0.95, 0.85)
	rng.seed = 202
	scatter(Rect2(0, 0, 3200, 1700), 1300, [Color("3a4a2c"), Color("26301e"), Color("4a5a34"), Color("5a5a3a")], [0, 0, 0, 1])
	scatter(Rect2(0, 0, 3200, 1700), 140, [Color("9a8a6a"), Color("6a2a2a")], [1])
	add_block(Rect2(-200, -200, 3600, 200), "hidden", 0)
	add_block(Rect2(-200, 1700, 3600, 200), "hidden", 0)
	add_block(Rect2(-200, -200, 200, 2100), "hidden", 0)
	add_block(Rect2(3200, -200, 200, 2100), "hidden", 0)
	# tree copses on the slopes
	for c in [Vector2(400, 300), Vector2(500, 1350), Vector2(1300, 250), Vector2(1250, 1400), Vector2(2000, 300), Vector2(2200, 1350), Vector2(2800, 300), Vector2(2750, 1300)]:
		for i in 14:
			var p: Vector2 = c + Vector2(rng.randf_range(-220, 220), rng.randf_range(-170, 170))
			if dist_to_path(p) > 170.0 and not in_ring(p):
				add_tree(p, rng.randf() < 0.5)
	# standing stones
	for s in [Vector2(700, 1000), Vector2(760, 1060), Vector2(1550, 600), Vector2(2650, 1050), Vector2(2600, 990)]:
		add_block(Rect2(s.x, s.y, 26, 18), "stone", 46)
	# cliffs and the cave mouth in the east
	add_block(Rect2(3060, 0, 140, 720), "rock", 70)
	add_block(Rect2(3060, 900, 140, 800), "rock", 70)
	add_block(Rect2(2960, 560, 100, 160), "rock", 60)
	add_block(Rect2(2960, 900, 100, 160), "rock", 60)
	add_torch(Vector2(3000, 740), 200, Color(1.0, 0.6, 0.3), 0.8)
	add_torch(Vector2(3000, 880), 200, Color(1.0, 0.6, 0.3), 0.8)
	# props
	add_prop("cross", "cross", "", Vector2(1450, 700), Color.WHITE, "E   Pray at the wayside cross")
	add_prop("sack", "sack_h", "", Vector2(2700, 1020), Color.WHITE, "E   Take the coin sack")
	add_prop("sign", "cave_sign", "", Vector2(2900, 700), Color.WHITE, "E   Read the miners' post")
	# Iele in their rings, wolves on the road
	for r in rings:
		for i in r[1]:
			var e := spawn_enemy("iele", r[0] + Vector2.from_angle(i * TAU / r[1]) * 70.0)
			e.home = r[0]
			e.orbit = i * TAU / r[1]
	for c in [Vector2(1100, 860), Vector2(2000, 860), Vector2(2600, 800)]:
		for i in 3:
			spawn_enemy("wolf", c + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(20, 70))
	spawn_enemy("pricolici", Vector2(2450, 760))
	add_trigger(Rect2(0, 730, 50, 240), main.leave_hills_west)
	add_trigger(Rect2(3110, 720, 90, 180), main.enter_caves)


func dist_to_path(p: Vector2) -> float:
	var best := 1e9
	for i in range(path_pts.size() - 1):
		best = minf(best, p.distance_to(Geometry2D.get_closest_point_to_segment(p, path_pts[i], path_pts[i + 1])))
	return best


func in_ring(p: Vector2) -> bool:
	for r in rings:
		if p.distance_to(r[0]) < 190.0:
			return true
	return false


func _process(delta: float) -> void:
	if main == null or main.state != "play":
		return
	lurk_t -= delta
	if lurk_t <= 0.0:
		lurk_t = lerpf(12.0, 5.0, G.dusk) + randf() * 3.0
		var pl = main.player
		if get_tree().get_nodes_in_group("lurkers").size() < 2:
			var p: Vector2 = pl.global_position + Vector2.from_angle(randf() * TAU) * randf_range(280.0, 420.0)
			if Rect2(Vector2(80, 80), size - Vector2(160, 160)).has_point(p) and dist_to_path(p) > 140.0:
				var l := Lurker.new()
				l.position = p
				add_child(l)


func draw_ground() -> void:
	super.draw_ground()
	# rolling hill shading
	for i in 9:
		var c := Vector2(200 + i * 360, 300 + (i % 3) * 450)
		draw_circle(c, 260, Color(0, 0, 0, 0.07))
		draw_circle(c + Vector2(-40, -40), 200, Color(1, 1, 0.8, 0.03))
	draw_polyline(PackedVector2Array(path_pts), Color("3a3020"), 120.0, true)
	draw_polyline(PackedVector2Array(path_pts), Color("4e4230"), 80.0, true)
	# mushroom rings
	for r in rings:
		var c: Vector2 = r[0]
		draw_circle(c, 150, Color("2f3a26"))
		for i in 28:
			var p := c + Vector2.from_angle(i * TAU / 28.0) * 120.0
			draw_rect(Rect2(p.x - 1.5, p.y - 6, 3, 6), Color("d8d2c0"))
			draw_circle(p + Vector2(0, -7), 5, Color("e8e0cc") if i % 3 else Color("b3372f"))
	# cave mouth
	draw_rect(Rect2(2960, 720, 240, 180), Color("0d0c0b"))
	draw_rect(Rect2(3060, 740, 140, 140), Color("050505"))
