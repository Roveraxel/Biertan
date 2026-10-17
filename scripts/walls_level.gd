class_name WallsLevel
extends Level
## The climb up Biertan hill through its three ring walls. Each gate is held
## shut by a blood ward; break the ward to raise the portcullis.

var gates: Array = []
var wards_left := 3
const WALL_Y := [1900.0, 1250.0, 650.0]
const GATE_X := [570.0, 1770.0, 1200.0]
const WARDS := [Vector2(1000, 2080), Vector2(1250, 1450), Vector2(650, 840)]


func build() -> void:
	title = "THE THREE WALLS"
	subtitle = "Three rings of stone. Three wards of blood."
	size = Vector2(2400, 2600)
	spawn = Vector2(1200, 2500)
	ground = Color("262a20")
	rng.seed = 707
	scatter(Rect2(0, 0, 2400, 2600), 1300, [Color("333a28"), Color("1a1e16"), Color("44463a")], [0, 1, 1])
	add_block(Rect2(-200, -200, 2800, 200), "hidden", 0)
	add_block(Rect2(-200, 2600, 2800, 200), "hidden", 0)
	add_block(Rect2(-200, -200, 200, 3000), "hidden", 0)
	add_block(Rect2(2400, -200, 200, 3000), "hidden", 0)
	for i in 3:
		var y: float = WALL_Y[i]
		var gx: float = GATE_X[i]
		add_block(Rect2(120, y, gx - 70 - 120, 44), "wall", 34 + i * 6)
		add_block(Rect2(gx + 70, y, 2280 - gx - 70, 44), "wall", 34 + i * 6)
		add_block(Rect2(gx - 110, y - 20, 40, 70), "tower", 70 + i * 10)
		add_block(Rect2(gx + 70, y - 20, 40, 70), "tower", 70 + i * 10)
		var g := Gate.new()
		g.setup(Rect2(gx - 70, y, 140, 44))
		add_child(g)
		gates.append(g)
		add_torch(Vector2(gx, y + 70), 200, Color(1.0, 0.25, 0.2), 0.7)
		var w := spawn_enemy("ward", WARDS[i])
		w.atk_cd = 3.0
		w.died.connect(_on_ward.bind(i))
	# pines on the steep flanks
	for y in range(80, 2600, 110):
		for x in [60.0, 2340.0]:
			add_tree(Vector2(x + rng.randf_range(-30, 30), y + rng.randf_range(-20, 20)), true)
	# ruined houses and graves between the walls
	for r in [Rect2(400, 2200, 160, 100), Rect2(1600, 2300, 180, 110), Rect2(500, 1500, 160, 100), Rect2(1800, 1600, 150, 100), Rect2(1600, 900, 160, 100)]:
		add_block(r, "ruin", 22)
	# the church at the top
	add_block(Rect2(900, 200, 600, 260), "church", 60)
	add_block(Rect2(780, 240, 110, 160), "tower", 170)
	add_torch(Vector2(1200, 520), 240, Color(1.0, 0.6, 0.35), 0.8)
	add_brazier(Vector2(1000, 560))
	add_brazier(Vector2(1400, 560))
	add_prop("cross", "cross", "", Vector2(1500, 1100), Color.WHITE, "E   Pray at the wayside cross")
	# the garrison
	for p in [Vector2(800, 2300), Vector2(1400, 2200), Vector2(1700, 2050)]:
		spawn_enemy("strigoi", p)
	for i in 4:
		spawn_enemy("wolf", Vector2(1100 + i * 40, 2250))
	for p in [Vector2(800, 1600), Vector2(1000, 1700), Vector2(1500, 1500), Vector2(1700, 1400)]:
		spawn_enemy("moroi", p)
	for i in 3:
		var e := spawn_enemy("iele", Vector2(400, 1450) + Vector2.from_angle(i * TAU / 3.0) * 70.0)
		e.home = Vector2(400, 1450)
	spawn_enemy("strigoi", Vector2(1300, 1350))
	for p in [Vector2(900, 900), Vector2(1500, 800), Vector2(500, 1000)]:
		spawn_enemy("shade", p)
	spawn_enemy("pricolici", Vector2(1100, 1000))
	spawn_enemy("pricolici", Vector2(1800, 950))
	spawn_enemy("strigoi", Vector2(900, 750))
	spawn_enemy("strigoi", Vector2(1500, 720))
	add_trigger(Rect2(1080, 2550, 240, 50), main.leave_walls_south)
	add_trigger(Rect2(1140, 460, 120, 40), main.enter_church)


func ambient() -> Color:
	return G.ambient(0.8)


func _on_ward(_e, i: int) -> void:
	wards_left -= 1
	gates[i].open()
	G.sfx("ward", 0.0)
	main.banner("THE %s GATE OPENS" % ["OUTER", "MIDDLE", "INNER"][i], "%d ward%s remain." % [wards_left, "" if wards_left == 1 else "s"] if wards_left > 0 else "The church door stands before you.")


func draw_ground() -> void:
	super.draw_ground()
	var pts := PackedVector2Array([Vector2(1200, 2600), Vector2(1100, 2200), Vector2(570, 2000), Vector2(570, 1850),
		Vector2(1000, 1650), Vector2(1770, 1400), Vector2(1770, 1200), Vector2(1400, 950), Vector2(1200, 700), Vector2(1200, 470)])
	draw_polyline(pts, Color("3a3428"), 110.0, true)
	for y in [2400.0, 1700.0, 1050.0]:
		for i in 6:
			var g := Vector2(250 + i * 70, y)
			draw_rect(Rect2(g.x - 3, g.y - 26, 6, 26), Color("4d4840"))
			draw_rect(Rect2(g.x - 10, g.y - 20, 20, 4), Color("4d4840"))
