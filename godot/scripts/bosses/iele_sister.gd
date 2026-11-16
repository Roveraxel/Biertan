## One of the seven Iele on the ridge. Three are real and four are frost and moonlight. None can be struck
## until Ilie's Doina makes one solid; striking an illusion turns the blow back on the hunter.
class_name IeleSister
extends Enemy

var real := false
var solid_t := 0.0
var ring = null
var target := Vector2.ZERO
var tick_t := 0.0

func setup(_k: String) -> void:
	kind = "iele_s"
	hp = 1.0; max_hp = 1.0
	speed = 400.0; dmg = 0.0; radius = 16.0; coin = 0; aggro = 99999.0; state = "chase"
	_make_figure()
	set_solid(false)

func make_real() -> void:
	real = true
	hp = 110.0; max_hp = 110.0

func undead() -> bool: return false
func salt_hit(_ring_pos: Vector2, _dt: float) -> void: pass

func step(dt: float, to: Vector2, _d: float, _mult: float) -> bool:
	if solid_t > 0.0:
		solid_t -= dt
		vel = knock; face = to.normalized()
		tick_t -= dt
		if tick_t <= 0.0:
			tick_t = 0.4
			Fx.ring(pos, Color(1, 0.95, 0.7, 0.9), 40.0, 0.3)
	else:
		vel = ((target - pos) * 5.0).limit_length(700.0)
		face = vel.normalized() if vel.length_squared() > 1.0 else Vector2.DOWN
	knock = knock.move_toward(Vector2.ZERO, 900.0 * dt)
	return true

func hurt(amount: float, dir: Vector2) -> void:
	if hp <= 0.0: return
	if solid_t <= 0.0:
		if not real:
			# the illusion bursts like frost and the blow comes back on him
			Fx.text(pos, "(it laughs)", Color(0.85, 0.85, 1), 50.0)
			Fx.ring(pos, Color(0.8, 0.85, 1, 0.9), 60.0, 0.3)
			if player: player.hurt(7.0, -dir)
		else: Fx.text(pos, "(your blade passes through her)", Color(0.85, 0.85, 1), 50.0)
		Audio.sfx("blip", -10.0, 1.6)
		return
	hp -= amount; flash = 0.12; knock = dir * 60.0
	Audio.sfx("hit", -6.0, 1.3)
	Fx.text(pos, str(roundi(amount)), Color("ffe08a"))
	if ring and ring.phase < 3 and hp < 1.0: hp = 1.0   # they cannot fall while the illusions still hide them
	if hp <= 0.0:
		hp = 0.0; solid_t = 0.0
		all.erase(self)
		Fx.ring(pos, Color(0.9, 0.95, 1, 0.9), 110.0, 0.6)
		Fx.text(pos, "Brr...", Color(0.9, 0.95, 1), 60.0)
		ring.sister_down(self)
