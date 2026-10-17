class_name ArenaLevel
extends Level
## Boss clearing: the Vârcolac.

const CENTER := Vector2(700, 700)
const RADIUS := 500.0

var boss: Boss
var braziers: Array = []
var darkness := 0.0


func build() -> void:
	title = "THE MOON CLEARING"
	subtitle = "The Vârcolac, eater of the moon"
	size = Vector2(1400, 1400)
	spawn = Vector2(700, 1130)
	ground = Color("101510")
	tile_path = ""
	rng.seed = 5
	scatter(Rect2(0, 0, 1400, 1400), 500, [Color("1c261a"), Color("0d130d")], [0, 1])
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var n := 48
	for i in n:
		var a := Vector2.from_angle(TAU * i / n) * RADIUS + CENTER
		var b := Vector2.from_angle(TAU * (i + 1) / n) * RADIUS + CENTER
		var cs := CollisionShape2D.new()
		var seg := SegmentShape2D.new()
		seg.a = a
		seg.b = b
		cs.shape = seg
		body.add_child(cs)
	add_child(body)
	for a in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		braziers.append(add_brazier(CENTER + a * 300.0))
	for i in 36:
		var ang := TAU * i / 36.0
		add_tree(CENTER + Vector2.from_angle(ang) * (RADIUS + 60.0 + rng.randf_range(0, 40)), true)
	boss = Boss.new()
	boss.setup("varcolac")
	boss.arena = self
	boss.position = CENTER + Vector2(0, -260)
	boss.phase_changed.connect(_on_phase)
	boss.died.connect(_on_boss_died)
	add_child(boss)
	main.boss = boss


func ambient() -> Color:
	var base := G.ambient(0.7)
	return base.lerp(Color(0.16, 0.05, 0.06), darkness)


func _process(delta: float) -> void:
	var target := 1.0 if (boss != null and is_instance_valid(boss) and boss.phase >= 2) else 0.0
	darkness = move_toward(darkness, target, delta * 0.8)


func _on_phase(p: int) -> void:
	if p == 2:
		main.banner("IT CLIMBS THE THREADS TO THE MOON", "The moon bleeds. Light the fires: the vârcolac fears flame and noise.")
		for b in braziers:
			b.decays = true
			b.set_lit(false)
	elif p == 3:
		main.banner("IT DEVOURS THE FIRES", "Let it gorge. When it grows heavy, its threads will snap.")


func _on_boss_died(_e) -> void:
	main.boss = null
	main.on_boss_dead()


func boss_howl(b: Boss) -> void:
	main.toast("The vârcolac howls, and the hounds answer!")
	G.sfx("boss_howl", 0.0, 1.0)
	b.howl_anim = 1.2
	G.fx_ring(self, b.global_position, Color(0.9, 0.9, 1.0, 0.7), 260, 0.8)
	if get_tree().get_nodes_in_group("enemies").size() < 7:
		for i in 2:
			spawn_enemy("wolf", b.global_position + Vector2.from_angle(randf() * TAU) * 90.0)


func swallow_light(b: Boss) -> void:
	var lit_list: Array = []
	for br in braziers:
		if br.lit:
			lit_list.append(br)
	if lit_list.is_empty():
		return
	var br: Brazier = lit_list[randi() % lit_list.size()]
	br.set_lit(false)
	G.fx_ring(self, br.global_position, Color(0.2, 0.2, 0.4, 0.9), 140, 0.7)
	main.toast("The vârcolac swallows a flame!")
	G.sfx("flee", -2.0, 0.7)
	b.gorge()


func draw_ground() -> void:
	super.draw_ground()
	draw_circle(CENTER, RADIUS, Color("232a1f"))
	draw_circle(CENTER, RADIUS - 40.0, Color("2b3326"))
	draw_arc(CENTER, 380.0, 0, TAU, 64, Color("3d4636"), 3.0)
	draw_arc(CENTER, 190.0, 0, TAU, 48, Color("3d4636"), 3.0)
	for i in 8:
		var a := Vector2.from_angle(TAU * i / 8.0)
		draw_line(CENTER + a * 190.0, CENTER + a * 380.0, Color("3d4636"), 2.0)
	draw_arc(CENTER, RADIUS, 0, TAU, 96, Color("5d584f"), 10.0)
