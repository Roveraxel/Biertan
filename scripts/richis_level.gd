class_name RichisLevel
extends Level
## Richiș: a smaller fortified village around its hall church, famous for the
## Green Man carvings. Second safe haven.

const COBBLE := Color("625a4a")


func build() -> void:
	title = "RICHIȘ"
	subtitle = "Safe haven · The church of the Green Men"
	size = Vector2(1800, 1200)
	spawn = Vector2(260, 600)
	ground = Color("3a4630")
	tile_tint = Color(1.6, 1.5, 1.2)
	rng.seed = 21
	scatter(Rect2(0, 0, 1800, 1200), 480, [Color("55683a"), Color("2f3d22"), Color("6a7a44")], [0, 0, 1])
	scatter(Rect2(200, 160, 1400, 880), 220, [Color("7d7360"), Color("5a5142")], [1, 1])
	# oval-ish ring wall with west and east gates
	add_block(Rect2(160, 110, 1480, 40), "wall", 26)
	add_block(Rect2(160, 1050, 1480, 40), "wall", 26)
	add_block(Rect2(160, 110, 40, 400), "wall", 26)
	add_block(Rect2(160, 690, 40, 400), "wall", 26)
	add_block(Rect2(1600, 110, 40, 400), "wall", 26)
	add_block(Rect2(1600, 690, 40, 400), "wall", 26)
	for c in [Vector2(160, 110), Vector2(1580, 110), Vector2(160, 1030), Vector2(1580, 1030)]:
		add_block(Rect2(c.x - 10, c.y - 10, 76, 76), "tower", 66)
	for gx in [140.0, 1580.0]:
		add_block(Rect2(gx, 450, 80, 64), "tower", 60)
		add_block(Rect2(gx, 690, 80, 64), "tower", 60)
	# hall church: long nave, west tower
	add_block(Rect2(700, 380, 420, 220), "church", 46)
	add_block(Rect2(620, 410, 90, 140), "tower", 104)
	# houses
	add_block(Rect2(300, 200, 220, 140), "house", 36)
	add_block(Rect2(1240, 210, 230, 140), "house", 36)
	add_block(Rect2(320, 820, 200, 120), "house", 34)
	add_block(Rect2(1200, 820, 220, 120), "house", 34)
	add_block(Rect2(860, 880, 150, 100), "house", 30)
	# well and fruit trees
	add_block(Rect2(976, 690, 48, 36), "stone", 16)
	for p in [Vector2(560, 260), Vector2(1100, 260), Vector2(600, 980), Vector2(1450, 600), Vector2(420, 640), Vector2(1350, 980)]:
		add_tree(p)
	# NPCs and lore
	add_prop("npc", "pastor", "Pfarrer Lukas · Pastor", Vector2(900, 690), Color("1c1a20"), "E   Speak with the pastor")
	add_prop("npc", "vasile", "Vasile · Salt Miner", Vector2(1380, 420), Color("8a8a86"), "E   Speak with Vasile")
	add_prop("npc", "katharina", "Katharina · Herbalist", Vector2(420, 400), Color("24324e"), "E   Speak with Katharina")
	add_prop("npc", "rozalia", "Rozalia · Mother", Vector2(1100, 1000), Color("e8e2d2"), "E   Speak with Rozalia")
	add_prop("greenman", "greenman", "", Vector2(1150, 630), Color.WHITE, "E   Look at the carving")
	# light
	add_brazier(Vector2(820, 720)).base_energy = 0.7
	add_brazier(Vector2(1180, 720)).base_energy = 0.7
	add_torch(Vector2(230, 505), 230, Color(1.0, 0.68, 0.34), 0.7)
	add_torch(Vector2(230, 695), 230, Color(1.0, 0.68, 0.34), 0.7)
	add_torch(Vector2(1575, 505), 230, Color(1.0, 0.68, 0.34), 0.7)
	add_torch(Vector2(1575, 695), 230, Color(1.0, 0.68, 0.34), 0.7)
	add_torch(Vector2(420, 360), 220, Color(1.0, 0.75, 0.4), 0.8)
	add_torch(Vector2(1380, 380), 220, Color(0.85, 0.9, 1.0), 0.6)
	add_torch(Vector2(900, 600), 260, Color(1.0, 0.8, 0.5), 0.5)
	add_trigger(Rect2(0, 520, 70, 160), main.leave_richis_west)
	add_trigger(Rect2(1730, 520, 70, 160), main.leave_richis_east)


func draw_ground() -> void:
	super.draw_ground()
	var ct := G.tex("res://assets/tiles/cobble.svg")
	var area := Rect2(200, 150, 1400, 900)
	if ct != null:
		var k := 0.55
		draw_set_transform(Vector2.ZERO, 0, Vector2(k, k))
		draw_texture_rect(ct, Rect2(area.position / k, area.size / k), true, Color(0.6, 0.58, 0.56))
		draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	else:
		draw_rect(area, COBBLE)
	draw_rect(Rect2(0, 530, 200, 140), COBBLE.darkened(0.15))
	draw_rect(Rect2(1600, 530, 200, 140), COBBLE.darkened(0.15))
	draw_rect(area, Color(0, 0, 0, 0.18), false, 6.0)
