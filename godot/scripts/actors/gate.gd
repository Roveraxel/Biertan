## A portcullis across a gap in a wall: solid until opened, then it winds up out of the way.
class_name Gate
extends Node3D

var opened := false
var _shape: CollisionShape3D
var _bars: MeshInstance3D
var _lift := 0.0

static func make(level: Level, centre: Vector2, sz: Vector2, angle_deg: float) -> Gate:
	var g := Gate.new()
	level.add_child(g)
	g.position = Fx.to3(centre)
	g.rotation.y = deg_to_rad(angle_deg)
	g._shape = level.solid_box(centre, sz, angle_deg)
	var b := Batch.new()
	var mb := b.mb(Mats.plain(Color(0.18, 0.16, 0.15), 0.3))
	var w := sz.x * Fx.S; var h := 2.6
	var x := -w / 2.0 + 0.1
	while x < w / 2.0:
		mb.box(Vector3(x - 0.04, 0, -0.04), Vector3(x + 0.04, h, 0.04), true)
		x += 0.28
	for i in 4: mb.box(Vector3(-w / 2.0, h * (i + 0.5) / 4.0 - 0.03, -0.05), Vector3(w / 2.0, h * (i + 0.5) / 4.0 + 0.03, 0.05), true)
	g._bars = b.commit(g, "Portcullis")
	return g

func open() -> void:
	if opened: return
	opened = true
	_shape.disabled = true
	if G.instant or not is_inside_tree() or not G.level.built: _lift = 0.99
	else: Audio.sfx("ignite", -4.0, 0.6)

func _process(dt: float) -> void:
	if not opened or _bars == null: return
	_lift = minf(1.0, _lift + dt * 0.8)
	_bars.position.y = 2.6 * _lift
	_bars.scale.y = maxf(0.01, 1.0 - _lift)
	if _lift >= 1.0:
		_bars.queue_free()
		_bars = null
