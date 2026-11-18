## World-space helpers and effects. Autoloaded as Fx.
## The game's logic runs in "pixels" on a flat map (x east, y south); the world is drawn at S metres per pixel.
extends Node

const S := 0.02          # metres per pixel (50 px = 1 m)
const HK := 2.6          # block face heights are drawn taller in 3D
const PITCH := 52.0      # camera pitch, degrees
const AMBER := Color("ffb347")

var cam: Camera3D
var yaw := 0.0            # camera turn around the hunter (Q/E), radians
var lights: Array[OmniLight3D] = []
var ambient_k := 1.0
var ambient_tint := Color.WHITE
var shake_amt := 0.0
var _circle: Texture2D
var _stop_until := 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func to3(p: Vector2, h := 0.0) -> Vector3:
	return Vector3(p.x * S, h, p.y * S)

func to2(p: Vector3) -> Vector2:
	return Vector2(p.x / S, p.z / S)

func circle_tex() -> Texture2D:
	if _circle == null: _circle = load("res://sprites/circle.png")
	return _circle

## Where effects are parented: the current level, so they go when it does.
func root() -> Node:
	return G.level if is_instance_valid(G.level) else get_tree().current_scene

func _process(delta: float) -> void:
	shake_amt = move_toward(shake_amt, 0.0, delta * 0.6)
	if _stop_until > 0 and Time.get_ticks_msec() >= _stop_until:
		_stop_until = 0
		Engine.time_scale = 1.0

# ------------------------------------------------------------------ lights

## A point light (lantern, fire, salt glow). Radius in pixels, as the levels give it.
func add_light(parent: Node3D, at: Vector2, radius: float, color: Color, energy: float, fire := false) -> OmniLight3D:
	var l := OmniLight3D.new()
	l.light_color = color
	l.omni_range = radius * S * 1.7
	l.omni_attenuation = 1.4
	l.shadow_enabled = false
	l.set_meta("fire", fire)
	l.set_meta("base", energy)
	parent.add_child(l)
	l.global_position = to3(at, 1.35 if fire else 1.8)
	set_light(l, energy)
	lights.append(l)
	l.tree_exiting.connect(func(): lights.erase(l))
	return l

func set_light(l: OmniLight3D, energy: float) -> void:
	l.set_meta("e", energy)
	l.light_energy = energy * (2.6 if l.get_meta("fire") else 1.7)
	l.visible = energy > 0.01

## How brightly the fires light a point: sprites are unlit, so they are tinted by hand.
func light_at(p: Vector3) -> Color:
	var c := Color(0.68, 0.69, 0.78) * ambient_k * ambient_tint
	var q := p + Vector3.UP
	for l in lights:
		if not l.visible or not l.is_inside_tree(): continue
		var d := l.global_position.distance_to(q)
		if d >= l.omni_range: continue
		var k := 1.0 - d / l.omni_range
		var e: float = l.get_meta("e") * (7.0 if l.get_meta("fire") else 4.5)
		c += l.light_color * (e * 0.12 * k * k)
	return Color(minf(c.r, 1.25), minf(c.g, 1.25), minf(c.b, 1.25), 1.0)

# ------------------------------------------------------------------ small effects

## Rising, fading text over a spot (damage, coins, a bark). `lift` is extra height in pixels.
func text(at: Vector2, s: String, color: Color, lift := 0.0) -> void:
	var l := Label3D.new()
	l.text = s
	l.modulate = color
	l.outline_modulate = Color(0, 0, 0, 0.85)
	l.outline_size = 8
	l.font_size = 40
	l.pixel_size = 0.0075
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.render_priority = 5
	root().add_child(l)
	l.global_position = to3(at, 1.7 + lift * S)
	var tw := l.create_tween().set_parallel()
	tw.tween_property(l, "position:y", l.position.y + 0.8, 0.9)
	tw.tween_property(l, "modulate:a", 0.0, 0.9)
	tw.tween_property(l, "outline_modulate:a", 0.0, 0.9)
	tw.chain().tween_callback(l.queue_free)

## An expanding ring on the ground.
func ring(at: Vector2, color: Color, radius: float, life := 0.4) -> void:
	var mb := MeshBuilder.new()
	mb.ring(Vector3.ZERO, 1.0 - 0.06, 1.0)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.albedo_color = color
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, mb.arrays())
	mesh.surface_set_material(0, m)
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root().add_child(mi)
	mi.global_position = to3(at, 0.06)
	var r := radius * S
	mi.scale = Vector3(r * 0.4, 1, r * 0.4)
	var tw := mi.create_tween().set_parallel()
	tw.tween_property(mi, "scale", Vector3(r, 1, r), life)
	tw.tween_property(m, "albedo_color:a", 0.0, life)
	tw.chain().tween_callback(mi.queue_free)

## Shake the camera by about this many metres (it settles on its own).
func shake(amount: float) -> void:
	shake_amt = maxf(shake_amt, amount)

## Freeze the game for a heartbeat so a killing blow lands with weight.
func hit_stop(seconds: float) -> void:
	if Engine.time_scale < 1.0: return
	Engine.time_scale = 0.05
	_stop_until = Time.get_ticks_msec() + int(seconds * 1000.0)

func _streaks(at: Vector3, life: float, draw: Callable) -> void:
	var im := ImmediateMesh.new()
	var mi := MeshInstance3D.new()
	mi.mesh = im
	mi.material_override = _line_mat()
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root().add_child(mi)
	mi.global_position = at
	var tw := mi.create_tween()
	tw.tween_method(func(k: float): im.clear_surfaces(); draw.call(im, k), 0.0, 1.0, life)
	tw.tween_callback(mi.queue_free)

var _lm: StandardMaterial3D
func _line_mat() -> StandardMaterial3D:
	if _lm == null:
		_lm = StandardMaterial3D.new()
		_lm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_lm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_lm.vertex_color_use_as_albedo = true
		_lm.cull_mode = BaseMaterial3D.CULL_DISABLED
		_lm.no_depth_test = true
	return _lm

## A camera-facing streak from a to b.
func _streak(im: ImmediateMesh, a: Vector3, b: Vector3, w: float, ca: Color, cb: Color) -> void:
	var side := Vector3(w, 0, 0)
	im.surface_set_color(ca); im.surface_add_vertex(a - side)
	im.surface_set_color(ca); im.surface_add_vertex(a + side)
	im.surface_set_color(cb); im.surface_add_vertex(b)

## Sparks where the blade lands, thrown along dir.
func spark(at: Vector2, dir: Vector2) -> void:
	var d3 := Vector3(dir.x, 0, dir.y)
	if d3.length_squared() < 0.0001: d3 = Vector3(0, 0, 1)
	d3 = d3.normalized()
	var dirs: Array[Vector3] = []
	for i in 7:
		var d := d3.rotated(Vector3.UP, deg_to_rad(randf_range(-55, 55)))
		d.y += randf_range(0.1, 0.7)
		dirs.append(d.normalized() * randf_range(0.5, 0.95))
	_streaks(to3(at, 0.8), 0.16, func(im: ImmediateMesh, k: float):
		var e := 1.0 - (1.0 - k) * (1.0 - k)
		im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
		for i in dirs.size():
			var col := Color(1, 0.93, 0.75, 1.0 - k) if i < 4 else Color(0.7, 0.05, 0.05, 1.0 - k)
			_streak(im, dirs[i] * (0.15 + e * 0.55), dirs[i] * (0.15 + e * 0.55 + 0.18 * (1.0 - k)), 0.022 if i < 4 else 0.035, col, col)
		im.surface_end())

## Three red claw rakes swept through the air in front of a striking monster.
func claw(at: Vector2, dir: Vector2) -> void:
	var f := Vector3(dir.x, 0, dir.y)
	if f.length_squared() < 0.0001: f = Vector3(0, 0, 1)
	f = f.normalized()
	var right := Vector3.UP.cross(f).normalized()
	_streaks(to3(at, 0.75), 0.32, func(im: ImmediateMesh, k: float):
		im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
		var col := Color(0.85, 0.08, 0.06, (1.0 - k) * 0.95)
		for i in 3:
			var off := (i - 1) * 0.16
			var prev := Vector3.ZERO
			for j in 9:
				var u := minf(j / 8.0, clampf(k * 1.6, 0.0, 1.0))
				var p := right * (lerpf(-0.45, 0.45, u) + off * 0.3) + Vector3.UP * (lerpf(0.45, -0.4, u) + off) + f * (0.55 + sin(u * PI) * 0.18)
				if j > 0:
					var w := 0.045 * sin(PI * (j - 0.5) / 8.0)
					_streak(im, prev, p, w, col, col)
					_streak(im, p, prev, w, col, col)
				prev = p
		im.surface_end())

## What is left of a slain creature: its last frame tips over beside a spreading pool of blood, then both fade.
func corpse(fig: Node3D, flipped: bool) -> void:
	var at := fig.global_position
	var rot := fig.global_rotation
	fig.get_parent().remove_child(fig)
	root().add_child(fig)
	fig.global_position = at
	fig.global_rotation = rot
	fig.set_process(false)
	var side := -1.0 if flipped else 1.0
	var pool := MeshInstance3D.new()
	var qm := PlaneMesh.new()
	qm.size = Vector2(1, 1)
	pool.mesh = qm
	var pm := StandardMaterial3D.new()
	pm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	pm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	pm.albedo_texture = circle_tex()
	pm.albedo_color = Color(0.32, 0.02, 0.03, 0.75)
	pool.material_override = pm
	pool.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root().add_child(pool)
	pool.global_position = Vector3(at.x - side * 0.35, 0.012, at.z)
	pool.scale = Vector3(0.2, 1, 0.12)
	var tw := fig.create_tween()
	tw.tween_property(fig, "rotation:z", fig.rotation.z + deg_to_rad(side * 82.0), 0.35).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tw.parallel().tween_property(fig, "position:y", fig.position.y - 0.04, 0.35)
	tw.parallel().tween_property(pool, "scale", Vector3(1.1, 1, 0.66), 1.2).set_delay(0.15).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tw.tween_interval(1.2)
	tw.tween_property(pm, "albedo_color:a", 0.0, 1.0)
	if fig.has_method("fade_to"): tw.parallel().tween_method(fig.fade_to, 1.0, 0.0, 1.0)
	tw.tween_callback(func(): fig.queue_free(); pool.queue_free())
