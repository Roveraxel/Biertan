class_name HollowLevel
extends Level
## Muma Pădurii's Hollow: a ring of old oaks around her hollow tree-house.

const CENTER := Vector2(750, 680)
const RADIUS := 520.0

var boss: Muma
var sisters: Array = []
var spots := [Vector2(450, 440), Vector2(1050, 440), Vector2(450, 920), Vector2(1050, 920), Vector2(750, 380)]


func build() -> void:
	title = "THE HOLLOW"
	subtitle = "Muma Pădurii"
	size = Vector2(1500, 1400)
	spawn = Vector2(750, 1130)
	ground = Color("141a12")
	tile_path = ""
	rng.seed = 404
	scatter(Rect2(0, 0, 1500, 1400), 700, [Color("26321e"), Color("101610"), Color("3a4a26")], [0, 0, 2])
	var body := StaticBody2D.new()
	body.collision_layer = 1
	var n := 48
	for i in n:
		var cs := CollisionShape2D.new()
		var seg := SegmentShape2D.new()
		seg.a = CENTER + Vector2.from_angle(TAU * i / n) * RADIUS
		seg.b = CENTER + Vector2.from_angle(TAU * (i + 1) / n) * RADIUS
		cs.shape = seg
		body.add_child(cs)
	add_child(body)
	for i in 40:
		add_tree(CENTER + Vector2.from_angle(TAU * i / 40.0) * (RADIUS + 50.0 + rng.randf_range(0, 50)), i % 3 == 0)
	# hollow trees she walks between (decor only)
	for s in spots:
		var t := HollowTree.new()
		t.position = s + Vector2(0, -40)
		add_child(t)
	# salt crystals at the edge so the fight can be sustained
	for a in [0.25, 0.75, 1.25, 1.75]:
		add_prop("crystal", "crystal", "", CENTER + Vector2.from_angle(PI * a) * (RADIUS - 70.0), Color.WHITE, "E   Chip salt from the crystal")
	add_torch(CENTER, 420, Color(0.6, 1.0, 0.5), 0.35)
	boss = Muma.new()
	boss.setup("muma")
	boss.arena = self
	boss.position = CENTER + Vector2(0, -200)
	boss.phase_changed.connect(_on_phase)
	boss.died.connect(_on_dead)
	add_child(boss)
	main.boss = boss


func ambient() -> Color:
	return Color(0.32, 0.36, 0.34)


func hop_spot(from: Vector2) -> Vector2:
	var opts: Array = []
	for s in spots:
		if s.distance_to(from) > 200.0:
			opts.append(s)
	return opts[randi() % opts.size()]


## The Forest Mother splits into three sisters; only one is real.
func split(real: Muma) -> void:
	dispel_illusions()
	var free_spots: Array = spots.duplicate()
	free_spots.shuffle()
	for i in 2:
		var m := Muma.new()
		m.setup("muma")
		m.illusion = true
		m.arena = self
		m.phase = real.phase
		m.hp = real.hp
		m.max_hp = real.max_hp
		m.bstate = "walk"
		m.position = free_spots[i]
		add_child(m)
		sisters.append(m)
	G.sfx("cackle", 0.0, 0.9)
	main.toast("Three sisters stand in the Hollow. Only one is real.")


func shuffle_sisters(real: Muma) -> void:
	var live: Array = []
	for s in sisters:
		if is_instance_valid(s):
			live.append(s)
	sisters = live
	if real.phase >= 2 and sisters.is_empty():
		split(real)
		return
	for s in sisters:
		s.global_position = hop_spot(real.global_position)
		s.alpha = 0.0


func dispel_illusions() -> void:
	for s in sisters:
		if is_instance_valid(s):
			s.queue_free()
	sisters.clear()


func weave(b: Muma) -> void:
	G.sfx("whisper", -6.0, 1.2)
	var p: Vector2 = main.player.global_position
	var n := 2 + b.phase
	for i in n:
		var th := WeaveThread.new()
		var ang := randf() * PI
		var dir := Vector2.from_angle(ang)
		var off := dir.orthogonal() * randf_range(-120, 120) if i > 0 else Vector2.ZERO
		th.a = p + off - dir * 600.0
		th.b = p + off + dir * 600.0
		add_child(th)


func call_crows(b: Muma) -> void:
	if get_tree().get_nodes_in_group("enemies").size() > 7:
		return
	main.toast("Crows pour out of her hollow!")
	for i in 3:
		var e := spawn_enemy("bat", b.global_position + Vector2.from_angle(i * TAU / 3.0) * 60.0)
		e.state = "chase"


func cast_roots(b: Muma) -> void:
	G.sfx("cackle", -6.0, randf_range(0.95, 1.2))
	var n := 3 + b.phase
	for i in n:
		if not is_instance_valid(main.player):
			return
		var target: Vector2 = main.player.global_position
		if i > 0:
			target += main.player.velocity * 0.3
		var r := RootSpike.new()
		r.position = target
		r.dmg = 12.0 + 2.0 * b.phase
		add_child(r)
		await get_tree().create_timer(0.38).timeout
		if b == null or not is_instance_valid(b):
			return
	if b.phase >= 3:
		for i in 6:
			var r := RootSpike.new()
			r.position = b.global_position + Vector2.from_angle(i * TAU / 6.0) * 150.0
			r.delay = 1.0
			add_child(r)


func call_wisps(b: Muma) -> void:
	if get_tree().get_nodes_in_group("enemies").size() > 5:
		return
	main.toast("She calls the wisps of the taken!")
	for i in 2:
		spawn_enemy("shade", b.global_position + Vector2.from_angle(randf() * TAU) * 120.0)


func _on_phase(p: int) -> void:
	if p == 2:
		main.banner("THE THREE SISTERS", "Her bark turns steel and she splits in three. Salt finds the real one (R).")
		split(boss)
	elif p == 3:
		main.banner("THE WOOD AWAKENS", "Roots everywhere. Keep moving.")


func _on_dead(_e) -> void:
	main.boss = null
	main.on_muma_dead()


func draw_ground() -> void:
	super.draw_ground()
	draw_circle(CENTER, RADIUS, Color("1e2618"))
	draw_circle(CENTER, RADIUS - 40.0, Color("243020"))
	for i in 10:
		var a := Vector2.from_angle(i * TAU / 10.0 + 0.2)
		draw_polyline(PackedVector2Array([CENTER + a * 60.0, CENTER + a * 200.0 + a.orthogonal() * 30.0, CENTER + a * 380.0]), Color("2e2416"), 7.0)
	for i in 30:
		var p := CENTER + Vector2.from_angle(i * 2.1) * (90.0 + (i * 37) % 380)
		draw_circle(p, 3, Color("b3372f") if i % 4 == 0 else Color("d8d2c0"))
	draw_arc(CENTER, RADIUS, 0, TAU, 96, Color("3a3020"), 10.0)
