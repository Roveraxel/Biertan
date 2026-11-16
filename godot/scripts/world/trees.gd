## Procedural low-poly trees: autumn beeches and oaks with a bent trunk and lumpy leaf clumps, Carpathian
## spruces with ragged drooping skirts, and in the deep woods some dead ones. Seeded from the tree's position.
## `p` is a Dictionary of MeshBuilders: bark, leaves, leaves2, ground, stone.
class_name Trees
extends RefCounted

const AUTUMN := [Color(0.13, 0.19, 0.11), Color(0.2, 0.23, 0.11), Color(0.34, 0.25, 0.1), Color(0.33, 0.16, 0.08), Color(0.29, 0.26, 0.11), Color(0.16, 0.21, 0.13)]
const ICO_F := [0,11,5, 0,5,1, 0,1,7, 0,7,10, 0,10,11, 1,5,9, 5,11,4, 11,10,2, 10,7,6, 7,1,8, 3,9,4, 3,4,2, 3,2,6, 3,6,8, 3,8,9, 4,9,5, 2,4,11, 6,2,10, 8,6,7, 9,8,1]

static var _ico0: Array[Vector3] = []
static var _ico_v: Array[Vector3] = []
static var _ico_t: Array[int] = []

## One tree, one family of colours: the second clump colour is a near shade of the first, so a crown reads as a
## single tree and not as two patches. Most are green; a few turn ochre or rust for the autumn.
const CROWNS := [Color(0.2, 0.31, 0.14), Color(0.24, 0.36, 0.16), Color(0.27, 0.38, 0.17), Color(0.22, 0.33, 0.15), Color(0.3, 0.37, 0.15), Color(0.25, 0.35, 0.18), Color(0.5, 0.36, 0.13), Color(0.46, 0.22, 0.11)]
## Spruce needles: a dark green with a near shade, no longer blue-green.
const SPRUCE_A := Color(0.08, 0.17, 0.09)
const SPRUCE_B := Color(0.1, 0.2, 0.11)
static func leaf_color(seed_value: int, k: int) -> Color:
	var i := absi(seed_value) % 11   # eight crowns, the first six twice as likely as the autumn two
	var base: Color = CROWNS[mini(i, 7) if i < 8 else i - 8] * 0.6
	base.a = 1.0
	return base if k == 0 else base.lerp(Color(0.3, 0.32, 0.12), 0.25)

static func _ico() -> void:
	if not _ico_v.is_empty(): return
	var t := (1.0 + sqrt(5.0)) / 2.0
	var v: Array[Vector3] = [Vector3(-1, t, 0), Vector3(1, t, 0), Vector3(-1, -t, 0), Vector3(1, -t, 0), Vector3(0, -1, t), Vector3(0, 1, t), Vector3(0, -1, -t), Vector3(0, 1, -t), Vector3(t, 0, -1), Vector3(t, 0, 1), Vector3(-t, 0, -1), Vector3(-t, 0, 1)]
	for p in v: _ico0.append(p.normalized())
	var mid := {}
	var nf: Array[int] = []
	var get_mid := func(a: int, b: int) -> int:
		var key := Vector2i(mini(a, b), maxi(a, b))
		if mid.has(key): return mid[key]
		v.append((v[a] + v[b]) / 2.0)
		mid[key] = v.size() - 1
		return v.size() - 1
	for i in range(0, ICO_F.size(), 3):
		var a: int = ICO_F[i]; var b: int = ICO_F[i + 1]; var c: int = ICO_F[i + 2]
		var ab: int = get_mid.call(a, b); var bc: int = get_mid.call(b, c); var ca: int = get_mid.call(c, a)
		nf.append_array([a, ab, ca, b, bc, ab, c, ca, bc, ab, bc, ca])
	for p in v: _ico_v.append(p.normalized())
	_ico_t = nf

## A tapering many-sided limb from a to b.
static func limb(mb: MeshBuilder, a: Vector3, b: Vector3, ra: float, rb: float, sides := 6) -> void:
	var dir := (b - a).normalized()
	var u := dir.cross(Vector3.RIGHT if absf(dir.y) > 0.9 else Vector3.UP).normalized()
	var w := dir.cross(u)
	for i in sides:
		var t0 := i * TAU / sides; var t1 := (i + 1) * TAU / sides
		var o0 := u * cos(t0) + w * sin(t0); var o1 := u * cos(t1) + w * sin(t1)
		mb.quad(a + o0 * ra, a + o1 * ra, b + o1 * rb, b + o0 * rb)

## A lumpy, roughed-up ball of leaves (or a stone), flattened underneath.
static func clump(mb: MeshBuilder, c: Vector3, size: Vector3, rnd: NetRandom, rough := 0.2, flat_bottom := 0.55, smooth := false) -> void:
	_ico()
	var pts: Array[Vector3] = []
	for p in _ico_v:
		var k := 1.0 + (rnd.f() * 2.0 - 1.0) * rough
		var q := p * k * size
		if q.y < -size.y * flat_bottom: q.y = -size.y * flat_bottom
		pts.append(c + q)
	for i in range(0, _ico_t.size(), 3):
		var ia := _ico_t[i]; var ib := _ico_t[i + 1]; var ic := _ico_t[i + 2]
		if smooth:
			var lift := Vector3.UP * 0.35
			mb.tri_smooth(pts[ia], pts[ib], pts[ic], (_ico_v[ia] + lift).normalized(), (_ico_v[ib] + lift).normalized(), (_ico_v[ic] + lift).normalized())
		else:
			mb.tri(pts[ia], pts[ib], pts[ic])

## Small leaf tufts poking out of a clump's skin, so its outline breaks up like real foliage.
static func tufts(mb: MeshBuilder, c: Vector3, size: Vector3, rnd: NetRandom, count: int) -> void:
	_ico()
	for _k in count:
		var ang := rnd.f() * TAU; var el := (rnd.f() - 0.25) * 1.2
		var dir := Vector3(cos(ang) * cos(el), sin(el), sin(ang) * cos(el))
		var at := c + dir * size * 0.95
		var r := size.x * (0.22 + rnd.f() * 0.14)
		var lift := dir + Vector3.UP * 0.4
		for i in range(0, ICO_F.size(), 3):
			var a := _ico0[ICO_F[i]]; var b := _ico0[ICO_F[i + 1]]; var d := _ico0[ICO_F[i + 2]]
			mb.tri_smooth(at + a * r, at + b * r, at + d * r, (a + lift).normalized(), (b + lift).normalized(), (d + lift).normalized())

## A broadleaf (beech, oak) in autumn, or a dead one with bare grey limbs.
static func broadleaf(p: Dictionary, at: Vector3, sc: float, rnd: NetRandom, dead: bool, low := false) -> void:
	var h := (2.1 + rnd.f() * 0.6) * sc
	var lean := Vector3(rnd.f() - 0.5, 0.0, rnd.f() - 0.5) * 0.5 * sc
	var a := at; var b := at + Vector3(0, h * 0.45, 0) + lean * 0.4; var top := at + Vector3(0, h, 0) + lean
	var r0 := 0.2 * sc
	limb(p.bark, a + Vector3.DOWN * 0.1, b, r0 * 1.25, r0 * 0.85, 7)
	limb(p.bark, b, top, r0 * 0.85, r0 * 0.45, 7)
	for i in (0 if low else 4):
		var ang := i * PI / 2.0 + rnd.f()
		var d := Vector3(cos(ang), 0, sin(ang))
		limb(p.bark, a + Vector3.UP * 0.35 * sc, a + d * 0.5 * sc + Vector3.DOWN * 0.05, r0 * 0.45, r0 * 0.12, 5)
	var limbs := 6 if dead else (3 if low else 4)
	var ends: Array[Vector3] = [top]
	for i in limbs:
		var ang := i * TAU / limbs + rnd.f() * 0.8
		var up := 0.45 + rnd.f() * 0.5
		var start := b.lerp(top, 0.25 + rnd.f() * 0.6)
		var dir := Vector3(cos(ang), up, sin(ang)).normalized()
		var length := (0.75 + rnd.f() * 0.45) * sc
		var end := start + dir * length
		limb(p.bark, start, end, r0 * 0.4, r0 * 0.12, 5)
		if dead:
			var tw := end + (dir + Vector3(rnd.f() - 0.5, 0.3, rnd.f() - 0.5)).normalized() * 0.5 * sc
			limb(p.bark, end, tw, r0 * 0.12, r0 * 0.04, 4)
		ends.append(end)
	if dead: return
	for i in ends.size():
		var s := (0.9 if i == 0 else 0.58 + rnd.f() * 0.22) * sc
		var size := Vector3(s, s * 0.72, s)
		var cc := ends[i] + Vector3.UP * 0.12 * sc
		var mbl: MeshBuilder = p.leaves2 if i % 3 == 1 else p.leaves
		clump(mbl, cc, size, rnd, 0.28, 0.5, true)
		if not low: tufts(mbl, cc, size, rnd, 7)

## A Carpathian spruce: a straight dark trunk under ragged tiers of drooping boughs.
static func spruce(p: Dictionary, at: Vector3, sc: float, rnd: NetRandom, low := false) -> void:
	var h := (4.2 + rnd.f() * 1.4) * sc
	limb(p.bark, at + Vector3.DOWN * 0.1, at + Vector3.UP * h * 0.85, 0.16 * sc, 0.05 * sc, 6)
	var tiers := 4 if low else 6
	for i in tiers:
		var k := i / float(tiers - 1)
		var y := lerpf(0.8, h * 0.88, k)
		var r := lerpf(1.55, 0.35, k) * sc
		var tier_h := lerpf(1.15, 0.8, k) * sc
		var c := at + Vector3.UP * y
		var apex := c + Vector3.UP * tier_h
		var seg := 8 if low else 12
		var twist := rnd.f() * PI
		var mb: MeshBuilder = p.leaves if i % 2 == 0 else p.leaves2
		var rim: Array[Vector3] = []
		for j in seg:
			var ang := twist + j * TAU / seg
			var rr := r * (1.0 if j % 2 == 0 else 0.72) * (0.9 + rnd.f() * 0.2)
			var droop := -0.28 * sc if j % 2 == 0 else 0.02
			rim.append(c + Vector3(cos(ang) * rr, droop, sin(ang) * rr))
		var inner := c + Vector3.UP * tier_h * 0.2
		for j in seg:
			var q0 := rim[j]; var q1 := rim[(j + 1) % seg]
			mb.tri(q0, q1, apex)
			if not low: mb.tri(q0, q1, inner)

## Ferns, grass and the odd stone around a tree's feet.
static func undergrowth(p: Dictionary, at: Vector3, sc: float, rnd: NetRandom) -> void:
	var n := 3 + rnd.i(4)
	for _i in n:
		var ang := rnd.f() * TAU
		var dist := (0.7 + rnd.f() * 1.1) * sc
		var c := at + Vector3(cos(ang) * dist, 0.0, sin(ang) * dist)
		var blades := 5 + rnd.i(4)
		var bh := 0.25 + rnd.f() * 0.3
		for j in blades:
			var ba := j * TAU / blades + rnd.f() * 0.4
			var d := Vector3(cos(ba), 0, sin(ba))
			var side := d.cross(Vector3.UP) * 0.05
			p.ground.tri(c - side, c + d * bh * 0.9 + Vector3.UP * bh, c + side)
	if rnd.f() < 0.35:
		var ang := rnd.f() * TAU
		var c := at + Vector3(cos(ang), 0.0, sin(ang)) * (1.0 + rnd.f()) * sc
		var s := 0.18 + rnd.f() * 0.22
		clump(p.stone, c, Vector3(s * 1.3, s * 0.7, s), rnd, 0.25, 0.3)
