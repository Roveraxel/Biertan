class_name Boss
extends Enemy
## The Vârcolac, after Romanian folklore: a lean, hound-like creature "born of
## the air". It climbs threads spun by women working at night without a candle
## and bites the moon, which bleeds red during an eclipse. When it gorges, it
## grows heavy, the threads snap and it falls. Fire and noise drive it off.

signal phase_changed(p)

var phase := 1
var bstate := "intro"
var bt := 0.0
var charge_dir := Vector2.RIGHT
var howl_t := 7.0
var swallow_t := 6.0
var howl_anim := 0.0
var eaten := 0
var arena


func setup(k: String) -> void:
	kind = "varcolac"
	hp = 360.0
	max_hp = 360.0
	speed = 105.0
	dmg = 16.0
	radius = 44.0
	coin = 60
	aggro = 9999.0


func hud_name() -> String:
	return "THE VÂRCOLAC, EATER OF THE MOON"


func hud_hint() -> String:
	if bstate == "fallen":
		return "Its threads have snapped! Strike while it lies on the ground!"
	if phase >= 2 and not vulnerable():
		return "It rides its threads in the dark. Strike it only near a lit fire."
	return ""


func gorge() -> void:
	eaten += 1
	if eaten >= 3:
		eaten = 0
		bstate = "fallen"
		bt = 0.0
		G.sfx("boss_roar", 0.0, 1.3)
		G.fx_ring(get_parent(), global_position, Color(0.9, 0.85, 0.7, 0.9), 160, 0.6)
		if arena != null:
			arena.main.toast("Gorged on flame, it grows heavy. Its threads snap and it falls!")


func vulnerable() -> bool:
	if phase == 1 or bstate == "fallen":
		return true
	for b in get_tree().get_nodes_in_group("braziers"):
		if b.lit and b.global_position.distance_to(global_position) < 260.0:
			return true
	return false


func hurt(amount: float, dir: Vector2) -> void:
	if bstate == "intro":
		return
	if not vulnerable():
		flash = 0.05
		G.fx_text(get_parent(), global_position + Vector2(0, -50), "shadow", Color("8a8aa8"))
		return
	hp -= amount
	flash = 0.1
	knock = dir * 90.0
	G.fx_text(get_parent(), global_position + Vector2(randf_range(-20, 20), -40), str(int(amount)), Color("ffe08a"))
	G.sfx("hit", -2.0, 0.75)
	if hp <= 0.0:
		die()
		return
	var r := hp / max_hp
	var np := 1 if r > 0.66 else (2 if r > 0.33 else 3)
	if np != phase:
		phase = np
		bstate = "recover"
		bt = -0.8
		phase_changed.emit(phase)
		G.fx_ring(get_parent(), global_position, Color(0.9, 0.3, 0.3, 0.9), 220, 0.8)


func die() -> void:
	died.emit(self)
	G.sfx("boss_roar", 0.0, 0.9)
	for i in 3:
		G.fx_ring(get_parent(), global_position, Color(1, 0.8, 0.5, 0.9), 120 + i * 60, 0.7 + i * 0.2)
	queue_free()


func _physics_process(delta: float) -> void:
	t += delta
	flash = maxf(0.0, flash - delta)
	atk_cd = maxf(0.0, atk_cd - delta)
	modulate.a = 1.0 if vulnerable() else 0.55
	howl_anim = maxf(0.0, howl_anim - delta)
	if player == null or not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")
	if player == null or player.hp <= 0.0:
		velocity = Vector2.ZERO
		queue_redraw()
		return
	bt += delta
	var to: Vector2 = player.global_position - global_position
	var d := to.length()
	var sm := 1.0 + 0.25 * (phase - 1)
	match bstate:
		"intro":
			velocity = Vector2.ZERO
			face = to.normalized()
			if bt > 2.5:
				bstate = "stalk"
				bt = 0.0
		"stalk":
			face = to.normalized()
			velocity = face * speed * sm + knock
			if d < radius + 34.0 and atk_cd <= 0.0:
				player.hurt(dmg, face)
				atk_cd = 1.1
			if bt > 2.4 / sm:
				bstate = "telegraph"
				bt = 0.0
				charge_dir = face
		"telegraph":
			velocity = knock
			if bt < 0.45:
				charge_dir = to.normalized()
			face = charge_dir
			if bt > 0.8 / sm:
				bstate = "charge"
				bt = 0.0
				hit_done = false
		"charge":
			velocity = charge_dir * 560.0 * sm
			if not hit_done and d < radius + 16.0:
				player.hurt(dmg * 1.4, charge_dir)
				hit_done = true
			if bt > 0.7 or is_on_wall():
				bstate = "recover"
				bt = 0.0
				G.fx_ring(get_parent(), global_position, Color(0.6, 0.5, 0.4, 0.6), 110, 0.5)
		"recover":
			velocity = knock
			if bt > 0.9 / sm:
				bstate = "stalk"
				bt = 0.0
		"fallen":
			velocity = knock
			if bt > 5.0:
				bstate = "stalk"
				bt = 0.0
	if bstate != "intro":
		howl_t -= delta
		if howl_t <= 0.0 and bstate in ["stalk", "recover"]:
			howl_t = 12.0 - 2.0 * phase
			if arena != null:
				arena.boss_howl(self)
		if phase >= 3:
			swallow_t -= delta
			if swallow_t <= 0.0:
				swallow_t = 7.0
				if arena != null:
					arena.swallow_light(self)
	knock = knock.move_toward(Vector2.ZERO, 700.0 * delta)
	move_and_slide()
	queue_redraw()


func _draw_fallback() -> void:
	var tint := Color(1, 1, 1, 1)
	if flash > 0.0:
		tint = Color(2, 2, 2, 1)
	var ang := face.angle()
	draw_set_transform(Vector2(0, 4), 0, Vector2(1, 0.45))
	draw_circle(Vector2.ZERO, 56, Color(0, 0, 0, 0.4))
	if bstate == "telegraph":
		draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
		draw_line(Vector2(0, -20), Vector2(0, -20) + charge_dir * 700.0, Color(1, 0.15, 0.1, 0.3 + 0.3 * sin(t * 25.0)), 8.0)
	var fur := Color("34343f") * tint
	# moon disc behind the head
	draw_set_transform(Vector2(0, -26), ang, Vector2.ONE)
	draw_circle(Vector2(46, 0), 44, Color(0.93, 0.88, 0.7, 0.85) * tint)
	draw_circle(Vector2(56, -6), 36, Color(0.1, 0.1, 0.15, 0.55))
	# body
	draw_set_transform(Vector2(0, -26), ang, Vector2(1.6, 1.0))
	draw_circle(Vector2.ZERO, 34, fur)
	draw_set_transform(Vector2(0, -26), ang, Vector2.ONE)
	for i in 5:
		var sx := -36.0 + i * 14.0
		draw_colored_polygon(PackedVector2Array([Vector2(sx, -26), Vector2(sx + 7, -40 - (i % 2) * 6), Vector2(sx + 14, -26)]), fur.darkened(0.25))
	draw_circle(Vector2(52, 0), 22, fur.lightened(0.08))
	draw_colored_polygon(PackedVector2Array([Vector2(48, -15), Vector2(42, -30), Vector2(58, -20)]), fur.darkened(0.3))
	draw_colored_polygon(PackedVector2Array([Vector2(48, 15), Vector2(42, 30), Vector2(58, 20)]), fur.darkened(0.3))
	draw_line(Vector2(-50, 0), Vector2(-78, sin(t * 6.0) * 10.0), fur.darkened(0.2), 9.0)
	draw_circle(Vector2(62, -7), 3.4, Color("ff2a1a"))
	draw_circle(Vector2(62, 7), 3.4, Color("ff2a1a"))
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)


func _draw() -> void:
	var pose := "idle"
	if bstate == "charge" or bstate == "telegraph":
		pose = "charge"
	elif howl_anim > 0.0:
		pose = "howl"
	var tex := G.tex("res://assets/sprites/boss_%s.svg" % pose)
	if tex == null:
		_draw_fallback()
		return
	if bstate == "telegraph":
		draw_line(Vector2(0, -20), Vector2(0, -20) + charge_dir * 700.0, Color(1, 0.15, 0.1, 0.3 + 0.3 * sin(t * 25.0)), 8.0)
	# the spun threads it climbs to the moon (snapped while it lies fallen)
	if phase >= 2:
		for i in 3:
			var x0 := -20.0 + i * 20.0
			if bstate == "fallen":
				draw_line(Vector2(x0, -60), Vector2(x0 + 10 * sin(t * 3.0 + i), -110), Color(0.9, 0.87, 0.8, 0.5), 1.5)
			else:
				draw_line(Vector2(x0, -60), Vector2(x0 * 3.0 + 30.0 * sin(t + i), -900), Color(0.9, 0.87, 0.8, 0.35), 1.5)
	var flip := face.x < 0.0
	var tilt := 0.35 if bstate == "fallen" else 0.0
	draw_set_transform(Vector2.ZERO, tilt, Vector2(-1.0 if flip else 1.0, 1.0))
	draw_texture_rect(tex, Rect2(-144, -192, 288, 216), false, Color(2, 2, 2) if flash > 0.0 else Color.WHITE)
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
