## Procedural mesh helper: flat-shaded quads and triangles with world-anchored UVs (in metres).
## Geometry is authored in the Unity build's space (x east, y up, z NORTH); every vertex goes through
## `xf` and is then mirrored into Godot's space (z south) on the way out. Materials are drawn two-sided.
class_name MeshBuilder
extends RefCounted

var xf := Transform3D.IDENTITY
var _v := PackedVector3Array()
var _n := PackedVector3Array()
var _uv := PackedVector2Array()

static func _axes(normal: Vector3) -> Array:
	if absf(normal.y) > 0.95: return [Vector3.RIGHT, Vector3(0, 0, 1)]
	var u := Vector3.UP.cross(normal).normalized()
	if u.length_squared() < 1e-6: u = Vector3.RIGHT
	return [u, normal.cross(u).normalized()]

func _out(p: Vector3) -> Vector3:
	var q := xf * p
	return Vector3(q.x, q.y, -q.z)

func empty() -> bool:
	return _v.is_empty()

func tri(a: Vector3, b: Vector3, c: Vector3, offset := Vector3.ZERO) -> void:
	var nu := (b - a).cross(c - a).normalized()
	var ax := _axes(nu)
	var ga := _out(a); var gb := _out(b); var gc := _out(c)
	var gn := (gc - ga).cross(gb - ga).normalized()   # the side this winding shows its front to
	for p in [[ga, a], [gb, b], [gc, c]]:
		_v.append(p[0]); _n.append(gn)
		var wp: Vector3 = p[1] + offset
		_uv.append(Vector2(wp.dot(ax[0]), wp.dot(ax[1])))

func quad(a: Vector3, b: Vector3, c: Vector3, d: Vector3, offset := Vector3.ZERO) -> void:
	var nu := (b - a).cross(c - a).normalized()
	var ax := _axes(nu)
	var g := [_out(a), _out(b), _out(c), _out(d)]
	var gn: Vector3 = (g[2] - g[0]).cross(g[1] - g[0]).normalized()
	var src := [a, b, c, d]
	for k in [0, 1, 2, 0, 2, 3]:
		_v.append(g[k]); _n.append(gn)
		var wp: Vector3 = src[k] + offset
		_uv.append(Vector2(wp.dot(ax[0]), wp.dot(ax[1])))

## A triangle with its own (outward) vertex normals, for soft-shaded rounded shapes.
func tri_smooth(a: Vector3, b: Vector3, c: Vector3, na: Vector3, nb: Vector3, nc: Vector3) -> void:
	var ga := _out(a); var gb := _out(b); var gc := _out(c)
	var rb := xf.basis
	var gna := _flip(rb * na); var gnb := _flip(rb * nb); var gnc := _flip(rb * nc)
	if (gc - ga).cross(gb - ga).dot(gna + gnb + gnc) < 0.0:
		var t := gb; gb = gc; gc = t
		var tn := gnb; gnb = gnc; gnc = tn
	_v.append(ga); _v.append(gb); _v.append(gc)
	_n.append(gna); _n.append(gnb); _n.append(gnc)
	_uv.append(Vector2(ga.x, ga.z)); _uv.append(Vector2(gb.x, gb.z)); _uv.append(Vector2(gc.x, gc.z))

static func _flip(v: Vector3) -> Vector3:
	return Vector3(v.x, v.y, -v.z).normalized()

## An axis-aligned box from mn to mx (no bottom).
func box(mn: Vector3, mx: Vector3, top: bool, bottom := false) -> void:
	var p000 := mn; var p100 := Vector3(mx.x, mn.y, mn.z); var p010 := Vector3(mn.x, mx.y, mn.z); var p110 := Vector3(mx.x, mx.y, mn.z)
	var p001 := Vector3(mn.x, mn.y, mx.z); var p101 := Vector3(mx.x, mn.y, mx.z); var p011 := Vector3(mn.x, mx.y, mx.z); var p111 := mx
	quad(p000, p010, p110, p100)
	quad(p101, p111, p011, p001)
	quad(p001, p011, p010, p000)
	quad(p100, p110, p111, p101)
	if top: quad(p010, p011, p111, p110)
	if bottom: quad(p000, p100, p101, p001)

## A closed box centred on c, optionally turned about the z axis (a diagonal brace on a wall).
func cube(c: Vector3, size: Vector3, rot_z_deg := 0.0) -> void:
	var keep := xf
	var r := deg_to_rad(rot_z_deg)
	xf = xf * Transform3D(Basis(Vector3(cos(r), sin(r), 0), Vector3(-sin(r), cos(r), 0), Vector3(0, 0, 1)), c)
	box(-size / 2.0, size / 2.0, true, true)
	xf = keep

## Crenellations along the top of a wall.
func merlons(mn: Vector3, mx: Vector3) -> void:
	var w := mx.x - mn.x; var d := mx.z - mn.z
	var along_x := w >= d
	var length := w if along_x else d
	var t := 0.1
	while t + 0.3 < length:
		if along_x: box(Vector3(mn.x + t, mx.y, mn.z), Vector3(mn.x + t + 0.3, mx.y + 0.3, mx.z), true)
		else: box(Vector3(mn.x, mx.y, mn.z + t), Vector3(mx.x, mx.y + 0.3, mn.z + t + 0.3), true)
		t += 0.6

## A broken wall: segments of uneven height.
func ruin_box(mn: Vector3, mx: Vector3, seed_value: int) -> void:
	var r := NetRandom.new(seed_value)
	var w := mx.x - mn.x
	var n := maxi(2, int(w / 0.7))
	for i in n:
		var x0 := mn.x + i * w / n; var x1 := mn.x + (i + 1) * w / n
		var h := (mx.y - mn.y) * (0.35 + 0.65 * r.f())
		box(Vector3(x0, mn.y, mn.z), Vector3(x1, mn.y + h, mx.z), true)

## A pitched roof over the box, ridge along its longer side, with eaves overhang.
func gable(mn: Vector3, mx: Vector3, rise: float, over: float) -> void:
	var w := mx.x - mn.x; var d := mx.z - mn.z; var y := mx.y
	if w >= d:
		var zc := (mn.z + mx.z) / 2.0
		var a := Vector3(mn.x - over, y - over * 0.5, mn.z - over); var b := Vector3(mx.x + over, y - over * 0.5, mn.z - over)
		var c := Vector3(mx.x + over, y + rise, zc); var e := Vector3(mn.x - over, y + rise, zc)
		var f := Vector3(mn.x - over, y - over * 0.5, mx.z + over); var g := Vector3(mx.x + over, y - over * 0.5, mx.z + over)
		quad(a, e, c, b)
		quad(g, c, e, f)
		tri(Vector3(mn.x, y, mn.z), Vector3(mn.x, y, mx.z), Vector3(mn.x, y + rise, zc))
		tri(Vector3(mx.x, y, mx.z), Vector3(mx.x, y, mn.z), Vector3(mx.x, y + rise, zc))
	else:
		var xc := (mn.x + mx.x) / 2.0
		var a := Vector3(mn.x - over, y - over * 0.5, mx.z + over); var b := Vector3(mn.x - over, y - over * 0.5, mn.z - over)
		var c := Vector3(xc, y + rise, mn.z - over); var e := Vector3(xc, y + rise, mx.z + over)
		var f := Vector3(mx.x + over, y - over * 0.5, mn.z - over); var g := Vector3(mx.x + over, y - over * 0.5, mx.z + over)
		quad(a, e, c, b)
		quad(f, c, e, g)
		tri(Vector3(mn.x, y, mn.z), Vector3(xc, y + rise, mn.z), Vector3(mx.x, y, mn.z))
		tri(Vector3(mx.x, y, mx.z), Vector3(xc, y + rise, mx.z), Vector3(mn.x, y, mx.z))

## A hipped roof, the Romanian peasant house's: four slopes, a short ridge, and a long low front eave over the prispa.
func hip(mn: Vector3, mx: Vector3, rise: float, over: float, front_over: float, front_drop: float) -> void:
	var y := mx.y; var w := mx.x - mn.x; var d := mx.z - mn.z
	var zc := (mn.z - front_over + mx.z) / 2.0
	var inset := maxf(0.05, minf(w * 0.5 - 0.2, (d + front_over) * 0.5))
	var a := Vector3(mn.x - over, y - front_drop, mn.z - over - front_over); var b := Vector3(mx.x + over, y - front_drop, mn.z - over - front_over)
	var f := Vector3(mn.x - over, y - over * 0.5, mx.z + over); var g := Vector3(mx.x + over, y - over * 0.5, mx.z + over)
	var r1 := Vector3(mn.x + inset, y + rise, zc); var r2 := Vector3(mx.x - inset, y + rise, zc)
	quad(a, r1, r2, b)
	quad(g, r2, r1, f)
	tri(a, f, r1); tri(g, b, r2)

func pyramid(mn: Vector3, mx: Vector3, rise: float, over: float) -> void:
	var y := mx.y
	var a := Vector3(mn.x - over, y, mn.z - over); var b := Vector3(mx.x + over, y, mn.z - over)
	var c := Vector3(mx.x + over, y, mx.z + over); var d := Vector3(mn.x - over, y, mx.z + over)
	var top := Vector3((mn.x + mx.x) / 2.0, y + rise, (mn.z + mx.z) / 2.0)
	tri(a, top, b); tri(b, top, c); tri(c, top, d); tri(d, top, a)

func cone(c: Vector3, r: float, h: float, seg: int) -> void:
	var apex := c + Vector3.UP * h
	for i in seg:
		var a0 := i * TAU / seg; var a1 := (i + 1) * TAU / seg
		tri(c + Vector3(cos(a0), 0, sin(a0)) * r, apex, c + Vector3(cos(a1), 0, sin(a1)) * r)

static func _yaw(deg: float) -> Basis:
	var r := deg_to_rad(deg)
	return Basis(Vector3(cos(r), 0, -sin(r)), Vector3.UP, Vector3(sin(r), 0, cos(r)))

## A flat rectangle on the ground, turned by rot_deg about the vertical (clockwise from above).
func flat_rect(c: Vector3, w: float, d: float, rot_deg := 0.0) -> void:
	var q := _yaw(rot_deg)
	quad(c + q * Vector3(-w / 2, 0, -d / 2), c + q * Vector3(-w / 2, 0, d / 2), c + q * Vector3(w / 2, 0, d / 2), c + q * Vector3(w / 2, 0, -d / 2))

## A flat ellipse on the ground.
func disc(c: Vector3, rx: float, rz: float, rot_deg := 0.0, seg := 24) -> void:
	var q := _yaw(rot_deg)
	for i in seg:
		var a0 := i * TAU / seg; var a1 := (i + 1) * TAU / seg
		tri(c, c + q * Vector3(cos(a1) * rx, 0, sin(a1) * rz), c + q * Vector3(cos(a0) * rx, 0, sin(a0) * rz))

## A flat ring (annulus) on the ground.
func ring(c: Vector3, r0: float, r1: float, seg := 40) -> void:
	for i in seg:
		var a0 := i * TAU / seg; var a1 := (i + 1) * TAU / seg
		var d0 := Vector3(cos(a0), 0, sin(a0)); var d1 := Vector3(cos(a1), 0, sin(a1))
		quad(c + d0 * r0, c + d0 * r1, c + d1 * r1, c + d1 * r0)

## A flat ribbon through points (on the ground or in the air), `w` wide.
func ribbon(pts: Array, w: float) -> void:
	for i in pts.size() - 1:
		var a: Vector3 = pts[i]; var b: Vector3 = pts[i + 1]
		var u := b - a; u.y = 0
		if u.length_squared() < 1e-8: continue
		var n := u.normalized().cross(Vector3.UP) * (w / 2.0)
		quad(a - n, a + n, b + n, b - n)

## A box along the ground segment a-b, thickness t, height h (no bottom).
func oriented_box(a: Vector3, b: Vector3, t: float, h: float) -> void:
	var u := b - a; u.y = 0; u = u.normalized()
	var n := u.cross(Vector3.UP) * (t / 2.0)
	var up := Vector3.UP * h
	var a0 := a - n; var a1 := a + n; var b0 := b - n; var b1 := b + n
	quad(a0, a0 + up, b0 + up, b0)
	quad(b1, b1 + up, a1 + up, a1)
	quad(a1, a1 + up, a0 + up, a0)
	quad(b0, b0 + up, b1 + up, b1)
	quad(a0 + up, a1 + up, b1 + up, b0 + up)

## A pitched roof along the segment a-b sitting on height h, width w, ridge rise.
func oriented_gable(a: Vector3, b: Vector3, w: float, h: float, rise: float) -> void:
	var u := b - a; u.y = 0; u = u.normalized()
	var n := u.cross(Vector3.UP) * (w / 2.0)
	var up := Vector3.UP * h; var ridge := Vector3.UP * (h + rise)
	var a0 := a - n + up; var a1 := a + n + up; var b0 := b - n + up; var b1 := b + n + up
	quad(a0, a + ridge, b + ridge, b0)
	quad(b1, b + ridge, a + ridge, a1)
	tri(a1, a + ridge, a0)
	tri(b0, b + ridge, b1)

func arrays() -> Array:
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = _v
	arr[Mesh.ARRAY_NORMAL] = _n
	arr[Mesh.ARRAY_TEX_UV] = _uv
	return arr
