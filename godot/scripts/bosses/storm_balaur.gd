## The Solomonar's balaur, called down out of the cloud. It circles overhead where no blade reaches and throws
## lightning (which takes the tallest thing near where it lands: stand by a standing stone). Then it comes down
## in a marked line, and for a few breaths it is on the ground and can be hit. It is beaten back, never killed.
class_name StormBalaur
extends Enemy

signal beaten

var bstate := "intro"
var bt := 0.0
var centre := Vector2.ZERO
var ang := 0.0
var alt := 3.2            # metres above the ground
var bolts := 0
var bolt_cd := 2.0
var lane_from := Vector2.ZERO
var lane_to := Vector2.ZERO
var dive_hit := false
var done := false
var sprite: Sprite3D
var body: MeshInstance3D
var smat: ShaderMaterial
var wave := 1.0

const SERPENT := """
shader_type spatial;
render_mode unshaded, cull_disabled, depth_prepass_alpha;
uniform sampler2D tex : filter_nearest;
uniform float flip = 0.0;
uniform float amp = 0.03;
uniform float speed = 4.0;
uniform float flash = 0.0;
void fragment() {
	vec2 uv = UV;
	if (flip > 0.5) uv.x = 1.0 - uv.x;
	float along = flip > 0.5 ? uv.x : 1.0 - uv.x;   // 0 at the head (drawn facing right), 1 at the tail
	uv.y += sin(along * 11.0 - TIME * speed) * amp * smoothstep(0.08, 0.5, along);
	uv.x += cos(along * 7.0 - TIME * speed * 0.7) * amp * 0.35 * along;
	vec4 c = texture(tex, uv);
	if (c.a < 0.5) discard;
	ALBEDO = c.rgb * (1.0 + flash * 0.7);
}
"""
var arena: Level

func hud_name() -> String: return "THE SOLOMONAR'S BALAUR"
func hud_hint() -> String:
	match bstate:
		"dive_tel": return "It is coming down. Out of its line!"
		"grounded": return "It is on the ground. Now!"
		"circle": return "Lightning takes the tallest thing. Stand by a standing stone."
	return ""
func undead() -> bool: return false
func salt_hit(_ring_pos: Vector2, _dt: float) -> void: pass

func setup(_k: String) -> void:
	kind = "storm_balaur"
	hp = 380.0; max_hp = 380.0
	speed = 0.0; dmg = 26.0; radius = 46.0; coin = 0; aggro = 99999.0; state = "chase"
	heavy = true
	_make_figure()
	set_solid(false)
	var tex: Texture2D = Mats.tex("res://sprites/balaur_storm.png")
	if tex == null: tex = Mats.tex("res://sprites/balaur_head.png")
	# the serpent is one drawing, made to move: its body ripples in a travelling wave from the head to the
	# tail, faster while it flies, and the whole thing rolls and breathes
	sprite = Sprite3D.new()   # kept for size and facing; the quad below is what is seen
	sprite.texture = tex
	sprite.visible = false
	add_child(sprite)
	var w := 5.2
	var qm := QuadMesh.new(); qm.size = Vector2(w, w * tex.get_height() / tex.get_width())
	body = MeshInstance3D.new()
	body.mesh = qm
	body.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var sh := Shader.new()
	sh.code = SERPENT
	smat = ShaderMaterial.new(); smat.shader = sh
	smat.set_shader_parameter("tex", tex)
	body.material_override = smat
	body.rotation.x = -deg_to_rad(Fx.PITCH * 0.55); body.add_to_group("ybill")
	add_child(body)
	G.boss = self

func step(dt: float, to: Vector2, d: float, mult: float) -> bool:
	vel = Vector2.ZERO
	bt += dt
	var want_alt := 3.2
	var before := pos
	match bstate:
		"intro":
			pos = centre + Vector2.from_angle(ang) * 520.0
			if bt > 2.0: bstate = "circle"; bt = 0.0; bolts = 0; bolt_cd = 1.2
		"circle":
			ang += dt * 0.8
			pos = pos.lerp(centre + Vector2(cos(ang), sin(ang) * 0.7) * 520.0, minf(1.0, dt * 3.0))
			bolt_cd -= dt
			if bolt_cd <= 0.0:
				bolt_cd = 1.5
				bolts += 1
				arena.lightning(player.pos + player.vel * 0.35)
			if bolts >= 3 and bolt_cd < 0.6:
				bstate = "dive_tel"; bt = 0.0
				lane_from = pos
				lane_to = player.pos + (player.pos - pos).normalized() * 260.0
				Audio.sfx_at("boss_roar", pos, -2.0, 1.3)
		"dive_tel":
			want_alt = 2.2
			if int(bt * 10.0) != int((bt - dt) * 10.0):
				for i in range(1, 7): Fx.ring(lane_from.lerp(lane_to, i / 6.0), Color(0.75, 0.85, 1, 0.55), 60.0, 0.15)
			if bt > 1.0: bstate = "dive"; bt = 0.0; dive_hit = false
		"dive":
			want_alt = 0.5
			var u := minf(1.0, bt / 0.55)
			pos = lane_from.lerp(lane_to, u)
			if not dive_hit and player.inv_t <= 0.0 and pos.distance_to(player.pos) < 85.0:
				dive_hit = true
				player.hurt(dmg * mult, (lane_to - lane_from).normalized())
			if u >= 1.0:
				bstate = "grounded"; bt = 0.0
				Fx.shake(0.3)
				Fx.ring(pos, Color(0.7, 0.8, 0.9, 0.9), 150.0, 0.5)
				Audio.sfx_at("hit", pos, 0.0, 0.5)
		"grounded":
			want_alt = 0.0
			if bt > 4.2:
				bstate = "circle"; bt = 0.0; bolts = 0; bolt_cd = 1.6
				ang = (pos - centre).angle()
		"down":
			want_alt = 0.0
	alt = move_toward(alt, want_alt, dt * 9.0)
	var dx := pos.x - before.x
	if absf(dx) > 0.5: sprite.flip_h = dx < 0.0
	elif bstate in ["grounded", "down"]: sprite.flip_h = to.x < 0.0
	# how hard it writhes: lazy coils while circling, a whip on the dive, a slow pant on the ground
	var want_wave: float = {"dive": 2.4, "dive_tel": 1.6, "grounded": 0.45, "down": 0.15}.get(bstate, 1.0)
	wave = move_toward(wave, want_wave, dt * 2.0)
	var tt := Time.get_ticks_msec() / 1000.0
	body.position.y = alt + 1.1 + sin(tt * 1.7) * 0.18 * wave
	body.rotation.z = sin(tt * 1.1) * 0.06 * wave + (0.25 if bstate == "dive" else 0.0) * (-1.0 if sprite.flip_h else 1.0)
	body.scale = Vector3.ONE * (1.0 + sin(tt * 2.3) * 0.02)
	smat.set_shader_parameter("flip", 1.0 if sprite.flip_h else 0.0)
	smat.set_shader_parameter("amp", 0.022 * wave + 0.006)
	smat.set_shader_parameter("speed", 2.5 + 2.5 * wave)
	smat.set_shader_parameter("flash", 1.0 if flash > 0.0 else 0.0)
	return true

func hurt(amount: float, dir: Vector2) -> void:
	if done: return
	if bstate != "grounded":
		if alt > 1.0: Fx.text(pos, "(out of reach)", Color(0.8, 0.85, 0.95), 120.0)
		return
	hp -= amount; flash = 0.12
	Audio.sfx("hit", -6.0, 0.7)
	Fx.text(pos, str(roundi(amount)), Color("ffe08a"), 40.0)
	if hp <= 0.0:
		hp = 1.0; done = true; bstate = "down"
		if G.boss == self: G.boss = null
		Fx.ring(pos, Color(0.8, 0.9, 1, 0.9), 220.0, 0.8)
		Audio.sfx("boss_roar", -2.0, 0.6)
		all.erase(self)
		beaten.emit()

func die() -> void: pass
