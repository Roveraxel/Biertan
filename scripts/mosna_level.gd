class_name MosnaLevel
extends Level
## Moșna: a large fortified church with a tall bell tower and a bacon tower.
## Third safe haven, last stop before the road to Biertan.

const COBBLE := Color("5e5648")


func build() -> void:
	title = "MOȘNA"
	subtitle = "Safe haven · The tower that keeps the bacon"
	size = Vector2(1900, 1250)
	spawn = Vector2(260, 620)
	ground = Color("38432e")
	tile_tint = Color(1.55, 1.45, 1.15)
	rng.seed = 31
	scatter(Rect2(0, 0, 1900, 1250), 500, [Color("55683a"), Color("2f3d22"), Color("6a7a44")], [0, 0, 1])
	scatter(Rect2(200, 160, 1500, 920), 240, [Color("7d7360"), Color("5a5142")], [1, 1])
	# double ring wall
	add_block(Rect2(160, 110, 1580, 40), "wall", 30)
	add_block(Rect2(160, 1090, 1580, 40), "wall", 30)
	add_block(Rect2(160, 110, 40, 420), "wall", 30)
	add_block(Rect2(160, 710, 40, 420), "wall", 30)
	add_block(Rect2(1700, 110, 40, 420), "wall", 30)
	add_block(Rect2(1700, 710, 40, 420), "wall", 30)
	for c in [Vector2(160, 110), Vector2(1680, 110), Vector2(160, 1070), Vector2(1680, 1070)]:
		add_block(Rect2(c.x - 10, c.y - 10, 80, 80), "tower", 74)
	for gx in [140.0, 1680.0]:
		add_block(Rect2(gx, 470, 80, 64), "tower", 62)
		add_block(Rect2(gx, 710, 80, 64), "tower", 62)
	# inner wall around the church yard (gaps north and south)
	add_block(Rect2(560, 300, 300, 26), "wall", 20)
	add_block(Rect2(1040, 300, 300, 26), "wall", 20)
	add_block(Rect2(560, 820, 300, 26), "wall", 20)
	add_block(Rect2(1040, 820, 300, 26), "wall", 20)
	add_block(Rect2(560, 300, 26, 546), "wall", 20)
	add_block(Rect2(1314, 300, 26, 546), "wall", 20)
	# hall church with the tall bell tower, and the bacon tower
	add_block(Rect2(760, 420, 380, 230), "church", 50)
	add_block(Rect2(700, 470, 80, 120), "tower", 150)
	add_block(Rect2(1220, 380, 80, 80), "tower", 96)
	# houses
	add_block(Rect2(300, 200, 200, 140), "house", 36)
	add_block(Rect2(1420, 200, 220, 140), "house", 36)
	add_block(Rect2(300, 880, 220, 130), "house", 34)
	add_block(Rect2(1400, 900, 220, 120), "house", 34)
	add_block(Rect2(860, 960, 180, 100), "house", 30)
	for p in [Vector2(520, 220), Vector2(1380, 600), Vector2(460, 640), Vector2(600, 1000), Vector2(1250, 1010)]:
		add_tree(p)
	add_prop("npc", "konrad", "Meister Konrad · Bell-founder", Vector2(950, 760), Color("3a3028"), "E   Speak with Konrad")
	add_prop("npc", "hannes", "Hannes · Keeper of the Bacon Tower", Vector2(1260, 520), Color("6a4a2a"), "E   Speak with Hannes")
	add_prop("npc", "veta", "Veta · Cantor's widow", Vector2(420, 420), Color("16141a"), "E   Speak with Veta")
	add_brazier(Vector2(860, 740)).base_energy = 0.7
	add_brazier(Vector2(1040, 740)).base_energy = 0.7
	add_torch(Vector2(230, 525), 230, Color(1.0, 0.68, 0.34), 0.7)
	add_torch(Vector2(230, 715), 230, Color(1.0, 0.68, 0.34), 0.7)
	add_torch(Vector2(1675, 525), 230, Color(1.0, 0.68, 0.34), 0.7)
	add_torch(Vector2(1675, 715), 230, Color(1.0, 0.68, 0.34), 0.7)
	add_torch(Vector2(950, 720), 240, Color(1.0, 0.55, 0.25), 0.8)
	add_torch(Vector2(420, 380), 220, Color(1.0, 0.75, 0.4), 0.6)
	add_torch(Vector2(1260, 480), 220, Color(1.0, 0.75, 0.4), 0.7)
	add_trigger(Rect2(0, 540, 70, 160), main.leave_mosna_west)
	add_trigger(Rect2(1830, 540, 70, 160), main.leave_mosna_east)


func draw_ground() -> void:
	super.draw_ground()
	var ct := G.tex("res://assets/tiles/cobble.svg")
	var area := Rect2(200, 150, 1500, 940)
	if ct != null:
		var k := 0.55
		draw_set_transform(Vector2.ZERO, 0, Vector2(k, k))
		draw_texture_rect(ct, Rect2(area.position / k, area.size / k), true, Color(0.58, 0.56, 0.54))
		draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	else:
		draw_rect(area, COBBLE)
	draw_rect(Rect2(0, 550, 200, 140), COBBLE.darkened(0.15))
	draw_rect(Rect2(1700, 550, 200, 140), COBBLE.darkened(0.15))
	draw_rect(Rect2(586, 326, 728, 494), Color(0.2, 0.25, 0.15, 0.35))
	draw_rect(area, Color(0, 0, 0, 0.18), false, 6.0)
