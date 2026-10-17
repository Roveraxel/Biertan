class_name Bear
extends Enemy
## The Bear of the Garden (Ursul din Grădina Ursului). In Ion Creangă's tale of
## Harap-Alb, the Spân sends the hero to fetch lettuce from the garden of a
## fearsome bear that no one has ever robbed and lived. An optional master,
## as hard as any on the road.

signal phase_changed(p)

var bstate := "sleep"
var bt := 0.0
var combo := 0
var charge_dir := Vector2.RIGHT
var roar_t := 9.0
var charge_t := 5.0
var slam_t := 7.0
var hive_t := 6.0
var enraged := false
var arena


func setup(_k: String) -> void:
	kind = "bear"
	hp = 750.0
	max_hp = 750.0
	speed = 150.0
	dmg = 24.0
	radius = 38.0
	coin = 0
	aggro = 9999.0


func hud_name() -> String:
	return "URSUL · THE BEAR OF THE GARDEN"


func hud_hint() -> String:
	if bstate == "rear":
		return "It rears up! Get out of the circle!"
	if enraged:
		return "Enraged. Its swipes come faster."
	return ""


func undead() -> bool:
	return false


func phase_val() -> int:
	return 2 if enraged else 1


func wake() -> void:
	if bstate == "sleep":
		bstate = "intro"
		bt = 0.0
		G.sfx("boss_roar", 2.0, 0.55)


func hurt(amount: float, dir: Vector2) -> void:
	if bstate == "sleep":
		wake()
	if bstate == "intro":
		return
	hp -= amount
	flash = 0.1
	knock = dir * 40.0
	G.fx_text(get_parent(), global_position + Vector2(randf_range(-20, 20), -70), str(int(amount)), Color("ffe08a"))
	G.sfx("hit", -2.0, 0.6)
	if hp <= 0.0:
		die()
		return
	if not enraged and hp < max_hp * 0.35:
		enraged = true
		phase_changed.emit(2)
		bstate = "roar"
		bt = 0.0


func die() -> void:
	died.emit(self)
	G.sfx("boss_roar", 0.0, 0.45)
	for i in 3:
		G.fx_ring(get_parent(), global_position, Color(0.9, 0.7, 0.4, 0.9), 120 + i * 70, 0.7 + i * 0.2)
	queue_free()


func _physics_process(delta: float) -> void:
	t += delta
	bt += delta
	flash = maxf(0.0, flash - delta)
	atk_cd = maxf(0.0, atk_cd - delta)
	if player == null or not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")
	if player == null or player.hp <= 0.0:
		velocity = Vector2.ZERO
		queue_redraw()
		return
	var to: Vector2 = player.global_position - global_position
	var d := to.length()
	var sm := 1.3 if enraged else 1.0
	match bstate:
		"sleep":
			velocity = Vector2.ZERO
			if d < 220.0:
				wake()
		"intro":
			velocity = Vector2.ZERO
			face = to.normalized()
			if bt > 1.6:
				bstate = "stalk"
				bt = 0.0
		"stalk":
			face = to.normalized()
			velocity = face * speed * sm + knock
			if d < 130.0 and atk_cd <= 0.0:
				bstate = "tel"
				bt = 0.0
				combo = 3 if enraged else 2
		"tel":
			velocity = knock
			if bt > 0.42 / sm:
				bstate = "swipe"
				bt = 0.0
				G.sfx("swing", 0.0, 0.5)
				if d < 140.0 and absf(face.angle_to(to)) < deg_to_rad(70.0):
					player.hurt(dmg, face)
		"swipe":
			velocity = face * 160.0
			if bt > 0.22:
				combo -= 1
				face = to.normalized()
				if combo > 0:
					bstate = "tel"
					bt = 0.15
				else:
					bstate = "stalk"
					bt = 0.0
					atk_cd = 1.2 / sm
		"charge_tel":
			velocity = knock
			if bt < 0.5:
				charge_dir = to.normalized()
				face = charge_dir
			if bt > 0.85 / sm:
				bstate = "charge"
				bt = 0.0
				hit_done = false
				G.sfx("boss_roar", -4.0, 0.8)
		"charge":
			velocity = charge_dir * 640.0 * sm
			if not hit_done and d < radius + 26.0:
				hit_done = true
				player.hurt(dmg * 1.3, charge_dir)
			if bt > 0.75 or is_on_wall():
				bstate = "stalk"
				bt = 0.0
				if is_on_wall():
					bstate = "dazed"
					G.fx_ring(get_parent(), global_position, Color(0.7, 0.6, 0.4, 0.8), 90, 0.4)
		"dazed":
			velocity = Vector2.ZERO
			if bt > 1.4:
				bstate = "stalk"
				bt = 0.0
		"rear":
			velocity = Vector2.ZERO
			if bt > 0.9 / sm:
				bstate = "stalk"
				bt = -0.3
				G.sfx("root", 2.0, 0.6)
				if d < 170.0:
					player.hurt(dmg * 1.4, to.normalized())
				var w := WaterWave.new()
				w.earth = true
				w.dmg = 16.0
				w.speed = 380.0
				w.max_r = 520.0
				w.position = global_position
				get_parent().add_child(w)
		"roar":
			velocity = Vector2.ZERO
			if bt > 0.6 and not hit_done:
				hit_done = true
				G.sfx("boss_roar", 4.0, 0.5)
				G.fx_ring(get_parent(), global_position, Color(1, 0.9, 0.7, 0.7), 320, 0.6)
				if d < 320.0:
					player.slow_t = maxf(player.slow_t, 1.6)
					if arena != null:
						arena.main.toast("The roar shakes your bones!")
			if bt > 1.1:
				hit_done = false
				bstate = "throw"
				bt = 0.0
		"throw":
			velocity = Vector2.ZERO
			if bt > 0.4:
				throw_hives(3 if enraged else 2)
				bstate = "stalk"
				bt = 0.0
	if bstate == "stalk" and bt > 0.0:
		charge_t -= delta
		slam_t -= delta
		roar_t -= delta
		if charge_t <= 0.0 and d > 220.0:
			charge_t = 5.0 / sm
			bstate = "charge_tel"
			bt = 0.0
		elif slam_t <= 0.0 and d < 200.0:
			slam_t = 7.0 / sm
			bstate = "rear"
			bt = 0.0
		elif roar_t <= 0.0:
			roar_t = 13.0 / sm
			bstate = "roar"
			bt = 0.0
			hit_done = false
	knock = knock.move_toward(Vector2.ZERO, 600.0 * delta)
	move_and_slide()
	queue_redraw()


func throw_hives(n: int) -> void:
	G.sfx("swing", 0.0, 0.4)
	for i in n:
		var fp := FirePatch.new()
		fp.bees = true
		fp.position = player.global_position + (Vector2.ZERO if i == 0 else Vector2.from_angle(randf() * TAU) * randf_range(70, 150))
		get_parent().add_child(fp)
	if arena != null:
		arena.main.toast("It hurls wild beehives!")


func _draw() -> void:
	draw_set_transform(Vector2(0, 4), 0, Vector2(1, 0.45))
	draw_circle(Vector2.ZERO, 54, Color(0, 0, 0, 0.45))
	if bstate == "rear":
		draw_arc(Vector2.ZERO, 170.0 / 0.45 * 0.45, 0, TAU, 48, Color(1, 0.3, 0.1, 0.35 + 0.3 * sin(t * 25.0)), 6.0)
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	if bstate == "tel":
		var a := face.angle()
		draw_arc(Vector2(0, -30), 135, a - deg_to_rad(70), a + deg_to_rad(70), 24, Color(1, 0.15, 0.1, 0.35 + 0.3 * sin(t * 30.0)), 10.0)
	if bstate == "charge_tel":
		draw_line(Vector2(0, -20), Vector2(0, -20) + charge_dir * 520.0, Color(1, 0.15, 0.1, 0.3 + 0.3 * sin(t * 25.0)), 40.0)
	var pose := "idle"
	if bstate in ["rear", "roar", "throw", "tel", "swipe"]:
		pose = "stand"
	elif bstate in ["charge", "charge_tel"]:
		pose = "charge"
	var tex := G.tex("res://assets/sprites/bear_%s.svg" % pose)
	var tint := Color(2, 2, 2) if flash > 0.0 else (Color(1.25, 0.85, 0.8) if enraged else Color.WHITE)
	var flip := face.x < 0.0
	draw_set_transform(Vector2.ZERO, 0, Vector2(-1.0 if flip else 1.0, 1.0))
	if tex != null:
		draw_texture_rect(tex, Rect2(-144, -201, 288, 216), false, tint)
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	if bstate == "sleep":
		for i in 3:
			var z := Vector2(30 + i * 14, -110 - i * 18 - fmod(t * 20.0, 18.0))
			draw_string(ThemeDB.fallback_font, z, "z", HORIZONTAL_ALIGNMENT_LEFT, -1, 16 + i * 4, Color(1, 1, 1, 0.6))
	if bstate == "dazed":
		for i in 5:
			var p := Vector2.from_angle(t * 4.0 + i * TAU / 5.0) * 30.0 + Vector2(0, -170)
			draw_circle(p, 3.0, Color(1, 0.9, 0.6, 0.9))
