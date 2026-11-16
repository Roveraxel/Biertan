## Marțolea, the spirit of Tuesday evening, who comes for women that work after dark on her day. She is as
## strong as the number of vessels left standing upright in the house: each one answered when she called.
## She claws at arm's length and throws a line of spun thread that tangles the feet. At cockcrow she goes.
class_name Martolea
extends Enemy

signal beaten

var bstate := "intro"
var bt := 0.0
var missed := 0
var thread_cd := 5.0
var thread_dir := Vector2.ZERO
var thread_hit := false
var done := false
var sprite: Sprite3D

func hud_name() -> String: return "MARȚOLEA"
func hud_hint() -> String:
	match bstate:
		"thread_tel": return "She is drawing out a thread. Step out of its line!"
		"windup": return "Her hand goes up. Get back!"
	return ""
func undead() -> bool: return false
func salt_hit(_ring_pos: Vector2, _dt: float) -> void: pass

func setup(_k: String) -> void:
	kind = "martolea"
	heavy = true
	radius = 24.0; coin = 0; aggro = 99999.0; state = "chase"
	_make_figure()
	set_body_radius(radius * 0.9)
	var tex: Texture2D = Mats.tex("res://sprites/martolea.png")
	sprite = Sprite3D.new()
	if tex:
		sprite.texture = tex
		sprite.pixel_size = 2.5 / tex.get_height()
		sprite.centered = false
		sprite.offset = Vector2(-tex.get_width() / 2.0, 0)
	sprite.shaded = false
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	sprite.rotation.x = -deg_to_rad(Fx.PITCH * 0.55)
	add_child(sprite)
	strengthen(0)
	G.boss = self

## One upright vessel more, one measure of strength more.
func strengthen(m: int) -> void:
	missed = m
	max_hp = 150.0 + 75.0 * m; hp = max_hp
	speed = 92.0 + 9.0 * m
	dmg = 11.0 + 2.5 * m

func step(dt: float, to: Vector2, d: float, mult: float) -> bool:
	bt += dt
	var dir := to.normalized()
	sprite.flip_h = to.x < 0.0
	sprite.modulate = Color(1.7, 1.7, 1.7) if flash > 0.0 else Color.WHITE
	if done:
		vel = Vector2.ZERO
		return true
	match bstate:
		"intro":
			vel = Vector2.ZERO
			if bt > 1.4: bstate = "walk"; bt = 0.0
		"walk":
			vel = dir * speed * mult + knock + separation()
			thread_cd -= dt
			if d < 120.0 and bt > 0.6:
				bstate = "windup"; bt = 0.0
			elif thread_cd <= 0.0 and d > 160.0:
				bstate = "thread_tel"; bt = 0.0; thread_dir = dir
				thread_cd = maxf(3.0, 6.5 - missed * 0.5)
		"windup":
			vel = Vector2.ZERO
			if bt > maxf(0.35, 0.6 - missed * 0.03):
				bstate = "claw"; bt = 0.0
				Audio.sfx_at("slash", pos, -4.0, 0.7)
				Fx.ring(pos + dir * 70.0, Color(0.7, 0.7, 0.85, 0.9), 90.0, 0.25)
				if d < 150.0 and player.inv_t <= 0.0: player.hurt(dmg * mult, dir)
		"claw":
			vel = Vector2.ZERO
			if bt > 0.7: bstate = "walk"; bt = 0.0
		"thread_tel":   # she draws a length of thread off the distaff
			vel = Vector2.ZERO
			if int(bt * 12.0) != int((bt - dt) * 12.0):
				for i in range(1, 9): Fx.ring(pos + thread_dir * i * 60.0, Color(0.95, 0.95, 0.85, 0.5), 20.0, 0.12)
			if bt > 0.8:
				bstate = "thread"; bt = 0.0; thread_hit = false
				Audio.sfx_at("swing", pos, -4.0, 1.4)
		"thread":
			vel = Vector2.ZERO
			if not thread_hit:
				thread_hit = true
				var along := to.dot(thread_dir); var side := absf(thread_dir.cross(to))
				if along > 0.0 and along < 520.0 and side < 40.0 and player.inv_t <= 0.0:
					player.hurt(7.0 * mult, thread_dir)
					player.slow_t = maxf(player.slow_t, 1.8)
					Fx.text(player.pos, "(tangled)", Color(0.95, 0.95, 0.85), 70.0)
			if bt > 0.5: bstate = "walk"; bt = 0.0
	knock = knock.move_toward(Vector2.ZERO, 900.0 * dt)
	return true

func hurt(amount: float, dir: Vector2) -> void:
	if done or bstate == "intro": return
	hp -= amount; flash = 0.12; knock = dir * 70.0
	Audio.sfx("hit", -6.0, 0.9)
	Fx.text(pos, str(roundi(amount)), Color("ffe08a"), 40.0)
	if hp <= 0.0:
		hp = 1.0; done = true
		if G.boss == self: G.boss = null
		all.erase(self)
		set_solid(false)
		beaten.emit()

func die() -> void: pass
