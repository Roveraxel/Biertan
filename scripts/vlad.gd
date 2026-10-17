class_name Vlad
extends Enemy
## Strigoi Vlad, the master of Biertan. Claws, blinks behind the hunter as a
## cloud of bats and hurls blood. From phase 2 he is mist: only the toll of
## the great bell drags him back into flesh. Phase 3: his presence drinks.

signal phase_changed(p)

var phase := 1
var bstate := "intro"
var bt := 0.0
var bolt_t := 4.0
var blink_t := 7.0
var bat_t := 10.0
var vuln_t := 0.0
var combo := 0
var slowed := 0.0
var arena


func setup(_k: String) -> void:
	kind = "vlad"
	hp = 600.0
	max_hp = 600.0
	speed = 120.0
	dmg = 14.0
	radius = 26.0
	coin = 0
	aggro = 9999.0


func hud_name() -> String:
	return "STRIGOI VLAD"


func hud_hint() -> String:
	if phase >= 2 and not vulnerable():
		return "He is mist. Ring the great bell (%s)!" % ("USE" if G.touch_mode else "E")
	if phase >= 3 and not (player != null and player.garlic):
		return "Stay out of his reach: his presence drinks your blood."
	return ""


func undead() -> bool:
	return true


func vulnerable() -> bool:
	return phase == 1 or vuln_t > 0.0


func salt_hit(_ring: Node2D, delta: float) -> void:
	slowed = 0.4
	if vulnerable():
		hp -= 6.0 * delta


func bell_toll() -> void:
	vuln_t = 7.0
	bstate = "stunned"
	bt = 0.0
	G.fx_ring(get_parent(), global_position, Color(1.0, 0.9, 0.6, 0.9), 200, 0.7)


func hurt(amount: float, dir: Vector2) -> void:
	if bstate in ["intro", "blink"]:
		return
	if not vulnerable():
		flash = 0.05
		G.fx_text(get_parent(), global_position + Vector2(0, -70), "mist", Color("c8a0a8"))
		return
	hp -= amount
	flash = 0.1
	knock = dir * 80.0
	G.fx_text(get_parent(), global_position + Vector2(randf_range(-20, 20), -60), str(int(amount)), Color("ffe08a"))
	G.sfx("hit", -2.0, 0.8)
	if hp <= 0.0:
		die()
		return
	var r := hp / max_hp
	var np := 1 if r > 0.66 else (2 if r > 0.33 else 3)
	if np != phase:
		phase = np
		vuln_t = 0.0
		bstate = "stalk"
		bt = -0.8
		phase_changed.emit(phase)
		G.sfx("laugh", 0.0, 0.9)
		G.fx_ring(get_parent(), global_position, Color(0.8, 0.1, 0.1, 0.9), 240, 0.9)


func die() -> void:
	died.emit(self)
	G.sfx("boss_roar", 0.0, 0.6)
	for i in 4:
		G.fx_ring(get_parent(), global_position, Color(1, 0.3, 0.25, 0.9), 100 + i * 80, 0.6 + i * 0.25)
	queue_free()


func _physics_process(delta: float) -> void:
	t += delta
	bt += delta
	flash = maxf(0.0, flash - delta)
	atk_cd = maxf(0.0, atk_cd - delta)
	vuln_t = maxf(0.0, vuln_t - delta)
	slowed = maxf(0.0, slowed - delta)
	if player == null or not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")
	if player == null or player.hp <= 0.0:
		velocity = Vector2.ZERO
		queue_redraw()
		return
	var to: Vector2 = player.global_position - global_position
	var d := to.length()
	var sm := (1.0 + 0.2 * (phase - 1)) * (0.4 if slowed > 0.0 else 1.0)
	match bstate:
		"intro":
			velocity = Vector2.ZERO
			face = to.normalized()
			if bt > 3.0:
				bstate = "stalk"
				bt = 0.0
				G.sfx("laugh", -2.0)
		"stalk":
			face = to.normalized()
			velocity = face * speed * sm + knock
			if d < 110.0 and atk_cd <= 0.0:
				bstate = "tel"
				bt = 0.0
				combo = 2 if phase == 1 else 3
		"tel":
			velocity = knock
			if bt > 0.45 / sm:
				bstate = "claw"
				bt = 0.0
				G.sfx("swing", -2.0, 0.7)
				if d < 125.0 and absf(face.angle_to(to)) < deg_to_rad(70.0):
					player.hurt(dmg, face)
		"claw":
			velocity = face * 260.0
			if bt > 0.18:
				combo -= 1
				face = to.normalized()
				if combo > 0:
					bstate = "tel"
					bt = 0.2
				else:
					bstate = "stalk"
					bt = 0.0
					atk_cd = 1.4
		"cast":
			velocity = knock
			if bt > 0.6:
				shoot()
				bstate = "stalk"
				bt = 0.0
		"blink":
			velocity = Vector2.ZERO
			if bt > 0.6:
				global_position = (player.global_position - player.facing * 90.0).clamp(Vector2(140, 200), arena.size - Vector2(140, 140)) if arena != null else global_position
				bstate = "tel"
				bt = 0.0
				combo = 1
				face = (player.global_position - global_position).normalized()
				G.sfx("blink", -2.0, 0.8)
		"stunned":
			velocity = knock
			if bt > 2.0:
				bstate = "stalk"
				bt = 0.0
	if bstate == "stalk" and bt > 0.0:
		bolt_t -= delta
		blink_t -= delta
		if bolt_t <= 0.0:
			bolt_t = 5.0 - phase
			bstate = "cast"
			bt = 0.0
		elif blink_t <= 0.0:
			blink_t = 8.0 - phase
			bstate = "blink"
			bt = 0.0
			G.sfx("blink", -2.0, 1.2)
			G.sfx("bat", -6.0)
		if phase >= 3:
			bat_t -= delta
			if bat_t <= 0.0 and arena != null:
				bat_t = 12.0
				arena.call_bats(self)
	if phase >= 3 and bstate != "intro" and d < 170.0 and not player.garlic and player.inv_t <= 0.0:
		player.hp = maxf(1.0, player.hp - 5.0 * delta)
		hp = minf(max_hp, hp + 5.0 * delta)
	knock = knock.move_toward(Vector2.ZERO, 700.0 * delta)
	modulate.a = 0.0 if bstate == "blink" else (1.0 if vulnerable() else 0.5 + 0.1 * sin(t * 3.0))
	move_and_slide()
	queue_redraw()


func shoot() -> void:
	G.sfx("bolt", -2.0)
	var n := 3 + phase * 2
	var base := (player.global_position - global_position).angle()
	for i in n:
		var b := BloodBolt.new()
		var a := base + (i - (n - 1) / 2.0) * 0.18
		b.vel = Vector2.from_angle(a) * (300.0 + 40.0 * phase)
		b.position = global_position + Vector2.from_angle(a) * 30.0
		get_parent().add_child(b)


func _draw() -> void:
	draw_set_transform(Vector2(0, 4), 0, Vector2(1, 0.45))
	draw_circle(Vector2.ZERO, 34, Color(0, 0, 0, 0.45))
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	if phase >= 3 and not (player != null and player.garlic):
		draw_set_transform(Vector2(0, 4), 0, Vector2(1, 0.45))
		draw_arc(Vector2.ZERO, 170.0 / 0.45 * 0.45, 0, TAU, 48, Color(0.7, 0.05, 0.1, 0.25 + 0.1 * sin(t * 4.0)), 4.0)
		draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	if bstate == "tel":
		var a := face.angle()
		draw_arc(Vector2(0, -30), 115, a - deg_to_rad(70), a + deg_to_rad(70), 24, Color(1, 0.15, 0.1, 0.35 + 0.3 * sin(t * 30.0)), 9.0)
	var pose := "idle"
	if bstate == "cast":
		pose = "cast"
	elif bstate in ["tel", "claw"]:
		pose = "claw"
	var tex := G.tex("res://assets/sprites/vlad_%s.svg" % pose)
	var tint := Color(2, 2, 2) if flash > 0.0 else Color.WHITE
	if not vulnerable() and flash <= 0.0:
		tint = Color(0.8, 0.6, 0.7)
	var flip := face.x < 0.0
	draw_set_transform(Vector2.ZERO, 0, Vector2(-1.0 if flip else 1.0, 1.0))
	if tex != null:
		draw_texture_rect(tex, Rect2(-144, -196, 288, 216), false, tint)
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	if not vulnerable():
		for i in 6:
			var p := Vector2(sin(t * 1.3 + i) * 40.0, -40.0 - 20.0 * i + fmod(t * 30.0 + i * 20.0, 30.0))
			draw_circle(p, 14, Color(0.5, 0.1, 0.15, 0.12))
	if bstate == "stunned":
		for i in 5:
			var p := Vector2.from_angle(t * 4.0 + i * TAU / 5.0) * 30.0 + Vector2(0, -180)
			draw_circle(p, 3.0, Color(1, 0.9, 0.6, 0.9))
