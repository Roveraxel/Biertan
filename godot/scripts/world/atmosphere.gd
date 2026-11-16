## The air of a place: low mist drifting over the ground, fireflies in the woods and vines, falling leaves in
## the forest, dust hanging in caves and the church, sparks rising from the braziers. The emitters ride along
## with the hunter; what they have already let go stays where it is.
class_name Atmosphere
extends Node3D

const UNDER := ["caves", "cellar", "crypt", "malcrypt", "gorge", "church", "sacristy"]
const WOODS := ["forest", "stana", "critforest", "crisforest", "richisforest", "ieleridge", "uriasi", "hollow", "hills", "arena"]
const LEAFY := ["forest", "stana", "critforest", "crisforest", "richisforest", "ieleridge", "uriasi", "hollow"]

static var _soft: Texture2D
static var _leaf: Texture2D

static func _textures() -> void:
	if _soft: return
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	for y in 64:
		for x in 64:
			var d := Vector2(x, y).distance_to(Vector2(31.5, 31.5)) / 32.0
			var v := clampf(1.0 - d, 0.0, 1.0)
			img.set_pixel(x, y, Color(1, 1, 1, v * v * (3.0 - 2.0 * v)))
	_soft = ImageTexture.create_from_image(img)
	var li := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	for y in 16:
		for x in 16:
			var u := (x - 7.5) / 7.5; var w := (y - 7.5) / 7.5
			li.set_pixel(x, y, Color.WHITE if absf(u) < (1.0 - absf(w)) * 0.55 and absf(w) < 0.95 else Color(1, 1, 1, 0))
	_leaf = ImageTexture.create_from_image(li)

static func _mat(tex: Texture2D, billboard: bool, additive := false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_texture = tex
	m.vertex_color_use_as_albedo = true
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.disable_receive_shadows = true
	if additive: m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	if billboard:
		m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
		m.billboard_keep_scale = true
	return m

static func _fade(c: Color, alpha: float, in_at: float, out_at: float) -> Gradient:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, in_at, out_at, 1.0])
	g.colors = PackedColorArray([Color(c.r, c.g, c.b, 0), Color(c.r, c.g, c.b, alpha), Color(c.r, c.g, c.b, alpha), Color(c.r, c.g, c.b, 0)])
	return g

static func _system(count: int, life: float, size_min: float, size_max: float, tex: Texture2D, billboard := true, additive := false) -> CPUParticles3D:
	_textures()
	var p := CPUParticles3D.new()
	p.amount = count
	p.lifetime = life
	p.lifetime_randomness = 0.3
	p.local_coords = false
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var q: PrimitiveMesh
	if billboard:
		q = QuadMesh.new()
		(q as QuadMesh).size = Vector2.ONE
	else:
		q = PlaneMesh.new()
		(q as PlaneMesh).size = Vector2.ONE
	q.material = _mat(tex, billboard, additive)
	p.mesh = q
	p.scale_amount_min = size_min
	p.scale_amount_max = size_max
	p.gravity = Vector3.ZERO
	return p

static func _box(p: CPUParticles3D, extents: Vector3, y: float) -> void:
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = extents / 2.0
	p.position.y = y

static func build(level: Node3D, level_id: String) -> Atmosphere:
	var a := Atmosphere.new()
	a.name = "Atmosphere"
	level.add_child(a)
	var under := level_id in UNDER
	var village := Mats.is_village(level_id) or level_id in ["walls", "biertanfort"]
	if not under:
		# mist lying on the ground like a sheet
		var n := 80 if level_id in WOODS else 50
		var m := _system(n, 12.0, 4.0, 8.0, _soft, false)
		_box(m, Vector3(26, 0.3, 22), 0.35)
		m.color_ramp = _fade(Color(0.62, 0.68, 0.8), 0.035 if village else 0.06, 0.3, 0.7)
		m.direction = Vector3(1, 0, 0); m.spread = 15.0
		m.initial_velocity_min = 0.15; m.initial_velocity_max = 0.35
		m.preprocess = 10.0
		a.add_child(m)
	if level_id in ["forest", "stana", "critforest", "crisforest", "richisforest", "ieleridge", "uriasi", "vineyard", "hills", "hollow"]:
		# fireflies glowing on and off as they drift
		var f := _system(26 if level_id == "vineyard" else 18, 6.0, 0.1, 0.17, _soft, true, true)
		_box(f, Vector3(22, 1.6, 18), 1.1)
		var g := Gradient.new()
		g.offsets = PackedFloat32Array([0.0, 0.15, 0.35, 0.55, 0.8, 1.0])
		g.colors = PackedColorArray([Color(0.85, 1, 0.45, 0), Color(0.85, 1, 0.45, 1), Color(0.9, 1, 0.43, 0.15), Color(0.95, 0.95, 0.42, 1), Color(1, 0.9, 0.4, 0.2), Color(1, 0.9, 0.4, 0)])
		f.color_ramp = g
		f.direction = Vector3(1, 0.2, 0.3); f.spread = 180.0
		f.initial_velocity_min = 0.05; f.initial_velocity_max = 0.3
		f.preprocess = 5.0
		a.add_child(f)
	if level_id in LEAFY:
		var l := _system(10, 6.5, 0.12, 0.2, _leaf)
		_box(l, Vector3(20, 0.5, 16), 4.5)
		var g := _fade(Color(0.54, 0.35, 0.14), 0.9, 0.08, 0.85)
		l.color_ramp = g
		l.direction = Vector3(0.5, -0.8, 0); l.spread = 20.0
		l.initial_velocity_min = 0.5; l.initial_velocity_max = 0.8
		l.angle_min = 0.0; l.angle_max = 360.0
		l.angular_velocity_min = -170.0; l.angular_velocity_max = 170.0
		a.add_child(l)
	if under:
		var d := _system(40 if level_id == "church" else 60, 8.0, 0.03, 0.07, _soft)
		_box(d, Vector3(18, 2.5, 14), 1.4)
		d.color_ramp = _fade(Color(0.9, 0.82, 0.68), 0.45, 0.25, 0.75)
		d.direction = Vector3(1, 0.3, 0); d.spread = 180.0
		d.initial_velocity_min = 0.01; d.initial_velocity_max = 0.06
		d.preprocess = 6.0
		a.add_child(d)
	return a

func _process(_dt: float) -> void:
	if is_instance_valid(G.player): global_position = G.player.global_position

## Sparks that rise from a fire, twist on the draught and wink out.
static func embers(fire: Node3D) -> CPUParticles3D:
	var p := _system(22, 1.3, 0.09, 0.15, _soft, true, true)
	p.position.y = -0.15
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 0.08
	p.direction = Vector3.UP; p.spread = 14.0
	p.initial_velocity_min = 0.6; p.initial_velocity_max = 1.5
	p.gravity = Vector3(0, 0.8, 0)
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.6, 1.0])
	g.colors = PackedColorArray([Color(1, 0.9, 0.55, 1), Color(1, 0.6, 0.15, 0.9), Color(0.85, 0.2, 0.04, 0)])
	p.color_ramp = g
	fire.add_child(p)
	return p

## Grey smoke seeping up out of something (a grating over a smoke-cellar), thinning as it climbs.
static func smoke(at: Node3D) -> CPUParticles3D:
	var p := _system(24, 3.2, 0.35, 0.6, _soft)
	p.position.y = 0.05
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 0.2
	p.direction = Vector3.UP; p.spread = 8.0
	p.initial_velocity_min = 0.25; p.initial_velocity_max = 0.5
	p.gravity = Vector3(0, 0.2, 0)
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.15, 1.0])
	g.colors = PackedColorArray([Color(0.55, 0.53, 0.5, 0), Color(0.5, 0.5, 0.48, 0.45), Color(0.4, 0.4, 0.42, 0)])
	p.color_ramp = g
	var c := Curve.new()
	c.add_point(Vector2(0, 0.3)); c.add_point(Vector2(1, 1))
	p.scale_amount_curve = c
	at.add_child(p)
	return p
