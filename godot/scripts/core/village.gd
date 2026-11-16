## A village laid out from its real map. Holds what every village needs when it places things: is this spot
## on a street, inside a house, against a wall; find me a free spot near here; split a street row into houses.
class_name Village
extends Level

var m: MapData
var compact_k := 0.8   # the whole village drawn this much smaller than the survey (walk less, see more)
var trim_k := 0.15     # and this share of its outermost houses left out
var building_sets: Array = []   # [[boxes, extra padding]]: what near_building looks at
var wall_lines: Array = []      # polylines near_wall looks at
var road_min_half := 30.0       # narrower ways (footpaths, steps) may squeeze between houses
var free_r1 := 600.0            # how far free_spot looks
var arrive_flag := ""           # set: the quest's arrive() scene plays once, when the fade-in has finished
var _arrive_t := 0.0
var _street_samples: Array = []

func load_map(map_id: String) -> void:
	m = MapData.new(map_id)
	size = m.size

## The farm villages of the road are all laid out the same way from their maps.
func standard(map_id: String, seed_value: int) -> void:
	load_map(map_id)
	ground = Color("2a3224")
	tile = "tile_grass_village"
	rng = NetRandom.new(seed_value)
	road_min_half = 40.0
	free_r1 = 800.0
	building_sets = [[m.boxes("houses"), 0.0], [m.boxes("churches"), 40.0]]
	wall_lines = m.lines("yardwalls")
	scatter(Rect2(Vector2.ZERO, size), 360, [Color("363e2a"), Color("2a2e22"), Color("444230")])
	lay_roads()

## The usual run of a surveyed village: churches with a tower on the big one, and the houses.
func churches_and_houses() -> void:
	for c in m.boxes("churches"): add_church(c, 78.0 if c.area > 250.0 else 56.0, c.area > 250.0, 0.75, 190.0)
	add_houses(44.0, 60.0, true)

## Graves, the scattered trees, then (after the level's own things) call finish().
func graves_and_trees() -> void:
	add_graves(90, 80.0, 100.0, false)
	plant_trees(400.0, 280.0, 0.55, 80.0, spawn)

func finish() -> void:
	edge_walls()
	plant_gardens(9001, garden_ok)

## Streets wide enough for a cart are cobbled, the rest are dirt lanes; brooks run as paths too.
func lay_roads() -> void:
	var roads := m.lines("roads")
	for i in roads.size():
		var w: float = m.road_width[i]
		add_path(roads[i], w, Color.WHITE, -990, "Cobbles" if w >= 140.0 else "Path")
	for s in m.lines("streams"): add_path(s, 50.0)

## Every surveyed house, shrunk until the street in front of it stays open (or left out if it never does).
func add_houses(base_h: float, barn_h: float, no_overlap := false) -> void:
	for b in m.boxes("houses"):
		var sz: Vector2 = b.size
		var tries := 0
		while tries < 3 and blocks_street(b.c, sz, b.angle):
			sz *= 0.8; tries += 1
		if blocks_street(b.c, sz, b.angle): continue
		if no_overlap and blocked(b.c, minf(sz.x, sz.y) * 0.45): continue   # drawn closer together than in life
		add_block_rotated(b.c, sz, b.angle, "house", barn_h if b.style == "barn" else base_h + rng.f() * 12.0)

## The low yard walls that join house to house along the street.
func add_yard_walls() -> void:
	for w in m.lines("yardwalls"):
		if w.size() > 1: add_curtain(w, 16.0, 18.0, "ring")

## Trees on a jittered grid: thick in the surveyed woods, thinned elsewhere, never on streets or against houses.
func plant_trees(step: float, jitter: float, thin: float, wall_pad: float, keep_clear: Vector2, limit := 220) -> void:
	var n := 0
	var x := 120.0
	while x < size.x - 120.0:
		var y := 120.0
		while y < size.y - 120.0:
			if n >= limit: return
			var p := Vector2(x + (rng.f() - 0.5) * jitter, y + (rng.f() - 0.5) * jitter)
			y += step
			var wood := false
			for w in m.lines("woods"):
				if inside(p, w):
					wood = true
					break
			if not wood and rng.f() < thin: continue
			if near_road(p, 70.0) or near_building(p, 90.0) or near_wall(p, wall_pad): continue
			if p.distance_to(keep_clear) < 300.0: continue
			add_tree(p, wood and rng.f() < 0.3)
			n += 1
		x += step

## Long farmsteads, gable to the street, along both sides of the cart roads.
func add_farms() -> void:
	var v := m.village
	var church: Vector2 = m.boxes("churches")[0].c
	var roads := m.lines("roads")
	var n := 0
	for i in roads.size():
		if n >= 70: break
		if m.road_width[i] < 120.0: continue
		var r: Array = roads[i]
		for k in r.size() - 1:
			if n >= 70: break
			var a: Vector2 = r[k]; var b: Vector2 = r[k + 1]
			var length := a.distance_to(b)
			if length < 1.0: continue
			var dir := (b - a) / length; var nrm := Vector2(-dir.y, dir.x)
			var ang := -rad_to_deg(atan2(dir.y, dir.x))
			var s := 150.0
			while s < length and n < 70:
				for side in [-1.0, 1.0]:
					var p: Vector2 = a + dir * s + nrm * side * (m.road_width[i] / 2.0 + 190.0)
					if not v.has_point(p) or p.distance_to(church) < 900.0: continue
					if blocked(p, 200.0) or near_road(p, 120.0): continue
					add_block_rotated(p, Vector2(200, 300), ang, "house", 44.0 + rng.f() * 12.0)
					n += 1
					if n >= 70: break
				s += 360.0

## The surveyed road point nearest a spot, nudged clear of anything solid.
func nearest_road_point(g: Vector2) -> Vector2:
	var best := g; var bd := INF
	for r in m.lines("roads"):
		for p in r:
			if g.distance_to(p) < bd:
				bd = g.distance_to(p); best = p
	return free_spot(best, 40.0)

## The surveyed house nearest a spot.
func nearest_house(g: Vector2) -> Dictionary:
	var best: Dictionary = m.boxes("houses")[0]; var bd := INF
	for b in m.boxes("houses"):
		if g.distance_to(b.c) < bd:
			bd = g.distance_to(b.c); best = b
	return best

static func centre(poly: Array) -> Vector2:
	var c := Vector2.ZERO
	for p in poly: c += p
	return c / poly.size()

## The heart of the village: the main road nearest the middle of its houses (where the troiță and market go).
func centre_spot() -> Vector2:
	var c := Vector2.ZERO; var n := 0
	for b in m.boxes("houses"): c += b.c; n += 1
	if n == 0: return spawn
	return free_spot(nearest_road_point(c / n) + Vector2(90, 40), 40.0)

## A spot by a road near c with the most room round it: away from the stalls, carts and villagers already placed.
func quiet_spot(c: Vector2, reach := 900.0) -> Vector2:
	var best := c; var best_d := -1.0
	for k in 60:
		var a := k * 2.39996
		var p := nearest_road_point(c + Vector2(cos(a), sin(a)) * reach * sqrt((k + 1) / 60.0)) + Vector2(90, 40)
		if not is_free(p, 50.0, null): continue
		var md := 1e9
		for q in props: md = minf(md, q.pos.distance_to(p))
		for dc in decors: md = minf(md, dc.pos.distance_to(p) + (0.0 if dc.radius > 0.0 else 120.0))   # flowers and grass do not count much
		md -= p.distance_to(c) * 0.15   # but still near the middle
		if md > best_d: best_d = md; best = p
	return best

## A troiță in the middle of the village: with Lorena's map, roads to anywhere he has been.
func add_troita(at: Vector2) -> void:
	add_decor(at, "troita", 22.0)
	add_prop("troita", "troita", "Troiță", at + Vector2(0, 30), "E   Pray at the troiță")

func _process(dt: float) -> void:
	super(dt)
	if arrive_flag == "" or G.side_has(arrive_flag) or G.state != G.State.PLAY or G.transitioning:
		_arrive_t = 0.0
		return
	_arrive_t += dt
	if _arrive_t > 0.6: quest.arrive()

# ------------------------------------------------------------------ geometry

## Is p inside the (turned) box, grown by margin?
static func in_box(p: Vector2, b: Dictionary, margin: float) -> bool:
	var r := -deg_to_rad(b.angle)
	var d: Vector2 = p - b.c
	var lx := d.x * cos(r) + d.y * sin(r)
	var ly := -d.x * sin(r) + d.y * cos(r)
	return absf(lx) < b.size.x / 2.0 + margin and absf(ly) < b.size.y / 2.0 + margin

static func inside(p: Vector2, poly: Array) -> bool:
	var c := false
	var j := poly.size() - 1
	for i in poly.size():
		if (poly[i].y > p.y) != (poly[j].y > p.y) and p.x < (poly[j].x - poly[i].x) * (p.y - poly[i].y) / (poly[j].y - poly[i].y) + poly[i].x: c = not c
		j = i
	return c

static func bounds(poly: Array) -> Rect2:
	var r := Rect2(poly[0], Vector2.ZERO)
	for p in poly: r = r.expand(p)
	return r

static func seg_dist(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var l := ab.length_squared()
	if l < 0.0001: return p.distance_to(a)
	return p.distance_to(a + ab * clampf((p - a).dot(ab) / l, 0.0, 1.0))

static func near_lines(p: Vector2, lines: Array, pad: float) -> bool:
	for w in lines:
		for k in w.size() - 1:
			if seg_dist(p, w[k], w[k + 1]) < pad: return true
	return false

func near_road(p: Vector2, pad: float) -> bool:
	var roads := m.lines("roads")
	for i in roads.size():
		var r: Array = roads[i]
		var lim: float = m.road_width[i] / 2.0 + pad
		for k in r.size() - 1:
			if seg_dist(p, r[k], r[k + 1]) < lim: return true
	return false

func near_building(p: Vector2, pad: float) -> bool:
	for bs in building_sets:
		for b in bs[0]:
			if in_box(p, b, pad + bs[1]): return true
	return false

func near_wall(p: Vector2, pad: float) -> bool:
	return near_lines(p, wall_lines, pad)

## Anything solid already built (a house piece, a tower, a cart) within r of the point.
func blocked(g: Vector2, r: float) -> bool:
	return not is_free(g, maxf(r, 30.0))

## Nothing solid along the straight walk from a to b.
func line_clear(a: Vector2, b: Vector2, r := 18.0) -> bool:
	var n := maxi(1, ceili(a.distance_to(b) / 20.0))
	for i in range(1, n + 1):
		if not is_free(a.lerp(b, i / float(n)), r): return false
	return true

## True when a house box would stand on a street: points every 30 px along each street, padded by most of the
## street's half-width, must stay outside it.
func blocks_street(c: Vector2, sz: Vector2, angle: float, pad_k := 0.85) -> bool:
	if _street_samples.is_empty():
		var roads := m.lines("roads")
		for i in roads.size():
			var half: float = m.road_width[i] / 2.0
			if half < road_min_half: continue
			var r: Array = roads[i]
			for k in r.size() - 1:
				var n := maxi(1, ceili(r[k].distance_to(r[k + 1]) / 30.0))
				for j in n + 1: _street_samples.append([r[k].lerp(r[k + 1], j / float(n)), half])
	var box := {"c": c, "size": sz, "angle": angle}
	var reach := maxf(sz.x, sz.y)
	for s in _street_samples:
		var p: Vector2 = s[0]
		if absf(p.x - c.x) > reach or absf(p.y - c.y) > reach: continue
		if in_box(p, box, s[1] * pad_k): return true
	return false

## What else a free spot must satisfy in this village (stay off the wall, inside the map...).
func free_ok(p: Vector2, _from: Vector2) -> bool:
	return not near_wall(p, 40.0) and p.x > 80.0 and p.y > 80.0 and p.x < size.x - 80.0 and p.y < size.y - 80.0

## A spot nudged out of any house or wall, so people and clues stand in the open.
func free_spot(g: Vector2, clear := 18.0, r0 := 40.0, r1 := -1.0, dr := 40.0, spokes := 12) -> Vector2:
	if r1 < 0.0: r1 = free_r1
	var ok := func(p: Vector2) -> bool: return not blocked(p, clear) and not near_building(p, clear) and free_ok(p, g)
	if ok.call(g): return g
	var r := r0
	while r <= r1:
		for k in spokes:
			var a := k * TAU / spokes
			var p := g + Vector2(cos(a), sin(a)) * r
			if ok.call(p): return p
		r += dr
	return g

## The four invisible walls round the map.
func edge_walls() -> void:
	add_wall(Vector2(size.x / 2.0, -20), Vector2(size.x, 40))
	add_wall(Vector2(size.x / 2.0, size.y + 20), Vector2(size.x, 40))
	add_wall(Vector2(-20, size.y / 2.0), Vector2(40, size.y))
	add_wall(Vector2(size.x + 20, size.y / 2.0), Vector2(40, size.y))

## The long axis of a building box as a map direction, and its length and width.
static func long_axis(b: Dictionary) -> Array:
	var r := deg_to_rad(b.angle)
	var long_x: bool = b.size.x >= b.size.y
	var axis := Vector2(cos(r), -sin(r)) if long_x else Vector2(sin(r), cos(r))
	return [axis, b.size.x if long_x else b.size.y, b.size.y if long_x else b.size.x, long_x]

## A church; a big one gets its bell tower at the west end.
func add_church(b: Dictionary, h: float, with_tower: bool, tower_k := 0.5, tower_h := 200.0) -> void:
	var cb := add_block_rotated(b.c, b.size, b.angle, "church", h)
	cb["big"] = with_tower; cb["name"] = b.get("name", "")   # for the church models (WorldBuilder)
	if not with_tower: return
	var la := long_axis(b)
	var axis: Vector2 = la[0]
	var end: Vector2 = b.c + axis * la[1] / 2.0 if axis.x < 0 else b.c - axis * la[1] / 2.0   # the western end
	var ts: float = la[2] * tower_k
	var tb := add_block_rotated(end + (b.c - end).normalized() * ts * 0.5, Vector2(ts, ts), b.angle, "tower", tower_h)
	tb["church_tower"] = true   # a church model brings its own tower

# ------------------------------------------------------------------ walls opened where roads run through them

static func cross(a: Vector2, b: Vector2, c: Vector2, d: Vector2) -> Variant:
	var r := b - a; var s := d - c
	var den := r.x * s.y - r.y * s.x
	if absf(den) < 1e-4: return null
	var t := ((c.x - a.x) * s.y - (c.y - a.y) * s.x) / den; var k := ((c.x - a.x) * r.y - (c.y - a.y) * r.x) / den
	if t < 0.0 or t > 1.0 or k < 0.0 or k > 1.0: return null
	return a + r * t

## Where roads and paths cross a wall line: [[point, half the opening it needs]].
func crossings(w: Array, min_half := 70.0, extra := 50.0) -> Array:
	var gaps := []
	var roads := m.lines("roads")
	for i in roads.size():
		var r: Array = roads[i]
		var half := maxf(min_half, m.road_width[i] / 2.0 + extra)
		for k in r.size() - 1:
			for j in w.size() - 1:
				var x = cross(r[k], r[k + 1], w[j], w[j + 1])
				if x != null: gaps.append([x, half])
	return gaps

## A wall line as runs of points, left open at every gap, with a corner every `every` px for the cutaway.
static func cut_at(w: Array, gaps: Array, every := 120.0) -> Array:
	var runs := []
	var run := []
	for i in w.size() - 1:
		var a: Vector2 = w[i]; var b: Vector2 = w[i + 1]
		var steps := maxi(1, ceili(a.distance_to(b) / 20.0))
		for k in steps + 1:
			if k == 0 and i > 0: continue
			var p := a.lerp(b, k / float(steps))
			var open := false
			for g in gaps:
				if p.distance_to(g[0]) < g[1]:
					open = true
					break
			if open:
				if run.size() > 1: runs.append(run)
				run = []
				continue
			if run.is_empty() or k == steps or run[-1].distance_to(p) >= every: run.append(p)
	if run.size() > 1: runs.append(run)
	return runs

## Headstones in rows over the cemeteries.
func add_graves(limit := 120, dx := 70.0, dy := 90.0, mind_walls := true) -> void:
	var n := 0
	for cem in m.lines("cemeteries"):
		var bb := bounds(cem)
		var x := bb.position.x
		while x < bb.end.x and n < limit:
			var y := bb.position.y
			while y < bb.end.y and n < limit:
				var p := Vector2(x + rng.f() * 20.0, y + rng.f() * 20.0)
				y += dy
				if not inside(p, cem) or near_building(p, 20.0) or (mind_walls and near_wall(p, 40.0)) or near_road(p, 10.0): continue
				add_block(Rect2(p.x - 9, p.y - 4, 18, 8), "stone", 14.0 + rng.f() * 8.0)
				n += 1
			x += dx

# ------------------------------------------------------------------ gardens

const GARDENS := [
	[["garden_bed", 0], ["pumpkins", 0], ["cabbages", 0], ["wattle_fence", 0]],
	[["garden_bed", 0], ["tomatoes_stakes", 0], ["cabbages", 0], ["apple_basket", 0]],
	[["corn_shock", 14], ["corn_shock", 14], ["haystack_plain", 26], ["scarecrow", 10]],
	[["apple_tree_autumn", 22], ["beehives", 16], ["apple_basket", 0]],
	[["pepper_rack", 14], ["wheelbarrow_pumpkins", 12], ["garden_shed", 30]],
	[["pumpkins", 0], ["sunflowers_dry", 0], ["sunflowers_dry", 0], ["wattle_fence", 0]],
	[["haystack_plain", 26], ["scarecrow", 10], ["pumpkins", 0]],
	# working yards: the things a household leaves standing about
	[["woodpile", 20], ["chopping_block", 10], ["firewood", 14], ["wattle_fence", 0]],
	[["handcart", 18], ["barrels", 16], ["sacks", 12], ["wattle_fence", 0]],
	[["washtub", 12], ["clothesline", 0], ["bench", 10]],
	[["garden_shed", 30], ["ladder", 0], ["wheel", 0], ["wattle_fence", 0]],
	[["kennel", 16], ["trough", 14], ["haycart", 22]],
	[["well", 20], ["trough", 14], ["bench2", 10]],
]
const GARDEN_LAYOUT := [Vector2(0, 0), Vector2(-58, 26), Vector2(56, 22), Vector2(0, -54)]

## Autumn gardens and working yards behind the houses, after everything else has its place.
func plant_gardens(seed_value: int, ok: Callable, limit := 80) -> int:
	var r := NetRandom.new(seed_value)
	var taken: Array[Vector2] = []
	for p in props: taken.append(p.pos)
	for d in decors: taken.append(d.pos)
	var clear := func(g: Vector2) -> bool:
		if not ok.call(g): return false
		for t in taken:
			if t.distance_squared_to(g) < 95.0 * 95.0: return false
		for o in GARDEN_LAYOUT:
			if not ok.call(g + o): return false
		return true
	var houses := []
	for b in blocks:
		if b.style == "house": houses.append(b)
	for i in range(houses.size() - 1, 0, -1):
		var j := r.i(i + 1)
		var tmp = houses[i]; houses[i] = houses[j]; houses[j] = tmp
	var n := 0
	for h in houses:
		if n >= limit: break
		if r.f() < 0.12: continue   # nearly every house keeps a garden or a yard
		var reach: float = maxf(h.size.x, h.size.y) * 0.5 + 95.0
		var start := r.i(8)
		for k in 8:
			var a := (start + k) * PI / 4.0
			var g: Vector2 = h.c + Vector2(cos(a), sin(a)) * (reach + r.f() * 40.0)
			if not clear.call(g): continue
			var kind: Array = GARDENS[r.i(GARDENS.size())]
			for i in mini(kind.size(), GARDEN_LAYOUT.size()):
				var at: Vector2 = g + GARDEN_LAYOUT[i] + Vector2(r.f() * 10.0 - 5.0, r.f() * 8.0 - 4.0)
				add_decor(at, kind[i][0], kind[i][1], r.f() < 0.5)
			# a crooked run of wattle fence along one side of the plot, where there is room for it
			if r.f() < 0.6:
				var fy := 78.0 if r.f() < 0.5 else -92.0
				for i in range(-2, 3):
					var fp := g + Vector2(i * 46.0, fy + r.f() * 8.0 - 4.0)
					if ok.call(fp): add_decor(fp, "wattle_fence", 10.0, i % 2 == 0)
			taken.append(g); n += 1
			break
	return n

## The usual test for a garden plot: off the streets, clear of houses and walls, inside the map.
func garden_ok(g: Vector2) -> bool:
	return not near_road(g, 95.0) and not near_building(g, 40.0) and not near_wall(g, 60.0) and not blocked(g, 40.0) \
		and g.x > 120.0 and g.y > 120.0 and g.x < size.x - 120.0 and g.y < size.y - 120.0

# ------------------------------------------------------------------ a more compact village

## Called once the village is built: drop the outermost houses nobody needs, then draw everything smaller
## around the map's corner, so the walks are shorter. Positions, houses, roads and walls all shrink together;
## people, props and trees keep their size. Anything a later scene uses (spots, member positions, the doors
## other levels come back to) is moved with it.
func compact() -> void:
	if compact_k >= 0.999 and trim_k <= 0.0: return
	_trim_edges()
	var f := compact_k
	var done: Array = []   # arrays already scaled (the same array can hang off the map and a member)
	if m:
		m.scale_all(f)
		for key in m._cache:
			if m._cache[key] is Array:
				for ln in m._cache[key]:
					if ln is Array: done.append(ln)
	for b in blocks:
		b.c *= f; b.size *= f; b.h = maxf(b.h * f, minf(b.h, 30.0))
		if b.has("shape") and is_instance_valid(b.shape):
			b.shape.queue_free()
			var r := deg_to_rad(b.angle)
			b.shape = solid_box(b.c + Vector2(-sin(r), -cos(r)) * b.size.y / 2.0, b.size, b.angle)
	for t in trees: t.p *= f
	for d in decals: d.c *= f
	for r in roads:
		if not _done(done, r.pts):
			for i in r.pts.size(): r.pts[i] *= f
			done.append(r.pts)
	for i in cobbles.size(): cobbles[i] = Rect2(cobbles[i].position * f, cobbles[i].size * f)
	for w in walls: w.c *= f
	for cv in covered:
		cv.rect = Rect2(cv.rect.position * f, cv.rect.size * f); cv.a *= f; cv.b *= f
	for k in spots: spots[k] *= f
	# everything already standing: people, things, lights, gates, triggers, the loose collision pieces
	var skip := {}
	for b in blocks:
		if b.has("shape"): skip[b.shape] = true
	for cu in curtains:
		for sh in cu.get("shapes", []): skip[sh] = true
	for n in get_children():
		if n == solids or not (n is Node3D): continue
		_scale_node(n, f)
	for cs in solids.get_children():
		if skip.has(cs) or not (cs is Node3D): continue
		cs.position.x *= f; cs.position.z *= f
	for cu in curtains:
		if not _done(done, cu.pts):
			for i in cu.pts.size(): cu.pts[i] *= f
			done.append(cu.pts)
		for sh in cu.get("shapes", []):
			if is_instance_valid(sh): sh.queue_free()
		cu.shapes = []
		_curtain_shapes(cu)
	# the level's own remembered positions
	for pr in get_property_list():
		if not (pr.usage & PROPERTY_USAGE_SCRIPT_VARIABLE): continue
		if pr.name in ["compact_k", "trim_k", "free_r1", "road_min_half"]: continue
		var v = get(pr.name)
		if v is Vector2: set(pr.name, v * f)
		elif v is Rect2: set(pr.name, Rect2(v.position * f, v.size * f))
		elif v is Array and not v.is_empty() and v[0] is Vector2 and not _done(done, v):
			for i in v.size(): v[i] *= f
			done.append(v)
	_street_samples.clear()
	_scale_statics(f)

static func _done(done: Array, a: Array) -> bool:
	for d in done:
		if is_same(d, a): return true
	return false

func _scale_node(n: Node3D, f: float) -> void:
	if n is MeshInstance3D and n.position == Vector3.ZERO and n.mesh:   # built in place (a cellar head): move its middle
		var c: Vector3 = n.mesh.get_aabb().get_center()
		n.position = Vector3(c.x * f - c.x, 0, c.z * f - c.z)
		return
	n.position.x *= f; n.position.z *= f

## Doors other levels send the hunter back to, kept on the quest scripts.
func _scale_statics(f: float) -> void:
	match id:
		"viscri": VisQuest.crypt_door *= f
		"malancrav": MlQuest.crypt_door *= f
		"cris": CsQuest.forest_gate *= f
		"crit": CritQuest.forest_gate *= f
		"richisvillage":
			RcQuest.ridge_gate *= f; RcQuest.forest_gate *= f
		"saschiz": SxQuest.hill_path *= f
		"sighisoara":
			var sc: GDScript = get_script()
			sc.set("cellar_door", sc.get("cellar_door") * f)
			sc.set("dracul_door", sc.get("dracul_door") * f)

## The outermost houses (by distance from the middle of the village) go, unless somebody or something the
## story uses stands by them.
func _trim_edges() -> void:
	var houses: Array = []
	var heart := Vector2.ZERO; var n := 0
	for b in blocks:
		if b.style == "house":
			houses.append(b); heart += b.c; n += 1
	if n < 12 or trim_k <= 0.0: return
	heart /= n
	for b in blocks:
		if b.style == "church": heart = b.c
	var ds: Array = []
	for b in houses: ds.append(b.c.distance_to(heart))
	ds.sort()
	var lim: float = ds[int(ds.size() * (1.0 - trim_k))]
	for b in houses:
		if b.c.distance_to(heart) < lim: continue
		var used := false
		for p in props:
			if is_instance_valid(p) and p.pos.distance_to(b.c) < 320.0:
				used = true
				break
		if used: continue
		if b.has("shape") and is_instance_valid(b.shape): b.shape.queue_free()
		blocks.erase(b)
	# yard walls left standing alone out there go with them
	for cu in curtains.duplicate():
		if cu.thick > 24.0: continue
		var far := true
		for q in cu.pts:
			if q.distance_to(heart) < lim * 1.02:
				far = false
				break
		if far:
			for sh in cu.get("shapes", []):
				if is_instance_valid(sh): sh.queue_free()
			curtains.erase(cu)
