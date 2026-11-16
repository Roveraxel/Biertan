## The Crypt Warden of Mălâncrav, three hundred years at his post with a gravedigger's shovel. He winds up
## and swings a wide arc in front of him, then has to drag the shovel out of the floor (hit him then). Low on
## strength, he beats the flagstones and calls two more moroi up the stairs.
class_name CryptWarden
extends Enemy

signal beaten
signal call_up

var bstate := "intro"
var bt := 0.0
var swing_dir := Vector2.ZERO
var called := false
var done := false

func hud_name() -> String: return "THE CRYPT WARDEN"
func hud_hint() -> String:
	if bstate == "windup": return "The shovel goes up. Get out of its arc, or behind him!"
	return "He's off balance. Hit him now!" if bstate == "recover" else ""
func undead() -> bool: return true

func setup(_k: String) -> void:
	kind = "warden"
	hp = 360.0; max_hp = 360.0
	speed = 92.0; dmg = 20.0; radius = 26.0; coin = 50; aggro = 99999.0
	heavy = true
	_make_figure()
	set_body_radius(radius * 0.9)
	G.boss = self
	Audio.sfx("shriek", -4.0, 0.6)
	Hud.banner("THE CRYPT WARDEN", "He has kept this crypt for three hundred years, and you rang his bell.")

func step(dt: float, to: Vector2, d: float, mult: float) -> bool:
	if done:
		vel = Vector2.ZERO
		return true
	bt += dt
	var dir := to.normalized()
	match bstate:
		"intro":
			vel = Vector2.ZERO; face = dir
			if bt > 1.2: bstate = "walk"; bt = 0.0
		"walk":
			face = dir
			vel = dir * speed * mult + knock + separation()
			if d < 190.0 and bt > 0.5:
				bstate = "windup"; bt = 0.0; swing_dir = dir
		"windup":   # the shovel goes up over his shoulder
			vel = Vector2.ZERO; face = swing_dir
			if bt > 0.7:
				bstate = "swing"; bt = 0.0; hit_done = false; strike_t = 0.45
		"swing":    # a wide arc in front of him
			vel = swing_dir * 120.0
			if not hit_done and bt > 0.12:
				hit_done = true
				Fx.ring(pos + swing_dir * 90.0, Color(0.55, 0.5, 0.6, 0.9), 150.0, 0.35)
				Audio.sfx_at("swing", pos, -2.0, 0.5)
				if d < 230.0 and absf(rad_to_deg(swing_dir.angle_to(to))) < 80.0: player.hurt(dmg * mult, dir)
			if bt > 0.45: bstate = "recover"; bt = 0.0
		"recover":  # the shovel bites the floor; he has to drag it out
			vel = Vector2.ZERO
			if bt > 0.9: bstate = "walk"; bt = 0.0
		"call":     # beats the floor with the shovel; the dead come up the stairs
			vel = Vector2.ZERO
			if bt > 1.2: bstate = "walk"; bt = 0.0
	knock = knock.move_toward(Vector2.ZERO, 900.0 * dt)
	return true

func hurt(amount: float, dir: Vector2) -> void:
	if done: return
	if bstate == "recover": amount *= 1.6
	hp -= amount; flash = 0.12
	knock = dir * 90.0
	Audio.sfx("hit", -6.0, 0.7)
	Fx.text(pos, str(roundi(amount)), Color("ffe08a"))
	if bstate == "intro": bstate = "walk"; bt = 0.0
	if not called and hp < max_hp * 0.35:
		called = true; bstate = "call"; bt = 0.0
		Fx.ring(pos, Color(0.6, 0.2, 0.25, 0.9), 220.0, 0.6)
		Audio.sfx("shriek", -4.0, 0.7)
		call_up.emit()
	if hp <= 0.0: die()

func die() -> void:
	if done: return
	done = true; hp = 0.0; bstate = "dead"
	vel = Vector2.ZERO
	_pay()
	if G.boss == self: G.boss = null
	Hud.banner("THE WARDEN FALLS", "The shovel rings on the flagstones, and the crypt goes quiet.")
	beaten.emit()
	died.emit(self)
	set_solid(false)
	all.erase(self)
	get_tree().create_timer(0.6, false).timeout.connect(queue_free)
