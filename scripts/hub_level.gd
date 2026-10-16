class_name HubLevel
extends Level
## Saschiz: fortified Saxon village. Safe haven with traders.

const COBBLE := Color("6a604d")


func build() -> void:
	title = "SASCHIZ"
	subtitle = "Safe haven · Autumn, Anno MDXXI"
	size = Vector2(1800, 1200)
	spawn = Vector2(900, 900)
	ground = Color("3c4a2c")
	rng.seed = 11
	scatter(Rect2(0, 0, 1800, 1200), 520, [Color("55683a"), Color("2f3d22"), Color("6a7a44")], [0, 0, 1])
	scatter(Rect2(190, 150, 1420, 900), 260, [Color("7d7360"), Color("5a5142")], [1, 1])
	# ring wall with gate on the east side
	add_block(Rect2(140, 100, 1520, 44), "wall", 28)
	add_block(Rect2(140, 1060, 1520, 44), "wall", 28)
	add_block(Rect2(140, 100, 44, 1004), "wall", 28)
	add_block(Rect2(1616, 100, 44, 410), "wall", 28)
	add_block(Rect2(1616, 690, 44, 414), "wall", 28)
	for c in [Vector2(140, 100), Vector2(1600, 100), Vector2(140, 1044), Vector2(1600, 1044)]:
		add_block(Rect2(c.x - 10, c.y - 10, 80, 80), "tower", 70)
	# gate towers
	add_block(Rect2(1596, 450, 80, 70), "tower", 64)
	add_block(Rect2(1596, 690, 80, 70), "tower", 64)
	# church with defensive tower
	add_block(Rect2(780, 430, 260, 250), "church", 44)
	add_block(Rect2(860, 300, 100, 120), "tower", 100)
	# houses
	add_block(Rect2(280, 200, 240, 150), "house", 38)
	add_block(Rect2(1230, 200, 240, 140), "house", 38)
	add_block(Rect2(300, 780, 190, 120), "house", 34)
	add_block(Rect2(1150, 800, 180, 120), "house", 34)
	add_block(Rect2(1440, 790, 110, 90), "house", 30)
	add_block(Rect2(676, 660, 48, 36), "stone", 16)
	# fruit trees
	for p in [Vector2(620, 300), Vector2(540, 560), Vector2(1100, 330), Vector2(1330, 620), Vector2(600, 960), Vector2(1280, 980), Vector2(230, 620)]:
		add_tree(p)
	# NPCs
	add_prop("npc", "anna", "Frau Anna Roth · Innkeeper", Vector2(410, 420), Color("8a3a4a"), "E   Speak with Anna")
	add_prop("npc", "hans", "Master Hans · Blacksmith", Vector2(1350, 410), Color("5a4a3a"), "E   Speak with Hans")
	add_prop("npc", "ileana", "Old Ileana · Herbalist", Vector2(1540, 610), Color("5a6a4a"), "E   Speak with Ileana")
	add_prop("npc", "gheorghe", "Gheorghe · Shepherd", Vector2(1100, 880), Color("7a6a4a"), "E   Speak with Gheorghe")
	# light
	add_brazier(Vector2(760, 730))
	add_brazier(Vector2(1060, 730))
	add_torch(Vector2(1590, 505), 260)
	add_torch(Vector2(1590, 695), 260)
	add_torch(Vector2(400, 372), 230, Color(1.0, 0.75, 0.4))
	add_torch(Vector2(1350, 360), 260, Color(1.0, 0.45, 0.2), 1.3)
	add_torch(Vector2(900, 470), 300, Color(1.0, 0.8, 0.5), 0.8)
	add_trigger(Rect2(1720, 520, 80, 160), main.try_leave_hub)


func draw_ground() -> void:
	super.draw_ground()
	draw_rect(Rect2(184, 144, 1432, 916), COBBLE)
	draw_rect(Rect2(1616, 530, 184, 140), COBBLE.darkened(0.15))
	draw_rect(Rect2(760, 700, 280, 300), COBBLE.lightened(0.06))
	draw_rect(Rect2(184, 144, 1432, 916), Color(0, 0, 0, 0.18), false, 6.0)
