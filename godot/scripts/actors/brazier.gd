## An iron fire-basket. Light it with E. In the Vârcolac's second phase the fires burn down after 26 s, and
## the beast can only be wounded near one that is lit.
class_name Brazier
extends Node3D

static var all: Array[Brazier] = []

var lit := true
var decays := false
var lit_t := 26.0
var base_energy := 1.25
var t := randf() * 2.0
var sprite: Sprite3D
var glow: OmniLight3D
var embers: CPUParticles3D
var _frames: Array[Texture2D] = []
var _cold: Texture2D

var pos: Vector2:
	get: return Vector2(position.x, position.z) / Fx.S
	set(v): position = Fx.to3(v)

func setup(at: Vector2, start_lit: bool) -> void:
	pos = at
	add_to_group("interact")
	for k in 8: _frames.append(Mats.tex("res://sprites/Props/brazier_fire_%d.png" % k))
	_cold = Mats.tex("res://sprites/Props/brazier_cold.png")
	sprite = Sprite3D.new()
	sprite.texture = _frames[0]
	sprite.pixel_size = 0.95 / Decor.PPU
	sprite.centered = false
	sprite.offset = Vector2(-_frames[0].get_width() / 2.0, 0)
	sprite.shaded = false
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	sprite.rotation.x = -deg_to_rad(Fx.PITCH * 0.55); sprite.add_to_group("ybill")
	add_child(sprite)
	var sh := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(0.55, 0.25)
	sh.mesh = pm
	sh.material_override = Mats.unlit(Color(0, 0, 0, 0.4), Fx.circle_tex())
	sh.position.y = 0.012
	add_child(sh)
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var cs := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = 13.0 * Fx.S
	cyl.height = 4.0
	cs.shape = cyl
	cs.position.y = 2.0
	body.add_child(cs)
	add_child(body)
	glow = Fx.add_light(self, at, 270.0, Color(1, 0.66, 0.32), base_energy, true)
	embers = Atmosphere.embers(glow)
	set_lit(start_lit)

func _enter_tree() -> void: all.append(self)
func _exit_tree() -> void: all.erase(self)

func set_lit(v: bool) -> void:
	lit = v
	if v: lit_t = 26.0
	Fx.set_light(glow, base_energy if v else 0.0)
	embers.emitting = v

func can_interact() -> bool: return not lit
func prompt_text() -> String: return "E   Light the brazier"

func interact() -> void:
	if lit: return
	set_lit(true)
	Audio.sfx("ignite", -4.0)
	Fx.ring(pos, Color(1, 0.7, 0.3), 90.0)

func _process(dt: float) -> void:
	t += dt
	if lit and decays:
		lit_t -= dt
		if lit_t <= 0.0: set_lit(false)
	if not lit:
		sprite.texture = _cold
		sprite.modulate = Fx.light_at(global_position)
		return
	sprite.texture = _frames[int(t * 10.0) % 8]
	sprite.modulate = Color.WHITE
	var e := base_energy + 0.12 * sin(t * 13.0) + 0.06 * sin(t * 29.0)
	# guttering in its last six seconds
	if decays and lit_t < 6.0: e *= 0.55 + 0.45 * (lit_t / 6.0) + 0.15 * sin(t * 20.0)
	Fx.set_light(glow, e)
