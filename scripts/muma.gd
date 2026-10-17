class_name Muma
extends Enemy
## Muma Pădurii, the Forest Mother. Bark-skinned hag who steals children to
## keep the wood young. Phase 2+: her bark is proof against steel unless salt
## burns it away. She walks between hollow trees and calls up roots.

signal phase_changed(p)

var phase := 1
var bstate := "intro"
var bt := 0.0
var root_t := 4.0
var hop_t := 10.0
var wisp_t := 8.0
var vuln_t := 0.0
var alpha := 1.0
var hop_to := Vector2.ZERO
var brew_t := 3.0
var weave_t := 7.0
var crow_t := 9.0
var illusion := false
var arena


func setup(_k: String) -> void:
	kind = "muma"
	hp = 560.0
	max_hp = 560.0
	speed = 88.0
	dmg = 15.0
	radius = 40.0
	coin = 80
	aggro = 9999.0


func hud_name() -> String:
	return "MUMA PĂDURII"


func hud_hint() -> String:
	if phase >= 2 and not vulnerable():
		return "Her bark turns steel. Catch her in a ring of salt (R)."
	return ""


func undead() -> bool:
	return true


func vulnerable() -> bool:
	return phase == 1 or vuln_t > 0.0


func salt_hit(ring: Node2D, _delta: float) -> void:
	if illusion:
		pop(false)
		return
	if bstate == "intro" or bstate == "hide" or ring.has_meta("spent"):
		return
	if arena != null:
		arena.dispel_illusions()
	if vuln_t <= 0.0:
		ring.set_meta("spent", true)
		vuln_t = 4.5
		bstate = "stunned"
		bt = 0.0
		G.fx_ring(get_parent(), global_position, Color(1, 1, 1, 0.9), 140, 0.6)
		G.sfx("cackle", -2.0, 0.7)
		if arena != null:
			arena.main.toast("The salt burns her bark! Strike now!")


## An illusion struck or salted bursts into crows.
func pop(crows := true) -> void:
	G.sfx("cackle", -4.0, 1.4)
	G.fx_ring(get_parent(), global_position, Color(0.3, 0.3, 0.3, 0.9), 80, 0.5)
	if crows and arena != null:
		for i in 2:
			var e: Enemy = arena.spawn_enemy("bat", global_position + Vector2(randf_range(-30, 30), -40))
			e.state = "chase"
		arena.main.toast("Only an illusion! It bursts into crows.")
	queue_free()


func hurt(amount: float, dir: Vector2) -> void:
	if bstate == "intro" or bstate == "hide":
		return
	if illusion:
		pop()
		return
	if not vulnerable():
		flash = 0.05
		G.fx_text(get_parent(), global_position + Vector2(0, -60), "bark", Color("a08a60"))
		G.sfx("hit", -10.0, 0.5)
		return
	hp -= amount
	flash = 0.1
	knock = dir * 70.0
	G.fx_text(get_parent(), global_position + Vector2(randf_range(-20, 20), -50), str(int(amount)), Color("ffe08a"))
	G.sfx("hit", -2.0, 0.7)
	if hp <= 0.0:
		die()
		return
	var r := hp / max_hp
	var np := 1 if r > 0.66 else (2 if r > 0.33 else 3)
	if np != phase:
		phase = np
		vuln_t = 0.0
		bstate = "walk"
		bt = -1.0
		hop_t = 2.0
		phase_changed.emit(phase)
		G.fx_ring(get_parent(), global_position, Color(0.5, 0.9, 0.3, 0.9), 220, 0.8)


func die() -> void:
	if arena != null:
		arena.dispel_illusions()
	died.emit(self)
	G.sfx("boss_roar", 0.0, 1.3)
	G.sfx("cackle", 0.0, 0.6)
	for i in 3:
		G.fx_ring(get_parent(), global_position, Color(0.6, 1.0, 0.5, 0.9), 120 + i * 70, 0.7 + i * 0.2)
	queue_free()


func _physics_process(delta: float) -> void:
	t += delta
	bt += delta
	flash = maxf(0.0, flash - delta)
	atk_cd = maxf(0.0, atk_cd - delta)
	vuln_t = maxf(0.0, vuln_t - delta)
	if player == null or not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")
	if player == null or player.hp <= 0.0:
		velocity = Vector2.ZERO
		queue_redraw()
		return
	var to: Vector2 = player.global_position - global_position
	var d := to.length()
	var sm := 1.0 + 0.2 * (phase - 1)
	match bstate:
		"intro":
			velocity = Vector2.ZERO
			face = to.normalized()
			if bt > 2.8:
				bstate = "walk"
				bt = 0.0
		"walk":
			face = to.normalized()
			velocity = face * speed * sm + knock
			if d < 130.0 and atk_cd <= 0.0:
				bstate = "sweep_tel"
				bt = 0.0
		"sweep_tel":
			velocity = knock
			if bt > 0.55 / sm:
				bstate = "sweep"
				bt = 0.0
				if d < 150.0 and absf(face.angle_to(to)) < deg_to_rad(65.0):
					player.hurt(dmg * (0.6 if illusion else 1.2), face)
				G.sfx("swing", 0.0, 0.5)
		"sweep":
			velocity = knock
			if bt > 0.35:
				bstate = "walk"
				bt = 0.0
				atk_cd = 1.3
		"cast":
			velocity = knock
			if bt > 0.7:
				bstate = "walk"
				bt = 0.0
				if arena != null and not illusion:
					arena.cast_roots(self)
		"hide":
			velocity = Vector2.ZERO
			alpha = maxf(0.0, alpha - delta * 2.0)
			if bt > 0.6 and global_position != hop_to:
				global_position = hop_to
				if not illusion and arena != null:
					arena.shuffle_sisters(self)
			if bt > 1.2:
				bstate = "walk"
				bt = 0.0
				G.sfx("cackle", -4.0, randf_range(0.9, 1.15))
		"stunned":
			velocity = knock
			if bt > 1.6:
				bstate = "walk"
				bt = 0.0
	if bstate != "hide":
		alpha = minf(1.0, alpha + delta * 2.0)
	if illusion:
		if bstate == "walk" and bt > 0.0:
			brew_t -= delta
			if brew_t <= 0.0:
				brew_t = randf_range(4.0, 6.0)
				throw_brew(1)
		knock = knock.move_toward(Vector2.ZERO, 700.0 * delta)
		modulate.a = alpha * (0.55 if fmod(t + position.x * 0.01, 3.2) < 0.15 else 0.92)
		move_and_slide()
		queue_redraw()
		return
	if bstate == "walk" and bt > 0.0:
		brew_t -= delta
		if brew_t <= 0.0:
			brew_t = 5.0 - phase * 0.7
			throw_brew(1 + phase)
		weave_t -= delta
		if weave_t <= 0.0 and arena != null:
			weave_t = 9.0 - phase
			arena.weave(self)
		root_t -= delta
		if root_t <= 0.0:
			root_t = 6.5 - phase * 1.2
			bstate = "cast"
			bt = 0.0
		if phase >= 2:
			hop_t -= delta
			if hop_t <= 0.0 and arena != null and vuln_t <= 0.0:
				hop_t = 11.0 - phase
				hop_to = arena.hop_spot(global_position)
				bstate = "hide"
				bt = 0.0
		if phase >= 3:
			wisp_t -= delta
			if wisp_t <= 0.0 and arena != null:
				wisp_t = 11.0
				arena.call_wisps(self)
			crow_t -= delta
			if crow_t <= 0.0 and arena != null:
				crow_t = 10.0
				arena.call_crows(self)
	knock = knock.move_toward(Vector2.ZERO, 700.0 * delta)
	modulate.a = alpha * (1.0 if vulnerable() else 0.92)
	move_and_slide()
	queue_redraw()


func throw_brew(n: int) -> void:
	G.sfx("hiss", -8.0, 1.6)
	for i in n:
		var fp := FirePatch.new()
		fp.brew = true
		fp.position = player.global_position + (Vector2.ZERO if i == 0 else Vector2.from_angle(randf() * TAU) * randf_range(50, 130))
		get_parent().add_child(fp)


func _draw() -> void:
	var pose := "idle"
	if bstate == "cast":
		pose = "cast"
	elif bstate == "sweep" or bstate == "sweep_tel":
		pose = "sweep"
	var tex := G.tex("res://assets/sprites/muma_%s.svg" % pose)
	draw_set_transform(Vector2(0, 4), 0, Vector2(1, 0.45))
	draw_circle(Vector2.ZERO, 50, Color(0, 0, 0, 0.4))
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	if bstate == "sweep_tel":
		var a := face.angle()
		draw_arc(Vector2(0, -20), 140, a - deg_to_rad(65), a + deg_to_rad(65), 24, Color(1, 0.3, 0.1, 0.35 + 0.3 * sin(t * 30.0)), 10.0)
	var tint := Color.WHITE
	if flash > 0.0:
		tint = Color(2, 2, 2)
	elif phase >= 2 and not vulnerable():
		tint = Color(0.75, 0.72, 0.68)
	elif vuln_t > 0.0:
		tint = Color(1.3, 1.15, 1.1)
	var sway := sin(t * 1.6) * 0.03 if bstate == "walk" else 0.0
	var flip := face.x < 0.0
	draw_set_transform(Vector2.ZERO, sway, Vector2(-1.0 if flip else 1.0, 1.0))
	if tex != null:
		draw_texture_rect(tex, Rect2(-144, -190, 288, 216), false, tint)
	else:
		draw_rect(Rect2(-30, -140, 60, 140), Color("4a3a28") * tint)
		draw_circle(Vector2(0, -150), 28, Color("4a6a30") * tint)
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	if bstate == "stunned":
		for i in 5:
			var p := Vector2.from_angle(t * 4.0 + i * TAU / 5.0) * 34.0 + Vector2(0, -170)
			draw_circle(p, 3.0, Color(1, 1, 1, 0.9))
