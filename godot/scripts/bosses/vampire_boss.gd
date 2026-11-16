## The Vampire of Biertan, and what he turns out to be. As the lord he walks, bites, calls thralls and lashes
## the old bell rope in a line; at three fifths of his strength he breaks into wolves and bats. As the strigoi
## mort steel skids off him until the church bell pins him, and only Muma's oak stake finishes it.
class_name VampireBoss
extends Enemy

var bstate := "intro"
var bt := 0.0
var lash_t := 6.0
var call_t := 12.0
var stun_t2 := 0.0
var mort := false
var lash_dir := Vector2.ZERO
var lash_hit := false

func hud_name() -> String: return "THE STRIGOI MORT" if mort else "THE STRIGOI OF BIERTAN"
func hud_hint() -> String:
	if mort:
		if stun_t2 > 0.0: return "The bell holds him! Strike now!"
		return "He's down. The oak stake!" if hp <= 1.0 else "Steel skids off him. Ring the bell!"
	return "The bell rope! Get out of its line!" if bstate == "windup" else ""
func undead() -> bool: return true
func salt_hit(_ring_pos: Vector2, _dt: float) -> void: pass

func setup(k: String) -> void:
	kind = k
	mort = k == "strigoi_mort"
	hp = 360.0 if mort else 520.0; max_hp = hp
	speed = 78.0 if mort else 118.0; dmg = 22.0 if mort else 14.0; radius = 30.0 if mort else 20.0; coin = 0; aggro = 99999.0
	heavy = true
	_make_figure()
	set_body_radius(radius * 0.9)
	G.boss = self

func step(dt: float, to: Vector2, d: float, mult: float) -> bool:
	bt += dt
	var dir := to.normalized()
	if mort:
		if stun_t2 > 0.0:
			stun_t2 -= dt; vel = Vector2.ZERO
			if randf() < dt * 2.0: Fx.text(pos, "*", Fx.AMBER, 90.0)
			return true
		if hp <= 1.0:   # down, waiting for the stake
			vel = Vector2.ZERO
			return true
		face = dir
		vel = dir * speed * mult + knock + separation()
		if d < radius + 40.0 and atk_cd <= 0.0:
			player.hurt(dmg * mult, dir)
			atk_cd = 1.5; strike_t = 0.45; knock = -dir * 120.0
		knock = knock.move_toward(Vector2.ZERO, 900.0 * dt)
		return true
	match bstate:
		"intro":
			vel = Vector2.ZERO; face = dir
			if bt > 1.4: bstate = "walk"; bt = 0.0
		"walk":
			face = dir
			vel = dir * speed * mult + knock + separation()
			if d < radius + 36.0 and atk_cd <= 0.0:
				player.hurt(dmg * mult, dir)
				atk_cd = 1.1; strike_t = 0.4
				Audio.sfx_at("slash", pos, -6.0, 0.8)
			lash_t -= dt; call_t -= dt
			if lash_t <= 0.0 and d < 520.0:
				bstate = "windup"; bt = 0.0; lash_dir = dir; lash_t = 6.5
			if call_t <= 0.0:
				call_t = 13.0
				G.level.call_thralls(pos)
				Fx.text(pos, "COME.", Color(0.9, 0.4, 0.4), 80.0)
		"windup":   # he takes the old bell rope off his shoulder and swings it back
			vel = Vector2.ZERO; face = lash_dir
			if bt < 0.8 and randf() < dt * 10.0: Fx.ring(pos + lash_dir * randf_range(60.0, 420.0), Color(0.8, 0.3, 0.25, 0.6), 22.0, 0.2)
			if bt > 0.85:
				bstate = "lash"; bt = 0.0; lash_hit = false; strike_t = 0.4
				Audio.sfx_at("swing", pos, -2.0, 0.5)
		"lash":
			vel = Vector2.ZERO
			for i in range(1, 8):
				if randf() < 0.4: Fx.ring(pos + lash_dir * i * 60.0, Color(0.85, 0.75, 0.55, 0.8), 26.0, 0.2)
			if not lash_hit:
				lash_hit = true
				var along := to.dot(lash_dir); var side := absf(lash_dir.cross(to))
				if along > 0.0 and along < 440.0 and side < 55.0 and player.inv_t <= 0.0: player.hurt(18.0 * mult, lash_dir)
			if bt > 0.5: bstate = "walk"; bt = 0.0
	knock = knock.move_toward(Vector2.ZERO, 900.0 * dt)
	return true

func hurt(amount: float, dir: Vector2) -> void:
	if hp <= 0.0: return
	if mort and stun_t2 <= 0.0:
		Fx.text(pos, "(your blade skids off grave-hard skin)", Color(0.8, 0.8, 0.85), 80.0)
		Audio.sfx("blip", -8.0, 0.5)
		return
	if not mort and bstate == "intro": return
	hp -= amount; flash = 0.12; knock = dir * (30.0 if mort else 80.0)
	Audio.sfx("hit", -6.0, 0.5 if mort else 0.8)
	Fx.text(pos, str(roundi(amount)), Color("ffe08a"))
	if not mort and hp <= max_hp * 0.6:
		hp = max_hp * 0.6
		G.level.shatter(self)
	elif mort and hp <= 1.0:
		hp = 1.0; stun_t2 = 0.0
		G.level.mort_down(self)
