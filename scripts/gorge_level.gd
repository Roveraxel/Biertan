class_name GorgeLevel
extends Level
## The flooded quarry where the Balaur lies across the road to Biertan.

var boss: Balaur


func build() -> void:
	title = "THE DROWNED QUARRY"
	subtitle = "The Balaur"
	size = Vector2(1600, 1200)
	spawn = Vector2(800, 1080)
	ground = Color("2a2723")
	tile_path = ""
	rng.seed = 505
	scatter(Rect2(0, 420, 1600, 880), 600, [Color("3a3630"), Color("1c1a17"), Color("4a4640")], [1, 1, 2])
	add_block(Rect2(-200, -200, 2000, 200), "hidden", 0)
	add_block(Rect2(-200, 1200, 2000, 200), "hidden", 0)
	add_block(Rect2(-200, -200, 200, 1700), "hidden", 0)
	add_block(Rect2(1600, -200, 200, 1700), "hidden", 0)
	add_block(Rect2(0, 0, 1600, 470), "hidden", 0)
	# quarry walls
	for y in range(470, 1200, 90):
		add_block(Rect2(0, y, 120, 90), "rock", rng.randf_range(60, 90))
		add_block(Rect2(1480, y, 120, 90), "rock", rng.randf_range(60, 90))
	for x in range(120, 1480, 100):
		if absf(x + 50 - 800) > 120:
			add_block(Rect2(x, 1120, 100, 80), "rock", 60)
	for p in [Vector2(320, 640), Vector2(1280, 640), Vector2(400, 980), Vector2(1200, 980)]:
		add_brazier(p)
	boss = Balaur.new()
	boss.main = main
	boss.arena = self
	boss.position = Vector2(800, 380)
	add_torch(Vector2(800, 330), 520, Color(0.55, 0.85, 0.6), 0.55)
	boss.died.connect(_on_dead)
	add_child(boss)
	boss.build_heads()
	main.boss = boss


func ambient() -> Color:
	return Color(0.42, 0.44, 0.52)


func on_head_sealed() -> void:
	main.banner("THE BALAUR THRASHES", "Its remaining heads grow wilder.")


func call_bats() -> void:
	if get_tree().get_nodes_in_group("enemies").size() > 8:
		return
	main.toast("Bats pour from the quarry walls!")
	G.sfx("bat", -4.0)
	for i in 3:
		var e := spawn_enemy("bat", Vector2([150.0, 1450.0][i % 2], randf_range(600, 1000)))
		e.state = "chase"


func _on_dead(_b) -> void:
	main.boss = null
	main.on_balaur_dead()


func draw_ground() -> void:
	super.draw_ground()
	draw_rect(Rect2(0, 0, 1600, 480), Color("0c1a20"))
	var shore := PackedVector2Array()
	for i in 33:
		var x := i * 50.0
		shore.append(Vector2(x, 470.0 + sin(i * 1.7) * 14.0))
	draw_polyline(shore, Color("8a8a7a"), 8.0)
	for i in 14:
		draw_line(Vector2(i * 120.0 + 30, 120 + (i % 4) * 80), Vector2(i * 120.0 + 90, 120 + (i % 4) * 80), Color(0.5, 0.6, 0.65, 0.25), 2.0)
	draw_rect(Rect2(720, 1120, 160, 80), Color("3a3630"))
