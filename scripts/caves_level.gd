class_name CavesLevel
extends Level
## The Salt Caves: old workings under the hills. Very dark; glowing salt
## crystals give light and refill the salt pouch. Moroi rise from the floor.

var path_pts := [
	Vector2(60, 700), Vector2(450, 640), Vector2(800, 820), Vector2(1200, 700),
	Vector2(1550, 520), Vector2(1950, 620), Vector2(2300, 860), Vector2(2650, 720), Vector2(2940, 700),
]
var chambers := [
	[Vector2(820, 860), 230.0],
	[Vector2(1550, 460), 260.0],
	[Vector2(2320, 900), 240.0],
	[Vector2(1250, 1120), 170.0],
]


func build() -> void:
	title = "THE SALT CAVES"
	subtitle = "Lord have mercy on the men below."
	size = Vector2(3000, 1400)
	spawn = Vector2(110, 700)
	ground = Color("26231f")
	tile_path = ""
	rng.seed = 303
	scatter(Rect2(0, 0, 3000, 1400), 900, [Color("35312b"), Color("1c1a17"), Color("4a4640"), Color("9a9a9e")], [1, 1, 2, 1])
	add_block(Rect2(-200, -200, 3400, 200), "hidden", 0)
	add_block(Rect2(-200, 1400, 3400, 200), "hidden", 0)
	add_block(Rect2(-200, -200, 200, 1800), "hidden", 0)
	add_block(Rect2(3000, -200, 200, 1800), "hidden", 0)
	# solid rock wherever the tunnels and chambers are not
	var y := 0.0
	while y < size.y + 60.0:
		var x := 0.0
		while x < size.x:
			var p := Vector2(x + 50.0, y + 45.0)
			if dist_to_path(p) > 130.0 and not in_chamber(p, 40.0):
				add_block(Rect2(x, y, 100, 90), "rock", rng.randf_range(50, 80))
			x += 100.0
		y += 90.0
	# side passage down to the small grave chamber
	# salt crystals: light and salt
	for c in [Vector2(520, 600), Vector2(900, 980), Vector2(1440, 360), Vector2(1700, 560), Vector2(2200, 980), Vector2(2450, 820), Vector2(1250, 1180), Vector2(2800, 660)]:
		add_prop("crystal", "crystal", "", c, Color.WHITE, "E   Chip salt from the crystal")
	add_prop("bones", "bones1", "", Vector2(1330, 1150), Color.WHITE, "E   Search the dead miner")
	add_prop("sign", "lake_sign", "", Vector2(1430, 610), Color.WHITE, "E   Read the scratched words")
	# the dead
	for p in [Vector2(760, 820), Vector2(900, 900), Vector2(1600, 420), Vector2(1500, 520), Vector2(1660, 480), Vector2(2260, 860), Vector2(2400, 940), Vector2(1200, 1100)]:
		spawn_enemy("moroi", p)
	for p in [Vector2(1950, 620), Vector2(2650, 720)]:
		spawn_enemy("shade", p)
	add_torch(Vector2(140, 700), 220, Color(1.0, 0.6, 0.3), 0.7)
	add_torch(Vector2(2880, 700), 260, Color(0.7, 1.0, 0.6), 0.6)
	add_trigger(Rect2(0, 600, 50, 200), main.leave_caves_west)
	add_trigger(Rect2(2950, 600, 50, 200), main.enter_hollow)


func ambient() -> Color:
	return Color(0.12, 0.12, 0.16)


func dist_to_path(p: Vector2) -> float:
	var best := 1e9
	for i in range(path_pts.size() - 1):
		best = minf(best, p.distance_to(Geometry2D.get_closest_point_to_segment(p, path_pts[i], path_pts[i + 1])))
	# side passage to the grave chamber
	best = minf(best, p.distance_to(Geometry2D.get_closest_point_to_segment(p, Vector2(1050, 760), Vector2(1250, 1120))) + 30.0)
	return best


func in_chamber(p: Vector2, pad := 0.0) -> bool:
	for c in chambers:
		if p.distance_to(c[0]) < c[1] + pad:
			return true
	return false


func draw_ground() -> void:
	super.draw_ground()
	draw_polyline(PackedVector2Array(path_pts), Color("3a3630"), 200.0, true)
	for c in chambers:
		draw_circle(c[0], c[1] + 30.0, Color("332f2a"))
	# the salt lake
	draw_circle(Vector2(1550, 380), 120, Color("1a2a34"))
	draw_circle(Vector2(1550, 380), 100, Color("22394a"))
	draw_arc(Vector2(1550, 380), 112, 0, TAU, 48, Color(0.9, 0.92, 0.95, 0.5), 5.0)
	# old rails
	for i in range(path_pts.size() - 1):
		var a: Vector2 = path_pts[i]
		var b: Vector2 = path_pts[i + 1]
		var n := (b - a).orthogonal().normalized() * 12.0
		draw_line(a + n, b + n, Color("3e3a34"), 2.0)
		draw_line(a - n, b - n, Color("3e3a34"), 2.0)
