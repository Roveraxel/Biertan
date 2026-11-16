## Uriașul, the giant of the hill fortress above Saschiz. He only wanted to play, and something black on his
## back will not let him stop. Phase 1: he swats and throws boulders. Phase 2: he scoops the hunter into his
## apron (hit him until he lets go). Phase 3: only blows to his back count, and he turns slowly.
class_name Giant
extends Enemy

signal child_freed(n: int)
signal sat_down

var phase := 1
var gstate := "idle"
var gt := 0.0
var throw_t := 2.5
var scoop_t := 4.0
var hold_hits := 0.0
var woken := false
var done := false
var slump := 0.0   # 0..0.2: how far he has sunk down to sit, after the fight
var arena := Vector2.ZERO   # where he woke: he never leaves the fortress yard
const LEASH := Vector2(1050, 720)

func hud_name() -> String: return "URIAȘUL"
func hud_hint() -> String:
	if phase == 2 and gstate == "hold": return "Hit him until he lets go!"
	return "The rot is on his back. Get behind him." if phase == 3 else ""

func setup(_k: String) -> void:
	kind = "giant"
	hp = 300.0; max_hp = 300.0
	speed = 70.0; dmg = 16.0; radius = 36.0; coin = 40; aggro = 700.0
	heavy = true
	_make_figure()
	set_body_radius(radius * 0.8)

func step(dt: float, to: Vector2, d: float, mult: float) -> bool:
	if done:
		vel = Vector2.ZERO
		return true
	gt += dt
	if not woken:
		vel = Vector2.ZERO
		if d < aggro:
			woken = true
			Audio.sfx("boss_roar", -4.0, 0.6)
			Hud.banner("URIAȘUL", "The giant of the hill fortress. He does not want to stop playing.")
		return true
	# phase 3: he turns slowly, so the hunter can get round to his back
	var want := to.normalized()
	var turn := (1.1 if phase == 3 else 6.0) * dt
	face = face.rotated(clampf(face.angle_to(want), -turn, turn))
	if face.length_squared() < 0.01: face = want
	if arena == Vector2.ZERO: arena = pos
	match gstate:
		"idle", "walk":
			vel = (face * speed * mult if d > 140.0 else Vector2.ZERO) + knock + separation()
			# the yard is his: past its edge he stops and throws instead of following down the road
			var rel := (pos + vel * dt - arena) / LEASH
			if rel.length() > 1.0: vel = (arena - pos).normalized() * speed * 0.5
			throw_t -= dt; scoop_t -= dt
			if phase == 2 and scoop_t <= 0.0 and d < 170.0:
				gstate = "reach"; gt = 0.0
			elif d < 130.0 and atk_cd <= 0.0:
				gstate = "swat"; gt = 0.0
			elif throw_t <= 0.0 and d > 220.0:
				gstate = "throw"; gt = 0.0
				Boulder.launch(pos + face * 40.0, player.pos, 1.05, 15.0)
				throw_t = 2.6 if phase == 1 else 3.6
		"throw":   # he stands and throws: no step forward, so it never reads as a rush at the hunter
			vel = Vector2.ZERO
			if gt > 0.6: gstate = "walk"
		"swat":
			vel = Vector2.ZERO
			if gt > 0.65:
				if d < 150.0: player.hurt(dmg * mult, want)
				atk_cd = 1.8; gstate = "walk"
		"reach":
			vel = Vector2.ZERO
			if gt > 0.7:
				if d < 190.0:
					gstate = "hold"; gt = 0.0; hold_hits = 0.0
					player.root_t = 3.5; player.grabbed = true
					_hold_player()
					Audio.sfx("laugh", -6.0, 0.5)
					Hud.toast("He scoops you into his apron!")
				else:
					gstate = "walk"; scoop_t = 3.0
		"hold":
			vel = Vector2.ZERO
			_hold_player()
			if hold_hits >= 4.0: _release(true)
			elif gt > 3.4:
				player.hurt(12.0, -face)
				_release(false)
		"sit":
			vel = Vector2.ZERO
	knock = knock.move_toward(Vector2.ZERO, 600.0 * dt)
	return true

## In his apron, in front of him; never inside a wall or past the fortress ring.
func _hold_player() -> void:
	var at: Vector2 = pos + face * 60.0
	if not G.level.is_free(at, 14.0, null): at = pos + face * 20.0
	if G.level.is_free(at, 14.0, null): player.pos = at

func _release(broke_free: bool) -> void:
	player.root_t = 0.0; player.grabbed = false
	# dropped behind him, as far as the ground allows: never through the fortress wall
	for back in [160.0, 120.0, 80.0, 50.0]:
		var at: Vector2 = pos - face * back
		var inside: bool = G.level.inside_ring(at) if G.level.has_method("inside_ring") else true
		if inside and G.level.is_free(at, 14.0, null):
			player.pos = at
			break
	gstate = "walk"; gt = 0.0; scoop_t = 6.0; atk_cd = 1.2
	Hud.toast("You wrench yourself free!" if broke_free else "He drops you, hard.")

func hurt(amount: float, _dir: Vector2) -> void:
	if done or not woken:
		woken = true
		return
	if gstate == "hold":
		hold_hits += 1.0
		Fx.text(pos, "!", Fx.AMBER, 90.0)
		amount *= 0.5
	elif phase == 3 and is_instance_valid(player) and face.dot((player.pos - pos).normalized()) > -0.1:
		amount *= 0.1
		Audio.sfx_at("hit", pos, -8.0, 0.5)
		Fx.text(pos, "THUD", Color(0.8, 0.8, 0.85), 70.0)
	hp -= amount; flash = 0.12
	Audio.sfx("hit", -6.0, 0.7)
	Fx.text(pos, str(roundi(amount)), Color("ffe08a"))
	if phase == 1 and hp <= 200.0:
		phase = 2; scoop_t = 1.5
		child_freed.emit(1)
	elif phase == 2 and hp <= 100.0:
		if gstate == "hold": _release(true)
		phase = 3
		child_freed.emit(2)
	if hp <= 0.0: die()

func die() -> void:
	if done: return
	done = true; hp = 0.0; gstate = "sit"; state = "sit"
	player.root_t = 0.0; player.grabbed = false
	vel = Vector2.ZERO
	Audio.sfx("bell", -10.0, 0.5)
	child_freed.emit(3)
	sat_down.emit()
	died.emit(self)
	if G.boss == self: G.boss = null

func anim_state() -> String:
	if done or gstate == "throw": return "idle"
	if gstate in ["swat", "reach", "hold"]: return "attack"
	return "walk" if vel.length() > 5.0 else "idle"
