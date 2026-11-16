## A wooden farm gate across a lane or a yard: two plank leaves on posts under a little shingle roof, as on
## the old Saxon and Romanian yards. Shut, it blocks the way; E swings both leaves open and it stays open.
class_name WoodGate
extends Node3D

static var _by_prop := {}

var opened := false
var _shape: CollisionShape3D
var _leaves: Array[Node3D] = []
var _swing := 0.0
var _prop: Prop

## centre and width in level pixels, angle in degrees (0: the gate runs east-west, across a north-south lane).
static func make(level: Level, centre: Vector2, width: float, angle_deg: float, label := "Gate") -> WoodGate:
	var g := WoodGate.new()
	level.add_child(g)
	g.position = Fx.to3(centre)
	g.rotation.y = deg_to_rad(angle_deg)
	g._shape = level.solid_box(centre, Vector2(width, 22.0), angle_deg)
	var w := width * Fx.S
	var wood := Mats.mat("px_planks", 1.0, Color(1.0, 0.86, 0.66), 0.04)
	var dark := Mats.mat("px_planks", 0.8, Color(0.7, 0.56, 0.42), 0.04)
	var b := Batch.new()
	var mb := b.mb(dark)
	for sx: float in [-1.0, 1.0]:   # the two posts, and the beam with its small roof over them
		mb.box(Vector3(sx * w / 2.0 - 0.13, 0, -0.13), Vector3(sx * w / 2.0 + 0.13, 2.5, 0.13), true)
	mb.box(Vector3(-w / 2.0 - 0.25, 2.4, -0.16), Vector3(w / 2.0 + 0.25, 2.55, 0.16), true)
	b.mb(Mats.roof()).box(Vector3(-w / 2.0 - 0.4, 2.55, -0.45), Vector3(w / 2.0 + 0.4, 2.7, 0.45), true)
	b.commit(g, "Gateposts")
	for sx: float in [-1.0, 1.0]:   # each leaf hinges on its post
		var hinge := Node3D.new()
		g.add_child(hinge)
		hinge.position = Vector3(sx * (w / 2.0 - 0.13), 0, 0)
		var lb := Batch.new()
		var lm := lb.mb(wood)
		var lw := w / 2.0 - 0.15
		var x := 0.0
		while x < lw - 0.05:   # upright planks, pointed by height
			var px0 := -sx * x; var px1 := -sx * minf(x + 0.13, lw)
			lm.box(Vector3(minf(px0, px1), 0.12, -0.04), Vector3(maxf(px0, px1), 1.75, 0.04), true)
			x += 0.22
		var dm := lb.mb(dark)
		for yy in [0.45, 1.4]: dm.box(Vector3(minf(0.0, -sx * lw), yy, -0.07), Vector3(maxf(0.0, -sx * lw), yy + 0.12, 0.07), true)
		lb.commit(hinge, "Leaf")
		g._leaves.append(hinge)
	g._prop = level.add_prop("gate", "gate_" + label.to_lower().replace(" ", "_"), label, centre, "E   Open the gate")
	_by_prop[g._prop] = g
	return g

static func use(p: Prop) -> bool:
	if not _by_prop.has(p): return false
	var g: WoodGate = _by_prop[p]
	if is_instance_valid(g): g.open()
	return true

func open() -> void:
	if opened: return
	opened = true
	_shape.disabled = true
	if is_instance_valid(_prop):
		_prop.used = true; _prop.prompt = ""
		_prop.remove_from_group("interact")
	if G.instant or not is_inside_tree() or not G.level.built: _swing = 1.0
	else: Audio.sfx("step_wood", -2.0, 0.55)
	_pose()

func _process(dt: float) -> void:
	if not opened or _swing >= 1.0: return
	_swing = minf(1.0, _swing + dt * 1.4)
	_pose()

func _pose() -> void:
	var k := 1.0 - pow(1.0 - _swing, 3.0)
	for i in _leaves.size():
		_leaves[i].rotation.y = (1.0 if i == 0 else -1.0) * k * deg_to_rad(100.0)
