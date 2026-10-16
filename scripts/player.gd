class_name Player
extends CharacterBody2D

signal died

var main
var hp := 100.0
var max_hp := 100.0
var speed := 205.0
var dmg := 12.0
var facing := Vector2.RIGHT
var attack_t := 0.0
var attack_cd := 0.0
var dodge_t := 0.0
var dodge_cd := 0.0
var dodge_dir := Vector2.RIGHT
var inv_t := 0.0
var hurt_flash := 0.0
var slow_t := 0.0
var walk_t := 0.0
var potions := 1
var coins := 20
var charm_dodge := false
var red_thread := false
var frozen := false
var god := false
var light: PointLight2D


func _ready() -> void:
	add_to_group("player")
	collision_layer = 2
	collision_mask = 1
	var cs := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = 12.0
	cs.shape = c
	add_child(cs)
	light = G.make_light(300.0, Color(1.0, 0.82, 0.5), 0.95)
	add_child(light)


func reset_stats() -> void:
	max_hp = 100.0
	hp = max_hp
	dmg = 12.0
	potions = 1
	coins = 20
	charm_dodge = false
	red_thread = false
	frozen = false


func _physics_process(delta: float) -> void:
	attack_cd = maxf(0.0, attack_cd - delta)
	dodge_cd = maxf(0.0, dodge_cd - delta)
	inv_t = maxf(0.0, inv_t - delta)
	attack_t = maxf(0.0, attack_t - delta)
	hurt_flash = maxf(0.0, hurt_flash - delta)
	slow_t = maxf(0.0, slow_t - delta)
	if frozen or hp <= 0.0:
		velocity = velocity.move_toward(Vector2.ZERO, 1800.0 * delta)
		move_and_slide()
		queue_redraw()
		return
	var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var md := get_global_mouse_position() - global_position
	if md.length() > 8.0:
		facing = md.normalized()
	if dodge_t > 0.0:
		dodge_t -= delta
		velocity = dodge_dir * (600.0 if charm_dodge else 540.0)
	else:
		var sp := speed * (0.55 if slow_t > 0.0 else 1.0)
		velocity = velocity.move_toward(dir * sp, 2800.0 * delta)
		if Input.is_action_just_pressed("dodge") and dodge_cd <= 0.0:
			dodge_dir = dir if dir != Vector2.ZERO else facing
			dodge_t = 0.22
			inv_t = 0.32
			dodge_cd = 0.75 * (0.9 if charm_dodge else 1.0)
			G.fx_ring(get_parent(), global_position, Color(1, 1, 1, 0.5), 32)
		if Input.is_action_pressed("attack") and attack_cd <= 0.0:
			swing()
		if Input.is_action_just_pressed("potion"):
			drink()
	move_and_slide()
	if dir != Vector2.ZERO:
		walk_t += delta * 9.0
	queue_redraw()


func swing() -> void:
	attack_t = 0.18
	attack_cd = 0.36
	var reach := 82.0
	for e in get_tree().get_nodes_in_group("enemies"):
		var to: Vector2 = e.global_position - global_position
		if to.length() < reach + e.radius and absf(facing.angle_to(to)) < deg_to_rad(72.0):
			e.hurt(dmg, to.normalized())


func drink() -> void:
	if potions > 0 and hp < max_hp:
		potions -= 1
		hp = minf(max_hp, hp + 45.0)
		G.fx_text(get_parent(), global_position, "+45", Color("7bd36a"))
		G.fx_ring(get_parent(), global_position, Color("7bd36a"), 40)


func hurt(amount: float, dir: Vector2) -> void:
	if inv_t > 0.0 or hp <= 0.0 or god:
		return
	hp -= amount
	inv_t = 0.55
	hurt_flash = 0.25
	velocity = dir * 320.0
	G.fx_text(get_parent(), global_position, str(int(amount)), Color("ff6a5a"))
	if hp <= 0.0:
		hp = 0.0
		died.emit()


func _draw_fallback() -> void:
	var blink := inv_t > 0.0 and int(inv_t * 30.0) % 2 == 0
	var a := 0.45 if blink else 1.0
	draw_set_transform(Vector2(0, 2), 0, Vector2(1, 0.45))
	draw_circle(Vector2.ZERO, 15, Color(0, 0, 0, 0.4))
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	var bob := sin(walk_t) * 1.5
	draw_circle(Vector2(0, -14 + bob), 12, Color("34425c", a))
	draw_circle(Vector2(0, -16 + bob), 9, Color("46587a", a))
	draw_circle(Vector2(0, -31 + bob), 9, Color("2a3348", a))
	draw_circle(Vector2(facing.x * 2.5, -30 + bob + facing.y * 2.0), 5.2, Color("d9b48f", a))
	var hand := Vector2(0, -16 + bob) + facing * 13.0
	var reach := 30.0 + (18.0 if attack_t > 0.0 else 0.0)
	draw_line(hand, hand + facing * reach, Color("cfd4dc", a), 3.0)
	draw_line(hand - facing * 4.0, hand + facing * 2.0, Color("6b4a2e", a), 4.0)
	if attack_t > 0.0:
		var k := 1.0 - attack_t / 0.18
		var ang := facing.angle()
		draw_arc(Vector2(0, -16), 62, ang - 1.2 + 2.4 * k - 0.9, ang - 1.2 + 2.4 * k, 10, Color(1, 0.95, 0.8, 0.85), 4.0)
	var lp := Vector2(-11, -12 + bob)
	draw_circle(lp, 7, Color(1, 0.8, 0.4, 0.25))
	draw_circle(lp, 3.5, G.AMBER)
	if hurt_flash > 0.0:
		draw_circle(Vector2(0, -18), 18, Color(1, 0.2, 0.2, hurt_flash * 2.0))


func _draw() -> void:
	var path := "res://assets/sprites/wanderer_idle.svg"
	if attack_t > 0.0:
		path = "res://assets/sprites/wanderer_attack.svg"
	elif velocity.length() > 40.0 and int(walk_t / 1.6) % 2 == 1:
		path = "res://assets/sprites/wanderer_walk.svg"
	var tex := G.tex(path)
	if tex == null:
		_draw_fallback()
		return
	var blink := inv_t > 0.0 and int(inv_t * 30.0) % 2 == 0
	var flip := attack_t > 0.0 and facing.x < 0.0
	draw_set_transform(Vector2.ZERO, 0, Vector2(-1.0 if flip else 1.0, 1.0))
	draw_texture_rect(tex, Rect2(-40, -69, 80, 80), false, Color(1, 1, 1, 0.45 if blink else 1.0))
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	if attack_t > 0.0:
		var k := 1.0 - attack_t / 0.18
		var ang := facing.angle()
		draw_arc(Vector2(0, -16), 62, ang - 1.2 + 2.4 * k - 0.9, ang - 1.2 + 2.4 * k, 10, Color(1, 0.95, 0.8, 0.85), 4.0)
	if hurt_flash > 0.0:
		draw_circle(Vector2(0, -18), 18, Color(1, 0.2, 0.2, hurt_flash * 2.0))
