class_name BalaurHead
extends Enemy
## One head of the Balaur, each one carrying a power from the tale of
## Harap-Alb: frost like Gerilă, fire like the Red Emperor's red-hot copper
## house, and an endless thirst like Setilă, who drinks lakes dry.
## Cut it down and it falls to a stump that regrows unless seared with fire.

var body
var anchor := Vector2.ZERO
var rest := Vector2.ZERO
var element := "fire"
var hstate := "sway"
var ht := 0.0
var strike_from := Vector2.ZERO
var strike_to := Vector2.ZERO
var cd := 2.0
var regrow_t := 0.0
var sealed := false
var main
const REGROW := 7.0


func setup(_k: String) -> void:
	kind = "balaur_head"
	hp = 170.0
	max_hp = 170.0
	radius = 26.0
	dmg = 18.0
	coin = 0
	aggro = 9999.0


func _ready() -> void:
	super._ready()
	collision_layer = 0
	collision_mask = 0
	cd = randf_range(1.5, 3.5)


func undead() -> bool:
	return false


func tint_col() -> Color:
	match element:
		"frost":
			return Color(0.75, 0.95, 1.25)
		"fire":
			return Color(1.35, 0.9, 0.7)
	return Color(0.8, 1.0, 1.1)


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
	regrow_t = REGROW
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
			var want: Vector2 = rest + (player.global_position - rest).limit_length(90.0) + Vector2(sin(t * 1.3 + anchor.x) * 26.0, cos(t * 1.1) * 14.0)
			global_position = global_position.lerp(want, minf(1.0, delta * 3.0))
			face = (player.global_position - global_position).normalized()
			if not body.intro and not body.gazing():
				cd -= delta * rage
			if cd <= 0.0 and player.hp > 0.0:
				ht = 0.0
				strike_from = global_position
				if element == "thirst":
					hstate = "drink"
					G.sfx("hiss", -2.0, 0.6)
				elif element == "fire" and randf() < 0.45:
					hstate = "skulls"
					G.sfx("laugh", -6.0, 1.6)
				else:
					hstate = "tel"
					strike_to = anchor + (player.global_position - anchor).limit_length(560.0)
					G.sfx("hiss", -4.0, randf_range(0.9, 1.2))
		"tel":
			face = (strike_to - global_position).normalized()
			global_position = strike_from - face * 30.0 * minf(1.0, ht / 0.4)
			if ht > 0.75 / rage:
				hstate = "breath"
				ht = 0.0
				G.sfx("fire", -2.0, 0.8 if element == "frost" else 1.0)
		"breath":
			var n := int(ht / 0.09)
			if n < 7 and n >= get_meta("patches", 0):
				set_meta("patches", n + 1)
				var fp := FirePatch.new()
				fp.frost = element == "frost"
				fp.position = global_position.lerp(strike_to, float(n + 1) / 7.0)
				get_parent().add_child(fp)
				if n == 6 and element == "frost" and player.global_position.distance_to(strike_to) < 60.0 and player.inv_t <= 0.0:
					player.root_t = 1.0
					G.fx_text(get_parent(), player.global_position + Vector2(0, -50), "frozen", Color("cfe8ff"))
			if ht > 0.7:
				set_meta("patches", 0)
				hstate = "recoil"
				ht = 0.0
		"drink":
			# dip into the lake and drink; the current drags the hunter in
			global_position = global_position.lerp(anchor + Vector2(0, -20), minf(1.0, delta * 3.0))
			face = Vector2.UP
			var pull: Vector2 = (anchor - player.global_position).normalized()
			player.pull += pull * 170.0
			if ht > 1.8:
				hstate = "spit"
				ht = 0.0
				global_position = rest
				var w := WaterWave.new()
				w.position = rest
				get_parent().add_child(w)
				G.sfx("dodge", 2.0, 0.5)
				G.sfx("hiss", 0.0, 0.5)
		"skulls":
			face = (player.global_position - global_position).normalized()
			if ht > 0.6:
				for i in 2 + int(rage):
					var s: Enemy = body.arena.spawn_enemy("skull", global_position + Vector2.from_angle(randf() * TAU) * 30.0)
					s.face = Vector2.from_angle(face.angle() + (i - 1) * 0.6)
				hstate = "recoil"
				ht = 0.0
		"spit":
			if ht > 0.6:
				hstate = "recoil"
				ht = 0.0
		"recoil":
			global_position = global_position.lerp(rest, minf(1.0, delta * 4.0))
			if ht > 0.7:
				hstate = "sway"
				cd = randf_range(2.0, 3.4)
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
			var k := regrow_t / REGROW
			draw_arc(Vector2(0, -36), 14, -PI / 2.0, -PI / 2.0 + TAU * k, 24, G.AMBER, 3.0)
		return
	if hstate == "tel":
		var c := Color(0.6, 0.85, 1.0) if element == "frost" else Color(1, 0.5, 0.1)
		c.a = 0.3 + 0.3 * sin(t * 30.0)
		draw_line(Vector2.ZERO, strike_to - global_position, c, 30.0)
	if hstate == "drink":
		draw_circle(Vector2.ZERO, 30 + 10 * sin(t * 10.0), Color(0.4, 0.6, 0.9, 0.3))
	var open := hstate in ["tel", "breath", "drink", "spit"]
	var tex := G.tex("res://assets/sprites/balaur_head%s.svg" % ("_open" if open else ""))
	var ang := face.angle()
	var flip := absf(ang) > PI / 2.0
	draw_set_transform(Vector2.ZERO, ang, Vector2(1, -1 if flip else 1))
	var tint := Color(2, 2, 2) if flash > 0.0 else tint_col()
	if tex != null:
		draw_texture_rect(tex, Rect2(-40, -42, 148, 80), false, tint)
	else:
		draw_circle(Vector2(20, 0), 24, Color("2e4a30"))
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	if hp < max_hp:
		draw_rect(Rect2(-24, -46, 48, 5), Color(0, 0, 0, 0.7))
		draw_rect(Rect2(-24, -46, 48 * hp / max_hp, 5), Color("c0392b"))
