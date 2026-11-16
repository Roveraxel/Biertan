## The Vârcolac, after Romanian folklore: a lean hound "born of the air" that climbs the threads spun by women
## working at night without a candle, and bites the moon, which bleeds red. Fire and noise drive it off. In
## its second phase the fires burn low and it can only be wounded near a lit one; in its third it swallows
## the flames, grows heavy, and its threads snap. It is driven off, never killed.
class_name Varcolac
extends Enemy

signal phase_changed(p: int)
signal beaten

var phase := 1
var bstate := "intro"
var bt := 0.0
var howl_t := 7.0
var swallow_t := 6.0
var charge_dir := Vector2.RIGHT
var eaten := 0
var done := false
var arena: Level
var sprite: Sprite3D

func hud_name() -> String: return "THE VÂRCOLAC, EATER OF THE MOON"
func hud_hint() -> String:
	if bstate == "fallen": return "Its threads have snapped. It is on the ground: strike!"
	if bstate == "telegraph": return "It is going to spring. Sidestep!"
	if phase >= 2 and not vulnerable(): return "It is shadow away from the fire. Light a brazier and fight beside it."
	return ""
func undead() -> bool: return false
func salt_hit(_ring_pos: Vector2, _dt: float) -> void: pass   # salt means nothing to a creature of the air

func setup(_k: String) -> void:
	kind = "varcolac"
	hp = 360.0; max_hp = 360.0
	speed = 105.0; dmg = 16.0; radius = 40.0; coin = 0; aggro = 99999.0; state = "chase"
	heavy = true
	_make_figure()
	set_body_radius(radius * 0.8)
	var tex: Texture2D = Mats.tex("res://sprites/varcolac.png")
	sprite = Sprite3D.new()
	if tex:
		sprite.texture = tex
		sprite.pixel_size = 3.4 / tex.get_width()
		sprite.centered = false
		sprite.offset = Vector2(-tex.get_width() / 2.0, 0)
	sprite.shaded = false
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	sprite.rotation.x = -deg_to_rad(Fx.PITCH * 0.55)
	add_child(sprite)
	if fig: sprite.visible = false   # the drawn, walking figure takes over from the still picture
	G.boss = self

func vulnerable() -> bool:
	if phase == 1 or bstate == "fallen": return true
	for b in Brazier.all:
		if b.lit and b.pos.distance_to(pos) < 260.0: return true
	return false

## A swallowed flame: twice, and it is too heavy for its threads.
func gorge() -> void:
	eaten += 1
	Fx.text(pos, "(it swells)", Color(0.8, 0.5, 0.4), 90.0)
	if eaten >= 2:
		eaten = 0
		bstate = "fallen"; bt = 0.0
		Fx.shake(0.3)
		Fx.ring(pos, Color(0.95, 0.95, 0.85, 0.9), 180.0, 0.6)
		Hud.toast("Its threads snap. It falls!")

func step(dt: float, to: Vector2, d: float, _mult: float) -> bool:
	bt += dt
	var sm := 1.0 + 0.25 * (phase - 1)
	if absf(vel.x) > 5.0: sprite.flip_h = vel.x < 0.0
	sprite.modulate = Color(1.7, 1.7, 1.7) if flash > 0.0 else (Color(0.45, 0.45, 0.6, 0.75) if not vulnerable() else Color.WHITE)
	sprite.rotation.z = PI / 2.0 if bstate == "fallen" else 0.0
	if fig: fig.rotation.z = PI / 2.0 if bstate == "fallen" else 0.0
	if done:
		vel = Vector2.ZERO
		return true
	match bstate:
		"intro":
			vel = Vector2.ZERO; face = to.normalized()
			if bt > 2.5: bstate = "stalk"; bt = 0.0
		"stalk":
			face = to.normalized()
			vel = face * speed * sm + knock
			if d < radius + 34.0 and atk_cd <= 0.0:
				player.hurt(dmg, face); atk_cd = 1.1
			if bt > 2.4 / sm: bstate = "telegraph"; bt = 0.0; charge_dir = face
		"telegraph":
			vel = knock
			if bt < 0.45: charge_dir = to.normalized()
			face = charge_dir
			if int(bt * 12.0) != int((bt - dt) * 12.0):
				for i in range(1, 6): Fx.ring(pos + charge_dir * i * 80.0, Color(0.9, 0.3, 0.3, 0.5), 30.0, 0.12)
			if bt > 0.8 / sm: bstate = "charge"; bt = 0.0; hit_done = false
		"charge":
			vel = charge_dir * 560.0 * sm
			if not hit_done and d < radius + 16.0:
				player.hurt(dmg * 1.4, charge_dir); hit_done = true
			if bt > 0.7:
				bstate = "recover"; bt = 0.0
				Fx.ring(pos, Color(0.6, 0.5, 0.4, 0.6), 110.0, 0.5)
		"recover":
			vel = knock
			if bt > 0.9 / sm: bstate = "stalk"; bt = 0.0
		"fallen":
			vel = knock
			if bt > 5.0: bstate = "stalk"; bt = 0.0
	if bstate != "intro":
		howl_t -= dt
		if howl_t <= 0.0 and bstate in ["stalk", "recover"]:
			howl_t = 12.0 - 2.0 * phase
			arena.boss_howl(self)
		if phase >= 3:
			swallow_t -= dt
			if swallow_t <= 0.0:
				swallow_t = 7.0
				arena.swallow_light(self)
	knock = knock.move_toward(Vector2.ZERO, 700.0 * dt)
	return true

func hurt(amount: float, dir: Vector2) -> void:
	if bstate == "intro" or done: return
	if not vulnerable():
		flash = 0.05
		Fx.text(pos, "shadow", Color("8a8aa8"), 50.0)
		return
	hp -= amount; flash = 0.1; knock = dir * 90.0
	Fx.text(pos, str(roundi(amount)), Color("ffe08a"), 40.0)
	Audio.sfx("hit", -2.0, 0.75)
	if hp <= 0.0:
		hp = 1.0; done = true; bstate = "fallen"
		if G.boss == self: G.boss = null
		all.erase(self)
		set_solid(false)
		Audio.sfx("boss_roar", 0.0, 0.9)
		for i in 3: Fx.ring(pos, Color(1, 0.8, 0.5, 0.9), 120.0 + i * 60.0, 0.7 + i * 0.2)
		beaten.emit()
		return
	var r := hp / max_hp
	var np := 1 if r > 0.66 else (2 if r > 0.33 else 3)
	if np != phase:
		phase = np
		bstate = "recover"; bt = -0.8
		phase_changed.emit(phase)
		Fx.ring(pos, Color(0.9, 0.3, 0.3, 0.9), 220.0, 0.8)

func die() -> void: pass
