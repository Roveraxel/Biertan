class_name BiertanLevel
extends Level
## Biertan, the lower village. Survivors hold out in the Marriage Prison,
## the one house the thralls will not enter. The fortress looms on the hill.


func build() -> void:
	title = "BIERTAN"
	subtitle = "The bells are silent. The hill is his."
	size = Vector2(1800, 1300)
	spawn = Vector2(220, 900)
	ground = Color("2a3024")
	tile_tint = Color(0.9, 0.9, 0.85)
	rng.seed = 41
	scatter(Rect2(0, 0, 1800, 1300), 600, [Color("3a4430"), Color("1e2418"), Color("4a5236")], [0, 0, 1])
	add_block(Rect2(-200, -200, 2200, 200), "hidden", 0)
	add_block(Rect2(-200, 1300, 2200, 200), "hidden", 0)
	add_block(Rect2(-200, -200, 200, 1700), "hidden", 0)
	add_block(Rect2(1800, -200, 200, 1700), "hidden", 0)
	# the fortress walls on the hill, north
	add_block(Rect2(0, 0, 820, 140), "wall", 60)
	add_block(Rect2(980, 0, 820, 140), "wall", 60)
	add_block(Rect2(780, 40, 60, 100), "tower", 110)
	add_block(Rect2(960, 40, 60, 100), "tower", 110)
	# abandoned houses along the street
	for r in [Rect2(200, 300, 200, 130), Rect2(480, 290, 180, 120), Rect2(1140, 300, 200, 130), Rect2(1420, 290, 200, 120),
			Rect2(240, 1060, 200, 120), Rect2(1300, 1060, 220, 120)]:
		add_block(r, "house", 34)
	add_block(Rect2(1560, 640, 140, 100), "ruin", 24)
	# the Marriage Prison: one small house behind a ring of salt and carts
	add_block(Rect2(820, 640, 160, 110), "house", 32)
	for a in 14:
		var ang := TAU * a / 14.0
		if absf(ang - PI) < 0.35 or absf(ang - PI / 2.0 * 3.0) < 0.35:
			continue
		var p := Vector2(900, 760) + Vector2(cos(ang) * 300.0, sin(ang) * 220.0)
		add_block(Rect2(p.x - 26, p.y - 12, 52, 24), "ruin", 16)
	add_prop("npc", "sexton", "Martin · Sexton of Biertan", Vector2(820, 830), Color("2a2a30"), "E   Speak with the sexton")
	add_prop("npc", "andreas", "Andreas", Vector2(1030, 820), Color("3a4a5a"), "E   Speak with Andreas")
	add_prop("npc", "sofia", "Sofia", Vector2(1080, 800), Color("7a2a36"), "E   Speak with Sofia")
	add_prop("sign", "prison_sign", "", Vector2(980, 770), Color.WHITE, "E   Read the door")
	add_brazier(Vector2(900, 880)).base_energy = 0.8
	add_torch(Vector2(900, 700), 300, Color(1.0, 0.7, 0.4), 0.8)
	add_torch(Vector2(900, 160), 260, Color(1.0, 0.2, 0.15), 0.6)
	for p in [Vector2(600, 600), Vector2(1250, 560), Vector2(400, 820), Vector2(1450, 900), Vector2(700, 1150)]:
		add_tree(p, true)
	add_trigger(Rect2(0, 820, 50, 200), main.leave_biertan_west)
	add_trigger(Rect2(840, 140, 120, 60), main.enter_walls)


func ambient() -> Color:
	return G.ambient(0.7)


func draw_ground() -> void:
	super.draw_ground()
	draw_line(Vector2(0, 900), Vector2(900, 900), Color("3a3428"), 110.0)
	draw_line(Vector2(900, 900), Vector2(900, 140), Color("3a3428"), 110.0)
	draw_set_transform(Vector2(900, 760), 0, Vector2(1.0, 0.73))
	draw_arc(Vector2.ZERO, 260.0, 0, TAU, 64, Color(0.9, 0.92, 0.95, 0.55), 5.0)
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
