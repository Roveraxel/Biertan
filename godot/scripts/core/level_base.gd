## Base class of every level: its metadata and the helpers levels are laid out with (ground, roads, blocks,
## trees, props, triggers, lights). Coordinates are map pixels, x east and y south, from the top-left corner.
## build() only records what stands where; WorldBuilder turns the records into the 3D world afterwards.
class_name Level
extends Node3D

var id := ""
var title := ""
var subtitle := ""
var size := Vector2(2000, 1400)
var spawn := Vector2.ZERO
var ground := Color("1c2418")
var tile := "tile_grass"
var rng := NetRandom.new(1)

# what build() recorded
var blocks: Array[Dictionary] = []
var trees: Array[Dictionary] = []
var decals: Array[Dictionary] = []
var roads: Array[Dictionary] = []
var cobbles: Array[Rect2] = []
var walls: Array[Dictionary] = []
var curtains: Array[Dictionary] = []
var covered: Array[Dictionary] = []
var exits: Array[Vector2] = []
var props: Array[Prop] = []
var decors: Array[Decor] = []
var cutaways: Array[Dictionary] = []
var solids: StaticBody3D
var built := false
var quest = null            # the quest script this place shares with its village (else the level answers itself)
var spots := {}             # prop id -> where it stands, for quest pointers
var _tick := 0

func _init() -> void:
	solids = StaticBody3D.new()
	solids.name = "Solids"
	solids.collision_layer = 1
	solids.collision_mask = 0
	add_child(solids)

## Create the level's contents. Called once by the loader before the hunter arrives.
func build() -> void: pass
## Called when the hunter has arrived and the world stands.
func on_enter() -> void: pass

func ambient() -> Color:
	return Color(0.95, 0.9, 0.82).lerp(Color(0.12, 0.14, 0.3), clampf(G.dusk, 0.0, 1.0))

func rand(a: float, b: float) -> float:
	return rng.range_f(a, b)

# ------------------------------------------------------------------ quest hooks (a level overrides what it needs)
func talk(_npc: String) -> bool: return false
func use(_p: Prop) -> void: pass
func marker(_npc: String) -> bool: return false
func pending(_p: Prop) -> bool: return false
## [Vector2 where, String label] or [] when the job points nowhere.
func target() -> Array: return []
func objective() -> String: return ""

# ------------------------------------------------------------------ solids

func solid_box(centre: Vector2, sz: Vector2, angle_deg := 0.0, body: StaticBody3D = null) -> CollisionShape3D:
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = Vector3(sz.x * Fx.S, 4.0, sz.y * Fx.S)
	cs.shape = sh
	cs.position = Fx.to3(centre, 2.0)
	cs.rotation.y = deg_to_rad(angle_deg)
	(body if body else solids).add_child(cs)
	return cs

func solid_circle(centre: Vector2, radius: float, body: StaticBody3D = null) -> CollisionShape3D:
	var cs := CollisionShape3D.new()
	var sh := CylinderShape3D.new()
	sh.radius = radius * Fx.S
	sh.height = 4.0
	cs.shape = sh
	cs.position = Fx.to3(centre, 2.0)
	(body if body else solids).add_child(cs)
	return cs

func prop_by_id(pid: String) -> Prop:
	for p in props:
		if is_instance_valid(p) and p.id == pid: return p
	return null

## A walkable route round walls, houses and trees (A* on a 20 px grid over the box spanning both ends).
## Returns the waypoints after `from`, ending at `to`; the straight line if there is no route.
func find_path(from: Vector2, to: Vector2, radius := 8.0, ignore: Node = null, margin := 360.0) -> Array[Vector2]:
	const CELL := 20.0
	var box := Rect2(from, Vector2.ZERO).expand(to).grow(margin)
	var g := AStarGrid2D.new()
	g.region = Rect2i(0, 0, int(box.size.x / CELL) + 1, int(box.size.y / CELL) + 1)
	g.cell_size = Vector2.ONE
	g.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	g.update()
	# stamp each obstacle on the cells it covers (no per-cell scan over every block)
	var stamp := func(c: Vector2, half: Vector2, test: Callable) -> void:
		var lo := Vector2i(((c - half - Vector2.ONE * radius - box.position) / CELL).floor())
		var hi := Vector2i(((c + half + Vector2.ONE * radius - box.position) / CELL).ceil())
		for x in range(maxi(lo.x, 0), mini(hi.x, g.region.size.x - 1) + 1):
			for y in range(maxi(lo.y, 0), mini(hi.y, g.region.size.y - 1) + 1):
				if test.call(box.position + Vector2(x, y) * CELL): g.set_point_solid(Vector2i(x, y))
	for b in blocks:
		if not b.solid: continue
		var r := deg_to_rad(b.angle)
		var up := Vector2(-sin(r), -cos(r)); var rt := Vector2(cos(r), -sin(r))
		var mid: Vector2 = b.c + up * b.size.y / 2.0
		var ext: float = (b.size.x + b.size.y) / 2.0
		if not box.grow(ext).has_point(mid): continue
		stamp.call(mid, Vector2(ext, ext), func(q: Vector2) -> bool:
			var rel: Vector2 = q - mid
			return absf(rel.dot(rt)) < b.size.x / 2.0 + radius and absf(rel.dot(up)) < b.size.y / 2.0 + radius)
	for t in trees:
		var tr: float = 11.0 * t.sc
		if box.grow(tr).has_point(t.p): stamp.call(t.p, Vector2(tr, tr), func(q: Vector2) -> bool: return q.distance_to(t.p) < tr + radius)
	for d in decors:
		if is_instance_valid(d) and d.radius > 0.0 and box.grow(d.radius).has_point(d.pos):
			stamp.call(d.pos, Vector2(d.radius, d.radius), func(q: Vector2) -> bool: return q.distance_to(d.pos) < d.radius + radius)
	for p in props:
		if is_instance_valid(p) and p != ignore and p.visible and box.has_point(p.pos):
			stamp.call(p.pos, Vector2(12, 12), func(q: Vector2) -> bool: return q.distance_to(p.pos) < 12.0 + radius)
	for w in walls:
		stamp.call(w.c, w.size / 2.0, func(q: Vector2) -> bool: return Rect2(w.c - w.size / 2.0, w.size).grow(radius).has_point(q))
	var a := Vector2i(((from - box.position) / CELL).round()); var b := Vector2i(((to - box.position) / CELL).round())
	for e in [a, b]:   # someone standing beside a stall must still be able to step away from it
		for dx in range(-1, 2):
			for dy in range(-1, 2):
				if g.is_in_boundsv(e + Vector2i(dx, dy)): g.set_point_solid(e + Vector2i(dx, dy), false)
	var out: Array[Vector2] = []
	var ids := g.get_id_path(a, b, true)
	if ids.size() < 2: out.append(to); return out
	var prev_d := Vector2i.ZERO
	for i in range(1, ids.size()):   # keep only the corners
		var dd: Vector2i = ids[i] - ids[i - 1]
		if i > 1 and dd != prev_d: out.append(box.position + Vector2(ids[i - 1]) * CELL)
		prev_d = dd
	out.append(to)
	# pull the string: drop a corner when the walk from the last kept point to the next one is clear
	var smooth: Array[Vector2] = []
	var cur := from
	var i := 0
	while i < out.size():
		var j := out.size() - 1
		while j > i and not _clear_grid(g, box, cur, out[j]): j -= 1
		smooth.append(out[j]); cur = out[j]; i = j + 1
	return smooth

func _clear_grid(g: AStarGrid2D, box: Rect2, a: Vector2, b: Vector2) -> bool:
	var n := maxi(1, ceili(a.distance_to(b) / 10.0))
	for k in range(1, n + 1):
		var c := Vector2i(((a.lerp(b, k / float(n)) - box.position) / 20.0).round())
		if g.is_in_boundsv(c) and g.is_point_solid(c): return false
	return true

## Nothing solid within `radius` of the spot (blocks, trees, clutter, people).
func is_free(at: Vector2, radius: float, ignore: Node = null) -> bool:
	for b in blocks:
		if not b.solid: continue
		var r := deg_to_rad(b.angle)
		var up := Vector2(-sin(r), -cos(r))
		var rel: Vector2 = at - (b.c + up * b.size.y / 2.0)
		var lx := rel.dot(Vector2(cos(r), -sin(r))); var ly := rel.dot(up)
		if absf(lx) < b.size.x / 2.0 + radius and absf(ly) < b.size.y / 2.0 + radius: return false
	for t in trees:
		if at.distance_to(t.p) < 11.0 * t.sc + radius: return false
	for d in decors:
		if is_instance_valid(d) and d.radius > 0.0 and at.distance_to(d.pos) < d.radius + radius: return false
	for p in props:
		if is_instance_valid(p) and p != ignore and p.visible and at.distance_to(p.pos) < 12.0 + radius: return false
	for w in walls:
		if Rect2(w.c - w.size / 2.0, w.size).grow(radius).has_point(at): return false
	for cw in curtains:
		for i in cw.pts.size() - 1:
			if dist_to_segment(at, cw.pts[i], cw.pts[i + 1]) < cw.thick / 2.0 + radius: return false
	for b in Brazier.all:
		if at.distance_to(b.pos) < 13.0 + radius: return false
	return true

# ------------------------------------------------------------------ ground

func draw_ground() -> void: pass   # the 3D ground is laid by WorldBuilder from `size`, `tile` and `ground`

## A flat patch of colour on the ground: a rectangle, or a disc (ellipse). `order` stacks patches (higher on top).
func add_decal(disc: bool, centre: Vector2, sz: Vector2, color: Color, order := -900, rot_deg := 0.0) -> void:
	decals.append({"disc": disc, "c": centre, "size": sz, "col": color, "order": order, "rot": rot_deg})

## A patch of textured ground (a mossy ring, a spring meadow): the decal carries a texture set and its tiling.
func add_patch(centre: Vector2, sz: Vector2, set_name: String, tint := Color.WHITE, tile := 1.5, order := -990, disc := true) -> void:
	decals.append({"disc": disc, "c": centre, "size": sz, "col": tint, "order": order, "rot": 0.0, "tex": set_name, "tile": tile})

## A cobbled square.
func add_cobbles(r: Rect2) -> void:
	cobbles.append(r)

## Scatter flattened blots of colour over a rect (grass, moss, dirt).
func scatter(r: Rect2, count: int, colors: Array) -> void:
	for i in count:
		var c: Color = colors[rng.i(colors.size())]
		var s := rand(6.0, 22.0)
		var at := Vector2(rand(r.position.x, r.end.x), rand(r.position.y, r.end.y))
		if s >= 14.0: add_decal(true, at, Vector2(s, s * 0.55), Color(c.r, c.g, c.b, 0.99), -990)   # 0.99: a faint blot, see WorldBuilder

## A thick dirt road (or a cobbled lane) along points.
func add_path(pts: Array, width: float, _color: Color = Color.WHITE, _order := -990, kind := "Path") -> void:
	roads.append({"pts": pts, "width": width, "cobble": kind == "Cobbles"})

# ------------------------------------------------------------------ structures

## A solid structure standing on a rect: wall, house, church, tower, clocktower, ruin, rock, stone, pew, hidden.
func add_block(r: Rect2, style := "wall", h := 18.0) -> Dictionary:
	var b := {"c": Vector2(r.get_center().x, r.end.y), "size": r.size, "h": h, "style": style, "angle": 0.0, "solid": true}
	blocks.append(b)
	b.shape = solid_box(r.get_center(), r.size)
	return b

## A block turned to follow its street: angle in degrees counter-clockwise as seen on the map.
func add_block_rotated(centre: Vector2, sz: Vector2, angle_deg: float, style: String, h: float, solid := true) -> Dictionary:
	var r := deg_to_rad(angle_deg)
	var up := Vector2(-sin(r), -cos(r))
	var b := {"c": centre - up * sz.y / 2.0, "size": sz, "h": h, "style": style, "angle": angle_deg, "solid": solid}
	blocks.append(b)
	if solid: b.shape = solid_box(centre, sz, angle_deg)
	return b

## A doorway in the front (camera-side) wall of the nearest house near `near`: where a cellar door goes, so it
## is built into a building instead of standing on its own in the grass. ok(p) can rule spots out.
func wall_door(near: Vector2, reach := 1200.0, ok := Callable()) -> Vector2:
	var best := near; var bd := INF
	for b in blocks:
		if not b.get("solid", false) or not (b.style in ["house", "barn", "tower", "church", "clocktower", "store"]): continue
		if b.size.x < 90.0 or b.h < 30.0: continue
		var r := deg_to_rad(b.angle)
		var n := Vector2(sin(r), cos(r))   # the front face's outward side
		if n.y < 0.6: continue
		var p: Vector2 = b.c + n * 6.0
		var d := p.distance_to(near)
		if d > reach or d >= bd: continue
		if ok.is_valid() and not ok.call(p): continue
		if not is_free(p + n * 40.0, 22.0): continue
		bd = d; best = p
	return best

## A stone tower with a cellar hatch in front of it, on free ground near `near` (inside `ok`). Returns where the hunter
## stands to use the doors, at the foot of its front.
func cellar_tower(near: Vector2, reach := 700.0, ok := Callable()) -> Vector2:
	var size := 240.0
	var best := Vector2.INF
	var r := 0.0
	while r <= reach and best == Vector2.INF:
		var n := maxi(1, int(r / 45.0) * 2)
		for i in n:
			var a := TAU * i / float(n)
			var p := near + Vector2(cos(a), sin(a)) * r
			if ok.is_valid() and not ok.call(p): continue
			if not is_free(p, size * 0.5 + 40.0) or not is_free(p + Vector2(0, 220), 130.0): continue
			best = p
			break
		r += 50.0
	if best == Vector2.INF: best = near
	add_block(Rect2(best - Vector2(size, size) * 0.5, Vector2(size, size)), "cellartower", 64.0)
	var hb := add_block(Rect2(best + Vector2(-100, size * 0.5 + 12), Vector2(200, 170)), "cellarhatch", 28.0)
	return hb.c + Vector2(0, 26)

## Where no house stands close enough: a low stone cellar head built over the stair, its door facing the camera.
## `at` is the foot of the door; the little building rises behind it.
func cellar_head(at: Vector2) -> void:
	var w := 120.0; var d := 90.0
	solid_box(at + Vector2(0, -d / 2.0 - 4.0), Vector2(w, d))
	var b := Batch.new()
	var o := Fx.to3(at)
	var hw := w * Fx.S / 2.0; var dd := d * Fx.S
	var st := b.mb(Mats.stone())
	st.box(o + Vector3(-hw, 0, -dd), o + Vector3(hw, 1.5, 0.0), true)
	var rf := b.mb(Mats.roof())
	rf.box(o + Vector3(-hw - 0.15, 1.5, -dd - 0.15), o + Vector3(hw + 0.15, 1.62, 0.2), true)
	rf.box(o + Vector3(-hw + 0.2, 1.62, -dd + 0.15), o + Vector3(hw - 0.2, 1.85, -0.1), true)
	b.commit(self, "Cellar head")

## A wooden gate across the road nearest `near`, square to it and as wide as it.
func road_gate(near: Vector2, label := "Gate") -> WoodGate:
	var best_q := near; var best_dir := Vector2.RIGHT; var best_w := 160.0; var bd := INF
	for r in roads:
		var pts: Array = r.pts
		for i in pts.size() - 1:
			var a: Vector2 = pts[i]; var b: Vector2 = pts[i + 1]
			var q := Geometry2D.get_closest_point_to_segment(near, a, b)
			if q.distance_to(near) < bd and a.distance_to(b) > 1.0:
				bd = q.distance_to(near); best_q = q; best_dir = (b - a).normalized(); best_w = r.width
	var across := best_dir.orthogonal()
	return WoodGate.make(self, best_q, best_w + 70.0, rad_to_deg(-across.angle()), label)

## A wooden gate in the gap between two yard walls near `near` (the way into a yard).
func gap_gate(near: Vector2, reach := 500.0, label := "Yard gate") -> WoodGate:
	var ends: Array = []   # [point, block index]
	for i in blocks.size():
		var b: Dictionary = blocks[i]
		if b.style != "wall" or b.size.x > 900.0: continue
		var r := deg_to_rad(b.angle)
		var up := Vector2(-sin(r), -cos(r)); var along := Vector2(cos(r), -sin(r))
		var mid: Vector2 = b.c + up * b.size.y / 2.0
		for sg in [-1.0, 1.0]: ends.append([mid + along * sg * b.size.x / 2.0, i])
	for j in curtains.size():   # yard walls are drawn as curtains: their two loose ends
		var pts: Array = curtains[j].pts
		if pts.size() < 2 or curtains[j].thick > 30.0: continue
		ends.append([pts[0], 10000 + j]); ends.append([pts[pts.size() - 1], 10000 + j])
	var best := []; var bd := INF
	for x in ends:
		if x[0].distance_to(near) > reach: continue
		for y in ends:
			if y[1] == x[1]: continue
			var gap: float = x[0].distance_to(y[0])
			if gap < 90.0 or gap > 300.0: continue
			var score: float = ((x[0] + y[0]) / 2.0).distance_to(near) + gap * 0.3
			if score < bd: bd = score; best = [x[0], y[0]]
	if best.is_empty(): return null
	var dv: Vector2 = best[1] - best[0]
	return WoodGate.make(self, (best[0] + best[1]) / 2.0, dv.length(), rad_to_deg(-dv.angle()), label)

## A solid straight wall; invisible unless a colour is given.
func add_wall(centre: Vector2, sz: Vector2, color = null) -> void:
	solid_box(centre, sz)
	if color != null: walls.append({"c": centre, "size": sz})

## A circle of invisible wall keeping a fight inside an arena.
func add_ring_wall(centre: Vector2, radius: float, segments := 48) -> void:
	var seg := TAU * radius / segments * 1.15
	for i in segments:
		var a := i * TAU / segments
		solid_box(centre + Vector2(cos(a), sin(a)) * (radius + 20.0), Vector2(40.0, seg), -rad_to_deg(a))

## A fortification wall along a polyline (Biertan's curved rings). style: ring, arches, gallery.
func add_curtain(pts: Array, thick := 34.0, h := 40.0, style := "ring") -> void:
	var cu := {"pts": pts, "thick": thick, "h": h, "style": style, "shapes": []}
	curtains.append(cu)
	_curtain_shapes(cu)

func _curtain_shapes(cu: Dictionary) -> void:
	var pts: Array = cu.pts; var thick: float = cu.thick
	for i in pts.size() - 1:
		var a: Vector2 = pts[i]; var b: Vector2 = pts[i + 1]
		if a.distance_to(b) < 1.0: continue
		cu.shapes.append(solid_box((a + b) / 2.0, Vector2(a.distance_to(b) + thick * 0.7, thick), -rad_to_deg((b - a).angle())))

## A roofed passage over a rect, or along a line when `width` is given.
func add_covered_way(r: Rect2, a := Vector2.ZERO, b := Vector2.ZERO, width := 0.0) -> void:
	covered.append({"rect": r, "a": a, "b": b, "width": width})

## A leafy tree in autumn colours, or a dark spruce.
func add_tree(at: Vector2, pine := false) -> void:
	rng.i(3)   # the old 2D palette pick: kept so every later roll lands where it did
	var sc := rand(0.85, 1.25)
	trees.append({"p": at, "pine": pine, "sc": sc})
	solid_circle(at, 11.0 * sc)

# ------------------------------------------------------------------ things in the world

func add_prop(kind: String, prop_id: String, display: String, at: Vector2, prompt := "", col := Color("a05030")) -> Prop:
	var p := Prop.new()
	p.kind = kind; p.id = prop_id; p.display = display; p.prompt = prompt; p.col = col
	p.name = "Prop %s %s" % [kind, prop_id]
	add_child(p)
	p.pos = at
	p.setup()
	props.append(p)
	spots[prop_id] = at
	return p

## Street clutter: a pixel-art sprite standing in the world; `radius` > 0 makes it solid.
func add_decor(at: Vector2, sprite: String, radius := 0.0, flip := false) -> Decor:
	var d := Decor.new()
	d.name = "Decor " + sprite
	add_child(d)
	d.setup(at, sprite, radius, flip)
	decors.append(d)
	return d

func remove_block(b: Dictionary) -> void:
	blocks.erase(b)
	if b.has("shape") and is_instance_valid(b.shape): b.shape.queue_free()
	if b.has("node") and is_instance_valid(b.node): b.node.queue_free()

func remove_prop(p: Prop) -> void:
	props.erase(p)
	if is_instance_valid(p): p.queue_free()

func remove_decor(d: Decor) -> void:
	decors.erase(d)
	if is_instance_valid(d): d.queue_free()

## Fires every time the hunter walks into the rect.
func add_trigger(r: Rect2, on_enter_cb: Callable) -> Area3D:
	var a := Area3D.new()
	a.collision_layer = 0
	a.collision_mask = 2
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = Vector3(r.size.x * Fx.S, 4.0, r.size.y * Fx.S)
	cs.shape = sh
	a.add_child(cs)
	add_child(a)
	a.position = Fx.to3(r.get_center(), 2.0)
	a.body_entered.connect(func(body): if body == G.player and G.state == G.State.PLAY and not G.transitioning: on_enter_cb.call_deferred())
	exits.append(r.get_center())
	return a

func add_brazier(at: Vector2, lit := true) -> Brazier:
	var b := Brazier.new()
	add_child(b)
	b.setup(at, lit)
	return b

## A flickering point light with no visible source.
func add_torch(at: Vector2, radius := 240.0, col := Color(1, 0.86, 0.68), energy := 0.95) -> OmniLight3D:
	if id in Mats.BRICK_LEVELS or id in Mats.SALT_LEVELS: col = col.lerp(Color(0.96, 0.9, 0.82), 0.6)   # underground: a soft lamp glow, easy on the eyes
	var l := Fx.add_light(self, at, radius, col, energy)
	l.set_meta("flicker", randf() * 10.0)
	return l

func spawn_enemy(kind: String, at: Vector2, script: GDScript = null) -> Enemy:
	var e: Enemy = script.new() if script else Enemy.new()
	add_child(e)
	e.pos = at
	e.setup(kind)
	e.apply_difficulty(G.difficulty())
	return e

static func dist_to_segment(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var k := clampf((p - a).dot(ab) / maxf(0.0001, ab.length_squared()), 0.0, 1.0)
	return p.distance_to(a + ab * k)

# ------------------------------------------------------------------ per frame

func _process(_dt: float) -> void:
	if not built or not is_instance_valid(G.player): return
	_tick += 1
	var t := Time.get_ticks_msec() / 1000.0
	for l in Fx.lights:
		if l.has_meta("flicker"):
			var s: float = l.get_meta("flicker")
			Fx.set_light(l, l.get_meta("base") + 0.12 * sin((t + s) * 11.0) + 0.07 * sin((t + s) * 23.0))
	# walls and houses between the camera and the hunter turn see-through so he stays visible
	var pp: Vector3 = G.player.global_position
	for c in cutaways:
		var ctr: Vector3 = c.centre
		var front: bool = ctr.z > pp.z + 0.2 and ctr.z - pp.z < c.half_d + 4.5 and absf(ctr.x - pp.x) < c.half_w + 0.8
		if front != c.faded:
			c.faded = front
			var mi: MeshInstance3D = c.node
			for i in mi.mesh.get_surface_count():
				var base: Material = c.base[i] if c.has("base") else mi.mesh.surface_get_material(i)
				mi.set_surface_override_material(i, Mats.see_through(base) if front else (base if c.has("base") else null))
			if c.has("caster"): c.caster.visible = not front   # a model's shadow comes from its plain box
			else: mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF if front else GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	# a covered way's roof lifts away while he is under it
	var p2: Vector2 = G.player.pos
	for cw in covered:
		if not cw.has("roof"): continue
		if cw.width > 0.0: cw.roof.visible = dist_to_segment(p2, cw.a, cw.b) > cw.width / 2.0 + 20.0
		else: cw.roof.visible = not cw.rect.has_point(p2)
