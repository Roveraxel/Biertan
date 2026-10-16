class_name Enemy
extends CharacterBody2D

signal died(enemy)

var kind := "wolf"
var hp := 20.0
var max_hp := 20.0
var speed := 140.0
var dmg := 8.0
var radius := 14.0
var coin := 3
var aggro := 400.0
var atk_cd := 0.0
var state := "idle"
var t := 0.0
var flash := 0.0
var face := Vector2.RIGHT
var knock := Vector2.ZERO
var lunge_dir := Vector2.ZERO
var hit_done := false
var player: Node2D
var home := Vector2.ZERO
var orbit := 0.0
var salted := 0.0
static var song_t := 0.0


func setup(k: String) -> void:
	kind = k
	match k:
		"wolf":
			hp = 18.0; speed = 150.0; dmg = 7.0; radius = 13.0; coin = 3; aggro = 430.0
		"pricolici":
			hp = 46.0; speed = 118.0; dmg = 14.0; radius = 17.0; coin = 9; aggro = 460.0
		"scarecrow":
			hp = 62.0; speed = 62.0; dmg = 12.0; radius = 16.0; coin = 7; aggro = 170.0
			state = "dormant"
		"shade":
			hp = 14.0; speed = 128.0; dmg = 6.0; radius = 12.0; coin = 0; aggro = 700.0
		"iele":
			hp = 26.0; speed = 170.0; dmg = 9.0; radius = 12.0; coin = 5; aggro = 330.0
			orbit = randf() * TAU
		"moroi":
			hp = 60.0; speed = 76.0; dmg = 14.0; radius = 15.0; coin = 8; aggro = 190.0
			state = "dormant"
	max_hp = hp


func _ready() -> void:
	add_to_group("enemies")
	collision_layer = 4
	collision_mask = 1
	var cs := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = radius * 0.8
	cs.shape = c
	add_child(cs)


func _physics_process(delta: float) -> void:
	t += delta
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
	var mult := 1.0 + 0.4 * G.dusk
	salted = maxf(0.0, salted - delta)
	if kind == "iele" and iele_step(delta, to, d, mult):
		knock = knock.move_toward(Vector2.ZERO, 900.0 * delta)
		move_and_slide()
		queue_redraw()
		return
	match state:
		"dormant", "idle":
			velocity = knock
			if d < aggro:
				if kind == "moroi" and state == "dormant":
					state = "rise"
					t = 0.0
					G.sfx("moroi", -4.0, randf_range(0.85, 1.1))
				else:
					state = "chase"
		"rise":
			velocity = Vector2.ZERO
			if t > 0.8:
				state = "chase"
		"chase":
			var dir := to.normalized()
			face = dir
			if kind == "pricolici" and d < 200.0 and atk_cd <= 0.0:
				state = "windup"
				t = 0.0
			else:
				velocity = dir * speed * mult + knock + separation()
				if d < radius + 26.0 and atk_cd <= 0.0:
					player.hurt(dmg * mult, dir)
					atk_cd = 1.0
		"windup":
			velocity = knock
			face = to.normalized()
			if t > 0.5:
				state = "lunge"
				t = 0.0
				lunge_dir = to.normalized()
				hit_done = false
		"lunge":
			velocity = lunge_dir * 470.0
			if not hit_done and d < radius + 24.0:
				player.hurt(dmg * mult, lunge_dir)
				hit_done = true
			if t > 0.3 or is_on_wall():
				state = "chase"
				atk_cd = 1.5
	knock = knock.move_toward(Vector2.ZERO, 900.0 * delta)
	move_and_slide()
	queue_redraw()


func undead() -> bool:
	return kind in ["iele", "moroi", "shade"]


func salt_hit(ring: Node2D, delta: float) -> void:
	var burn := 16.0 if kind == "moroi" else 11.0
	hp -= burn * delta
	flash = 0.05
	var out: Vector2 = (global_position - ring.global_position).normalized()
	knock = out * 260.0
	if salted <= 0.0:
		G.fx_text(get_parent(), global_position + Vector2(0, -30), "salt!", Color("e8eeff"))
		if state == "dormant":
			state = "chase"
	salted = 0.6
	if hp <= 0.0:
		die()


## Iele: dance around their fairy ring, then circle the hunter, sing to
## slow and draw them in, and dart in for a strike.
func iele_step(delta: float, to: Vector2, d: float, mult: float) -> bool:
	if state in ["windup", "lunge"]:
		return false
	if state == "idle":
		orbit += delta * 1.3
		var target := home + Vector2.from_angle(orbit) * 70.0
		velocity = (target - global_position) * 3.0 + knock
		face = Vector2.from_angle(orbit + PI / 2.0)
		if d < aggro:
			state = "chase"
			if song_t <= 0.0:
				G.sfx("iele_song", -6.0, randf_range(0.95, 1.05))
				song_t = 4.5
				player.main.toast("The Iele sing. Your legs grow heavy...")
		return true
	song_t = maxf(0.0, song_t - delta / 3.0)
	orbit += delta * 1.5
	var tgt: Vector2 = player.global_position + Vector2.from_angle(orbit) * 135.0
	face = to.normalized()
	velocity = (tgt - global_position).limit_length(speed * mult) + knock + separation()
	if salted > 0.0:
		velocity = -to.normalized() * speed + knock
	if d < 290.0 and salted <= 0.0 and not player.wormwood:
		player.slow_t = maxf(player.slow_t, 0.15)
		player.pull += -to.normalized() * 55.0
	if song_t <= 0.0 and d < 300.0:
		song_t = 4.5
		G.sfx("iele_song", -9.0, randf_range(0.9, 1.1))
	if d < 210.0 and atk_cd <= 0.0 and salted <= 0.0:
		state = "windup"
		t = 0.15
	if d > aggro * 2.2:
		state = "idle"
	return true


func separation() -> Vector2:
	var push := Vector2.ZERO
	for o in get_tree().get_nodes_in_group("enemies"):
		if o != self:
			var dv: Vector2 = global_position - o.global_position
			var dl := dv.length()
			if dl < 32.0 and dl > 0.1:
				push += dv / dl * (32.0 - dl) * 5.0
	return push


func hurt(amount: float, dir: Vector2) -> void:
	hp -= amount
	flash = 0.12
	knock = dir * 280.0
	G.sfx("hit", -5.0)
	if state == "dormant" or state == "idle":
		state = "chase"
	G.fx_text(get_parent(), global_position, str(int(amount)), Color("ffe08a"))
	if hp <= 0.0:
		die()


func die() -> void:
	died.emit(self)
	if coin > 0 and player != null and is_instance_valid(player):
		player.coins += coin
		G.sfx("coin", -12.0)
		G.fx_text(get_parent(), global_position + Vector2(0, -16), "+%d" % coin, G.AMBER)
	G.fx_ring(get_parent(), global_position, Color(0.8, 0.8, 0.9, 0.8), 40)
	queue_free()


func _draw_fallback() -> void:
	var tint := Color(1, 1, 1, 1)
	if flash > 0.0:
		tint = Color(2, 2, 2, 1)
	draw_set_transform(Vector2(0, 2), 0, Vector2(1, 0.45))
	draw_circle(Vector2.ZERO, radius * 1.2, Color(0, 0, 0, 0.35))
	var ang := face.angle()
	match kind:
		"wolf", "pricolici":
			var big := kind == "pricolici"
			var fur := Color("4a4a52") if not big else Color("5a3a2a")
			fur = fur * tint
			var s := 1.3 if big else 1.0
			draw_set_transform(Vector2(0, -10 * s), ang, Vector2(1.5, 1.0))
			draw_circle(Vector2.ZERO, 10 * s, fur)
			draw_set_transform(Vector2(0, -10 * s), ang, Vector2.ONE)
			draw_circle(Vector2(16 * s, 0), 7 * s, fur.lightened(0.1))
			draw_colored_polygon(PackedVector2Array([Vector2(13, -5) * s, Vector2(10, -11) * s, Vector2(17, -7) * s]), fur.darkened(0.3))
			draw_colored_polygon(PackedVector2Array([Vector2(13, 5) * s, Vector2(10, 11) * s, Vector2(17, 7) * s]), fur.darkened(0.3))
			draw_line(Vector2(-14, 0) * s, Vector2(-26, sin(t * 10.0) * 4.0) * s, fur.darkened(0.2), 4.0)
			draw_circle(Vector2(20 * s, -2.5 * s), 1.6, Color("ff3a2a"))
			draw_circle(Vector2(20 * s, 2.5 * s), 1.6, Color("ff3a2a"))
			if state == "windup":
				draw_circle(Vector2.ZERO, 22 * s, Color(1, 0.2, 0.1, 0.25 + 0.2 * sin(t * 30.0)))
		"scarecrow":
			var straw := Color("a8903a") * tint
			var live := state != "dormant"
			draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
			draw_line(Vector2(0, 0), Vector2(0, -34), Color("4a3320"), 4.0)
			draw_line(Vector2(-18, -26), Vector2(18, -26), Color("4a3320"), 4.0)
			draw_circle(Vector2(0, -22), 11, straw.darkened(0.2))
			draw_circle(Vector2(-18, -24), 4, straw)
			draw_circle(Vector2(18, -24), 4, straw)
			draw_circle(Vector2(0, -40), 8, straw)
			draw_colored_polygon(PackedVector2Array([Vector2(-11, -44), Vector2(11, -44), Vector2(0, -58)]), Color("2a2118"))
			var eye := Color("ff8a2a") if live else Color("1a1410")
			draw_circle(Vector2(-3, -40), 1.8, eye)
			draw_circle(Vector2(3, -40), 1.8, eye)
		"shade":
			var wob := sin(t * 6.0) * 3.0
			draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
			draw_circle(Vector2(0, -20 + wob), 12, Color(0.8, 0.9, 1.0, 0.45))
			draw_colored_polygon(PackedVector2Array([Vector2(-12, -20 + wob), Vector2(12, -20 + wob), Vector2(14, 0), Vector2(6, -4), Vector2(0, 2), Vector2(-6, -4), Vector2(-14, 0)]), Color(0.8, 0.9, 1.0, 0.4))
			draw_circle(Vector2(-4, -22 + wob), 2, Color(0.1, 0.1, 0.2, 0.9))
			draw_circle(Vector2(4, -22 + wob), 2, Color(0.1, 0.1, 0.2, 0.9))
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	if hp < max_hp:
		var w := 30.0
		draw_rect(Rect2(-w / 2.0, -radius * 3.2 - 6.0, w, 4), Color(0, 0, 0, 0.7))
		draw_rect(Rect2(-w / 2.0, -radius * 3.2 - 6.0, w * hp / max_hp, 4), Color("c0392b"))


func draw_health_bar() -> void:
	if hp < max_hp:
		var w := 30.0
		draw_rect(Rect2(-w / 2.0, -radius * 3.2 - 6.0, w, 4), Color(0, 0, 0, 0.7))
		draw_rect(Rect2(-w / 2.0, -radius * 3.2 - 6.0, w * hp / max_hp, 4), Color("c0392b"))


func _draw() -> void:
	if kind == "scarecrow":
		var stex := G.tex("res://assets/sprites/scarecrow_%s.svg" % ("dormant" if state == "dormant" else "awake"))
		if stex != null:
			draw_texture_rect(stex, Rect2(-40, -69, 80, 80), false, Color(2, 2, 2) if flash > 0.0 else Color.WHITE)
			draw_health_bar()
			return
	if kind == "shade":
		var htex := G.tex("res://assets/sprites/shade_%s.svg" % ("a" if int(t * 3.0) % 2 == 0 else "b"))
		if htex != null:
			var al := 0.8 + 0.15 * sin(t * 5.0)
			draw_texture_rect(htex, Rect2(-36, -62, 72, 72), false, Color(1, 1, 1, al) if flash <= 0.0 else Color(2, 2, 2, 1))
			draw_health_bar()
			return
	if kind == "iele":
		var itex := G.tex("res://assets/sprites/iele_%s.svg" % ("a" if int(t * 4.0) % 2 == 0 else "b"))
		if itex != null:
			var al := 0.78 + 0.18 * sin(t * 4.0)
			var hov := sin(t * 3.0 + orbit) * 4.0
			draw_texture_rect(itex, Rect2(-36, -66 + hov, 72, 72), false, Color(2, 2, 2) if flash > 0.0 else Color(1, 1, 1, al))
			if state == "windup":
				draw_circle(Vector2(0, -26), 22, Color(0.7, 0.8, 1.0, 0.25 + 0.2 * sin(t * 30.0)))
			draw_health_bar()
			return
	if kind == "moroi":
		var mtex := G.tex("res://assets/sprites/moroi_%s.svg" % ("dormant" if state == "dormant" else "awake"))
		if mtex != null:
			var rise := clampf(t / 0.8, 0.0, 1.0) if state == "rise" else 1.0
			var flip := face.x < 0.0
			draw_set_transform(Vector2(0, 10.0 * (1.0 - rise)), 0, Vector2(-1.0 if flip else 1.0, rise if state == "rise" else 1.0))
			draw_texture_rect(mtex, Rect2(-40, -69, 80, 80), false, Color(2, 2, 2) if flash > 0.0 else Color.WHITE)
			draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
			draw_health_bar()
			return
	if kind == "wolf" or kind == "pricolici":
		var path := "res://assets/sprites/wolf_idle.svg"
		if state == "windup" or state == "lunge":
			path = "res://assets/sprites/wolf_lunge.svg"
		elif velocity.length() > 40.0 and int(t * 8.0) % 2 == 0:
			path = "res://assets/sprites/wolf_run.svg"
		var tex := G.tex(path)
		if tex != null:
			var s := 1.3 if kind == "pricolici" else 1.0
			var tint := Color(1.25, 0.88, 0.75) if kind == "pricolici" else Color.WHITE
			if flash > 0.0:
				tint = Color(2, 2, 2)
			var flip := face.x < 0.0
			draw_set_transform(Vector2.ZERO, 0, Vector2(-s if flip else s, s))
			draw_texture_rect(tex, Rect2(-46.5, -61, 96, 72), false, tint)
			draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
			if state == "windup":
				draw_circle(Vector2(0, -14), 24 * s, Color(1, 0.2, 0.1, 0.22 + 0.18 * sin(t * 30.0)))
			draw_health_bar()
			return
	_draw_fallback()
