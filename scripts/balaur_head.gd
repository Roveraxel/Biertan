class_name BalaurHead
extends Enemy
## One head of the Balaur. Sways on its neck, strikes or breathes fire.
## Cut it down and it falls to a stump that regrows unless seared with fire.

var body
var anchor := Vector2.ZERO
var rest := Vector2.ZERO
var fire_head := false
var hstate := "sway"
var ht := 0.0
var strike_from := Vector2.ZERO
var strike_to := Vector2.ZERO
var cd := 2.0
var regrow_t := 0.0
var sealed := false
var main


func setup(_k: String) -> void:
	kind = "balaur_head"
	hp = 130.0
	max_hp = 130.0
	radius = 26.0
	dmg = 16.0
	coin = 0
	aggro = 9999.0


func _ready() -> void:
	super._ready()
	collision_layer = 0
	collision_mask = 0
	cd = randf_range(1.5, 3.5)


func undead() -> bool:
	return false


func can_interact() -> bool:
	return hstate == "stump" and not sealed


func prompt_text() -> String:
	return "E   Sear the stump with your torch" if main.player.torch else "You have nothing to burn it with"


func interact() -> void:
	if not main.player.torch:
		main.toast("You need fire to seal the neck.")
		return
	sealed = true
	hstate = "sealed"
	remove_from_group("interactable")
	G.sfx("sear", -2.0)
	G.fx_ring(get_parent(), global_position, Color(1.0, 0.6, 0.2, 0.9), 70, 0.6)
	main.toast("The stump hisses black. This head will not grow back.")
	body.head_sealed(self)


func hurt(amount: float, dir: Vector2) -> void:
	if hstate in ["stump", "sealed"] or body.intro:
		return
	hp -= amount
	flash = 0.1
	G.sfx("hit", -3.0, 0.8)
	G.fx_text(get_parent(), global_position + Vector2(0, -30), str(int(amount)), Color("ffe08a"))
	if hp <= 0.0:
		hp = 0.0
		sever()


func sever() -> void:
	hstate = "stump"
	ht = 0.0
	regrow_t = 9.0
	remove_from_group("enemies")
	add_to_group("interactable")
	global_position = anchor + (rest - anchor) * 0.35
	G.sfx("boss_roar", -4.0, 1.4)
	G.fx_ring(get_parent(), global_position, Color(0.5, 0.8, 0.3, 0.9), 90, 0.5)
	main.toast("A head falls! Sear the stump before it grows back.")


func regrow() -> void:
	hstate = "sway"
	hp = max_hp * 0.6
	cd = 1.5
	remove_from_group("interactable")
	add_to_group("enemies")
	G.sfx("hiss", 0.0, 0.8)
	main.toast("The head grows back!")


func _physics_process(delta: float) -> void:
	t += delta
	ht += delta
	flash = maxf(0.0, flash - delta)
	if player == null or not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")
	if player == null:
		return
	var rage: float = body.rage()
	match hstate:
		"sway":
			var want: Vector2 = rest + (player.global_position - rest).limit_length(70.0) + Vector2(sin(t * 1.3 + anchor.x) * 26.0, cos(t * 1.1) * 14.0)
			global_position = global_position.lerp(want, minf(1.0, delta * 3.0))
			face = (player.global_position - global_position).normalized()
			if not body.intro:
				cd -= delta * rage
			if cd <= 0.0 and player.hp > 0.0:
				hstate = "tel"
				ht = 0.0
				strike_from = global_position
				var reach := 520.0 if fire_head else 430.0
				strike_to = anchor + (player.global_position - anchor).limit_length(reach)
				if not fire_head:
					G.sfx("hiss", -4.0, randf_range(0.9, 1.2))
		"tel":
			face = (strike_to - global_position).normalized()
			global_position = strike_from - face * 30.0 * minf(1.0, ht / 0.4)
			if ht > 0.75 / rage:
				hstate = "breath" if fire_head else "strike"
				ht = 0.0
				if fire_head:
					G.sfx("fire", -2.0)
		"strike":
			var k := minf(1.0, ht / 0.22)
			global_position = strike_from.lerp(strike_to, k)
			if player.global_position.distance_to(global_position) < 46.0 and not hit_done:
				hit_done = true
				player.hurt(dmg, face)
			if k >= 1.0:
				hstate = "recoil"
				ht = 0.0
				hit_done = false
		"breath":
			var n := int(ht / 0.1)
			if n < 6 and n >= get_meta("patches", 0):
				set_meta("patches", n + 1)
				var fp := FirePatch.new()
				fp.position = global_position.lerp(strike_to, float(n + 1) / 6.0)
				get_parent().add_child(fp)
			if ht > 0.7:
				set_meta("patches", 0)
				hstate = "recoil"
				ht = 0.0
		"recoil":
			global_position = global_position.lerp(rest, minf(1.0, delta * 4.0))
			if ht > 0.7:
				hstate = "sway"
				cd = randf_range(2.4, 3.8)
		"stump":
			regrow_t -= delta
			if regrow_t <= 0.0:
				regrow()
	queue_redraw()


func _draw() -> void:
	if hstate == "stump" or hstate == "sealed":
		var col := Color("1a1a14") if sealed else Color("3a5a30")
		draw_circle(Vector2.ZERO, 22, col)
		draw_circle(Vector2.ZERO, 14, Color("6a1a1a") if not sealed else Color("0e0e0a"))
		if not sealed:
			var k := regrow_t / 9.0
			draw_arc(Vector2(0, -36), 14, -PI / 2.0, -PI / 2.0 + TAU * k, 24, G.AMBER, 3.0)
		return
	if hstate == "tel":
		if fire_head:
			draw_line(Vector2.ZERO, strike_to - global_position, Color(1, 0.5, 0.1, 0.3 + 0.3 * sin(t * 30.0)), 30.0)
		else:
			draw_line(Vector2.ZERO, strike_to - global_position, Color(1, 0.15, 0.1, 0.3 + 0.3 * sin(t * 30.0)), 10.0)
	var open := hstate in ["tel", "strike", "breath"]
	var tex := G.tex("res://assets/sprites/balaur_head%s.svg" % ("_open" if open else ""))
	var ang := face.angle()
	var flip := absf(ang) > PI / 2.0
	draw_set_transform(Vector2.ZERO, ang, Vector2(1, -1 if flip else 1))
	var tint := Color(2, 2, 2) if flash > 0.0 else (Color(1.3, 1.0, 0.8) if fire_head else Color.WHITE)
	if tex != null:
		draw_texture_rect(tex, Rect2(-40, -42, 148, 80), false, tint)
	else:
		draw_circle(Vector2(20, 0), 24, Color("2e4a30"))
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	if hp < max_hp:
		draw_rect(Rect2(-24, -46, 48, 5), Color(0, 0, 0, 0.7))
		draw_rect(Rect2(-24, -46, 48 * hp / max_hp, 5), Color("c0392b"))
