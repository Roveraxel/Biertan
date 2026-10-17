class_name ChurchLevel
extends Level
## Inside the fortified church of Biertan. Vlad waits at the altar.
## The rope of the great bell hangs in the tower doorway.

var boss: Vlad
var bell_cd := 0.0
var bell: Prop


func build() -> void:
	title = "THE CHURCH OF BIERTAN"
	subtitle = "Strigoi Vlad"
	size = Vector2(1400, 1500)
	spawn = Vector2(700, 1380)
	ground = Color("3a3630")
	tile_path = ""
	rng.seed = 808
	scatter(Rect2(0, 0, 1400, 1500), 300, [Color("46423a"), Color("2c2924")], [1, 2])
	add_block(Rect2(0, 0, 1400, 140), "wall", 80)
	add_block(Rect2(0, 1440, 1400, 60), "wall", 40)
	add_block(Rect2(0, 0, 80, 1500), "wall", 40)
	add_block(Rect2(1320, 0, 80, 1500), "wall", 40)
	# pews, with a wide aisle
	for y in range(560, 1300, 130):
		add_block(Rect2(180, y, 300, 24), "pew", 14)
		add_block(Rect2(920, y, 300, 24), "pew", 14)
	# altar
	add_block(Rect2(600, 200, 200, 60), "stone", 30)
	for x in [200.0, 420.0, 980.0, 1200.0]:
		add_block(Rect2(x - 22, 300, 44, 44), "stone", 80)
	for p in [Vector2(560, 230), Vector2(840, 230), Vector2(300, 1400), Vector2(1100, 1400), Vector2(160, 400), Vector2(1240, 400)]:
		add_torch(p, 260, Color(1.0, 0.7, 0.4), 0.7)
	bell = add_prop("bell", "bell", "", Vector2(140, 760), Color.WHITE, "E   Ring the great bell")
	bell.main = main
	boss = Vlad.new()
	boss.setup("vlad")
	boss.arena = self
	boss.position = Vector2(700, 480)
	boss.phase_changed.connect(_on_phase)
	boss.died.connect(_on_dead)
	add_child(boss)
	main.boss = boss


func ambient() -> Color:
	return Color(0.38, 0.34, 0.4)


func _process(delta: float) -> void:
	bell_cd = maxf(0.0, bell_cd - delta)


func ring_bell() -> void:
	if bell_cd > 0.0:
		main.toast("The bell still sways. Wait for it.")
		return
	bell_cd = 12.0
	G.sfx("bell", 2.0)
	G.fx_ring(self, bell.global_position, Color(1.0, 0.9, 0.6, 0.8), 400, 1.0)
	if boss != null and is_instance_valid(boss):
		if boss.phase >= 2:
			boss.bell_toll()
			main.toast("The great bell tolls! Vlad is dragged out of the mist!")
		else:
			main.toast("The great bell tolls. Vlad flinches.")


func call_bats(v: Vlad) -> void:
	if get_tree().get_nodes_in_group("enemies").size() > 7:
		return
	main.toast("He breaks into bats and calls their kin!")
	for i in 4:
		var e := spawn_enemy("bat", v.global_position + Vector2.from_angle(i * TAU / 4.0) * 60.0)
		e.state = "chase"


func _on_phase(p: int) -> void:
	if p == 2:
		main.banner("THE NIHIL RITE", "Throw salt and stand in it! Then ring the bell to break his mist.")
	elif p == 3:
		main.banner("THE MASTER HUNGERS", "His presence drinks your blood. Keep away, or wear garlic.")


func _on_dead(_e) -> void:
	main.boss = null
	main.on_vlad_dead()


func draw_ground() -> void:
	super.draw_ground()
	for y in range(140, 1440, 60):
		for x in range(80, 1320, 60):
			if (x / 60 + y / 60) % 2 == 0:
				draw_rect(Rect2(x, y, 60, 60), Color(0, 0, 0, 0.08))
	draw_rect(Rect2(560, 140, 280, 1300), Color("4a1418"))
	draw_rect(Rect2(570, 140, 260, 1300), Color("5a1a1e"))
	draw_rect(Rect2(620, 290, 160, 50), Color("1a1012"))
	draw_rect(Rect2(630, 280, 140, 14), Color("2a1a1c"))
	draw_rect(Rect2(80, 700, 110, 120), Color("26221e"))
