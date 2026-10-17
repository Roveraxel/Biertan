class_name Vlad
extends Enemy
## Strigoi Vlad, the blood lord of Biertan. Inspired by blood-rite bosses:
## a long blood glaive with sweeping three-hit combos and a lunging thrust,
## spilled blood that erupts into bloodflame, and the Nihil rite: three cries
## that wrench blood from the hunter unless they stand in salt. From phase 2
## he is mist; only the toll of the great bell drags him back into flesh.

signal phase_changed(p)

const REACH := 175.0

var phase := 1
var bstate := "intro"
var bt := 0.0
var pool_t := 5.0
var dash_t := 7.0
var bolt_t := 9.0
var blink_t := 12.0
var bat_t := 10.0
var rain_t := 6.0
var vuln_t := 0.0
var combo := 0
var slowed := 0.0
var nihil := 0
var dash_dir := Vector2.RIGHT
var arena


func setup(_k: String) -> void:
	kind = "vlad"
	hp = 900.0
	max_hp = 900.0
	speed = 165.0
	dmg = 22.0
	radius = 26.0
	coin = 0
	aggro = 9999.0


func hud_name() -> String:
	return "STRIGOI VLAD, LORD OF BLOOD"


func hud_hint() -> String:
	if bstate == "rite":
		return "NIHIL! Stand inside a ring of salt!"
	if phase >= 2 and not vulnerable():
		return "He is mist. Ring the great bell (%s)!" % ("USE" if G.touch_mode else "E")
	if phase >= 3 and not (player != null and player.garlic):
		return "His presence drinks your blood. Keep away, or wear garlic."
	return ""


func undead() -> bool:
	return true


func vulnerable() -> bool:
	if bstate == "rite":
		return false
	return phase == 1 or vuln_t > 0.0


func salt_hit(_ring: Node2D, delta: float) -> void:
	slowed = 0.4
	if vulnerable():
		hp -= 6.0 * delta


func bell_toll() -> void:
	if bstate == "rite":
		return
	vuln_t = 7.0
	bstate = "stunned"
	bt = 0.0
	G.fx_ring(get_parent(), global_position, Color(1.0, 0.9, 0.6, 0.9), 200, 0.7)


func hurt(amount: float, dir: Vector2) -> void:
	if bstate in ["intro", "blink", "rite"]:
		return
	if not vulnerable():
		flash = 0.05
		G.fx_text(get_parent(), global_position + Vector2(0, -70), "mist", Color("c8a0a8"))
		return
	hp -= amount
	flash = 0.1
	knock = dir * 60.0
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
		phase_changed.emit(phase)
		G.fx_ring(get_parent(), global_position, Color(0.8, 0.1, 0.1, 0.9), 240, 0.9)
		if phase == 2:
			start_rite()
		else:
			bstate = "stalk"
			bt = -0.6
			G.sfx("laugh", 0.0, 0.9)


func start_rite() -> void:
	bstate = "rite"
	bt = 0.0
	nihil = 0
	G.sfx("laugh", 0.0, 0.75)


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
	var sm := (1.0 + 0.15 * (phase - 1)) * (0.45 if slowed > 0.0 else 1.0)
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
			var want := face * speed * sm
			if d < REACH * 0.7:
				want = -face * speed * 0.3
			velocity = want + knock
			if d < REACH + 20.0 and atk_cd <= 0.0:
				bstate = "tel"
				bt = 0.0
				combo = 3
		"tel":
			velocity = knock
			if combo == 3 or bt < 0.15:
				face = to.normalized()
			if bt > (0.5 if combo == 3 else 0.32) / sm:
				bstate = "sweep"
				bt = 0.0
				G.sfx("swing", -1.0, 0.6)
				if combo == 1:
					if Geometry2D.get_closest_point_to_segment(player.global_position, global_position, global_position + face * (REACH + 90.0)).distance_to(player.global_position) < 30.0:
						player.hurt(dmg * 1.3, face)
				elif d < REACH + 10.0 and absf(face.angle_to(to)) < deg_to_rad(65.0):
					player.hurt(dmg, face)
		"sweep":
			velocity = face * (320.0 if combo == 1 else 140.0)
			if bt > 0.2:
				combo -= 1
				if combo > 0:
					bstate = "tel"
					bt = 0.0
				else:
					bstate = "stalk"
					bt = 0.0
					atk_cd = 1.1 - 0.15 * phase
		"dash_tel":
			velocity = knock
			if bt < 0.35:
				dash_dir = to.normalized()
				face = dash_dir
			if bt > 0.6 / sm:
				bstate = "dash"
				bt = 0.0
				hit_done = false
				G.sfx("blink", -2.0, 0.6)
		"dash":
			velocity = dash_dir * 760.0
			if not hit_done and d < 70.0:
				hit_done = true
				player.hurt(dmg * 1.1, dash_dir)
			if bt > 0.4 or is_on_wall():
				bstate = "tel"
				bt = 0.0
				combo = 1
				face = to.normalized()
		"cast":
			velocity = knock
			if bt > 0.5:
				shoot()
				bstate = "stalk"
				bt = 0.0
		"pools":
			velocity = knock
			if bt > 0.5:
				spill(4 + phase, 170.0)
				bstate = "stalk"
				bt = 0.0
		"blink":
			velocity = Vector2.ZERO
			if bt > 0.5:
				if arena != null:
					global_position = (player.global_position - player.facing * 110.0).clamp(Vector2(140, 200), arena.size - Vector2(140, 140))
				bstate = "tel"
				bt = 0.0
				combo = 1
				face = (player.global_position - global_position).normalized()
				G.sfx("blink", -2.0, 0.8)
		"rite":
			velocity = Vector2.ZERO
			if bt > 1.4:
				bt = 0.0
				nihil += 1
				nihil_cry()
				if nihil >= 3:
					bstate = "stalk"
					bt = -0.5
		"stunned":
			velocity = knock
			if bt > 2.0:
				bstate = "stalk"
				bt = 0.0
	if bstate == "stalk" and bt > 0.0:
		pool_t -= delta
		dash_t -= delta
		bolt_t -= delta
		blink_t -= delta
		if pool_t <= 0.0:
			pool_t = 7.0 - phase
			bstate = "pools"
			bt = 0.0
			G.sfx("laugh", -10.0, 1.2)
		elif dash_t <= 0.0 and d > 200.0:
			dash_t = 6.0 - phase
			bstate = "dash_tel"
			bt = 0.0
		elif bolt_t <= 0.0:
			bolt_t = 8.0 - phase
			bstate = "cast"
			bt = 0.0
		elif blink_t <= 0.0 and phase >= 2:
			blink_t = 10.0 - phase
			bstate = "blink"
			bt = 0.0
			G.sfx("blink", -2.0, 1.2)
			G.sfx("bat", -6.0)
		if phase >= 3:
			bat_t -= delta
			rain_t -= delta
			if bat_t <= 0.0 and arena != null:
				bat_t = 14.0
				arena.call_bats(self)
			if rain_t <= 0.0:
				rain_t = 6.0
				spill(6, 320.0)
	if phase >= 3 and bstate != "intro" and d < 190.0 and not player.garlic and player.inv_t <= 0.0:
		player.hp = maxf(1.0, player.hp - 6.0 * delta)
		hp = minf(max_hp, hp + 6.0 * delta)
	knock = knock.move_toward(Vector2.ZERO, 700.0 * delta)
	modulate.a = 0.0 if bstate == "blink" else (1.0 if vulnerable() or bstate == "rite" else 0.5 + 0.1 * sin(t * 3.0))
	move_and_slide()
	queue_redraw()


func nihil_cry() -> void:
	G.sfx("boss_roar", 0.0, 0.5 + 0.1 * nihil)
	G.fx_ring(get_parent(), global_position, Color(0.9, 0.05, 0.1, 0.9), 900, 0.9)
	if arena != null:
		arena.main.banner("NIHIL!", "")
	var safe := false
	for r in get_tree().get_nodes_in_group("salt_rings"):
		if r.contains(player.global_position):
			safe = true
	if safe:
		G.fx_text(get_parent(), player.global_position + Vector2(0, -40), "warded", Color("e8eeff"))
		return
	var amount: float = player.max_hp * 0.14
	player.inv_t = 0.0
	player.hurt(amount, Vector2.ZERO)
	hp = minf(max_hp, hp + amount)


func spill(n: int, spread: float) -> void:
	for i in n:
		var g := BloodGeyser.new()
		var off := Vector2.ZERO if i == 0 else Vector2.from_angle(randf() * TAU) * randf_range(60.0, spread)
		g.position = player.global_position + off
		g.dmg = 16.0 + 3.0 * phase
		g.delay = 1.2 + i * 0.08
		get_parent().add_child(g)


func shoot() -> void:
	G.sfx("bolt", -2.0)
	var n := 5 + phase * 2
	var base := (player.global_position - global_position).angle()
	for i in n:
		var b := BloodBolt.new()
		var a := base + (i - (n - 1) / 2.0) * 0.16
		b.vel = Vector2.from_angle(a) * (360.0 + 50.0 * phase)
		b.dmg = 12.0
		b.position = global_position + Vector2.from_angle(a) * 30.0
		get_parent().add_child(b)


func _draw() -> void:
	draw_set_transform(Vector2(0, 4), 0, Vector2(1, 0.45))
	draw_circle(Vector2.ZERO, 34, Color(0, 0, 0, 0.45))
	if phase >= 3 and not (player != null and player.garlic):
		draw_arc(Vector2.ZERO, 190.0, 0, TAU, 48, Color(0.7, 0.05, 0.1, 0.25 + 0.1 * sin(t * 4.0)), 4.0)
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	var a := face.angle()
	if bstate == "tel":
		if combo == 1:
			draw_line(Vector2(0, -30), Vector2(0, -30) + face * (REACH + 90.0), Color(1, 0.15, 0.1, 0.35 + 0.3 * sin(t * 30.0)), 22.0)
		else:
			draw_arc(Vector2(0, -30), REACH, a - deg_to_rad(65), a + deg_to_rad(65), 28, Color(1, 0.15, 0.1, 0.35 + 0.3 * sin(t * 30.0)), 12.0)
	if bstate == "dash_tel":
		draw_line(Vector2(0, -20), Vector2(0, -20) + dash_dir * 300.0, Color(1, 0.1, 0.1, 0.3 + 0.3 * sin(t * 25.0)), 30.0)
	if bstate == "rite":
		var k := bt / 1.4
		draw_circle(Vector2(0, -90), 30 + 40 * k, Color(0.8, 0.0, 0.05, 0.25 + 0.3 * k))
	# the blood glaive
	if bstate != "blink":
		var ga := a
		if bstate == "sweep" and combo != 1:
			ga += (1.0 if combo % 2 == 0 else -1.0) * (bt / 0.2 - 0.5) * 2.2
		var base := Vector2(0, -50)
		var tip := base + Vector2.from_angle(ga) * REACH * 0.85
		draw_line(base, tip, Color("2a1a14"), 5.0)
		draw_colored_polygon(PackedVector2Array([tip + Vector2.from_angle(ga + 1.6) * 9.0, tip + Vector2.from_angle(ga) * 44.0, tip + Vector2.from_angle(ga - 1.6) * 9.0]), Color(0.75, 0.05, 0.08))
		draw_line(tip, tip + Vector2.from_angle(ga) * 40.0, Color(1.0, 0.5, 0.4, 0.8), 1.5)
	var pose := "idle"
	if bstate in ["cast", "pools", "rite"]:
		pose = "cast"
	elif bstate in ["tel", "sweep", "dash", "dash_tel"]:
		pose = "claw"
	var tex := G.tex("res://assets/sprites/vlad_%s.svg" % pose)
	var tint := Color(2, 2, 2) if flash > 0.0 else Color.WHITE
	if not vulnerable() and flash <= 0.0 and bstate != "rite":
		tint = Color(0.8, 0.6, 0.7)
	var flip := face.x < 0.0
	var lift := -40.0 * minf(1.0, bt) if bstate == "rite" else 0.0
	draw_set_transform(Vector2(0, lift), 0, Vector2(-1.0 if flip else 1.0, 1.0))
	if tex != null:
		draw_texture_rect(tex, Rect2(-144, -196, 288, 216), false, tint)
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	if not vulnerable() and bstate != "rite":
		for i in 6:
			var p := Vector2(sin(t * 1.3 + i) * 40.0, -40.0 - 20.0 * i + fmod(t * 30.0 + i * 20.0, 30.0))
			draw_circle(p, 14, Color(0.5, 0.1, 0.15, 0.12))
	if bstate == "stunned":
		for i in 5:
			var p := Vector2.from_angle(t * 4.0 + i * TAU / 5.0) * 30.0 + Vector2(0, -180)
			draw_circle(p, 3.0, Color(1, 0.9, 0.6, 0.9))
