## Builds the 3D world from what a level recorded: ground, roads, coloured patches, houses (Saxon and Romanian),
## churches, towers, ring walls with their gates, trees, and the dark forest beyond the map's edge.
## Geometry is written in the old build's space (x east, y up, z north); MeshBuilder mirrors it on the way out.
class_name WorldBuilder
extends RefCounted

const S := Fx.S
const HK := Fx.HK
const DARK := Color(0.03, 0.025, 0.02)

static var L: Level
static var root: Node3D
static var wall_ends: Array[Dictionary] = []
static var village_heart := Vector2.ZERO
static var romanian_from := INF
static var _static := {}   # plain masonry (stones, rocks, low walls) merged by patch of ground

## A map point in the old build's 3D space.
static func u(p: Vector2, h := 0.0) -> Vector3:
	return Vector3(p.x * S, h, -p.y * S)

static func _yaw(deg: float) -> Basis:
	return MeshBuilder._yaw(deg)

static func build(level: Level) -> void:
	L = level
	root = Node3D.new()
	root.name = "World"
	L.add_child(root)
	wall_ends.clear()
	Atmosphere.build(L, L.id)
	_ground()
	_roads()
	_decals()
	_prep_houses()
	_static.clear()
	for b in L.blocks: _block(b)
	for k in _static: _static[k].commit(root, "Stones")
	for c in L.curtains: _curtain(c)
	_gates()
	for cw in L.covered: _covered_way(cw)
	_trees()
	_wilds()

static func _cut(node: MeshInstance3D) -> void:
	if node == null: return
	var bb := node.get_aabb()
	L.cutaways.append({"node": node, "centre": bb.get_center(), "half_w": bb.size.x / 2.0, "half_d": bb.size.z / 2.0, "faded": false})

# ------------------------------------------------------------------ light

## Scale the moon and the ambient light by the level's own brightness (caves are dark, villages bright).
static func apply_darkness(level: Level) -> void:
	var main := level.get_tree().current_scene
	# The level's ambient colour sets the hour. Its brightness runs from deep night through the overcast dusk the
	# villages were tuned at (k about 1.4, unchanged) up to plain day; its hue leans the light (a red eclipse, a storm).
	var a := level.ambient()
	var lum := a.r * 0.3 + a.g * 0.59 + a.b * 0.11
	var night := clampf((0.4 - lum) / 0.26, 0.0, 1.0)
	var day := clampf((lum - 0.58) / 0.22, 0.0, 1.0)
	var k := clampf(lum / 0.4, 1.0, 1.45)
	if lum < 0.4: k = lerpf(0.46, 1.0, pow(lum / 0.4, 1.2))
	k += day * 0.5
	var tint := Color.WHITE.lerp(Color(a.r, a.g, a.b) / maxf(lum, 0.06), 0.5)
	tint = Color(minf(tint.r, 1.6), minf(tint.g, 1.6), minf(tint.b, 1.6))
	Fx.ambient_k = k
	Fx.ambient_tint = tint
	var moon_col := Color(0.55, 0.62, 0.9); var moon_e := 1.7 * k; var shadow := 0.75
	var sky := Color(0.42, 0.44, 0.58) * k; var eq := Color(0.3, 0.29, 0.34) * k; var gnd := Color(0.16, 0.14, 0.12) * k
	var fog_d := 0.012; var fog_c := Color(0.05, 0.06, 0.09)
	if Mats.px():
		# a raw, overcast autumn dusk: cold grey light, the village sunk in damp haze
		moon_col = Color(0.66, 0.7, 0.78); moon_e = 1.9 * k; shadow = 0.45
		sky = Color(0.5, 0.53, 0.6) * k; eq = Color(0.36, 0.37, 0.4) * k; gnd = Color(0.13, 0.13, 0.12) * k
		fog_d = 0.026; fog_c = Color(0.16, 0.18, 0.2)
	# night: a thin blue moon and black haze. Day: a low warm sun, long soft shadows, the haze burnt off.
	moon_col = moon_col.lerp(Color(0.42, 0.52, 0.95), night * 0.7).lerp(Color(1.0, 0.9, 0.72), day)
	moon_e *= 1.0 + day * 0.35 + night * 0.75   # a clear moon: dark, but shapes still read
	shadow = lerpf(shadow, 0.6, day)
	fog_c = fog_c.lerp(Color(0.035, 0.045, 0.08), night).lerp(Color(0.5, 0.52, 0.5), day * 0.6)
	fog_d *= 1.0 - day * 0.55
	sky = sky.lerp(Color(0.62, 0.66, 0.72) * k, day * 0.6)
	sky *= tint; eq *= tint
	if level.id == "sacristy":
		# inside the hall church: candlelight and stone, no moon
		moon_col = Color(0.8, 0.66, 0.52); moon_e = 0.8 * k; shadow = 0.6
		sky = Color(0.3, 0.26, 0.22) * k; eq = Color(0.24, 0.2, 0.17) * k
		fog_c = Color(0.06, 0.05, 0.04)
	main.set_light(moon_col, moon_e, shadow, sky, eq, gnd, fog_d, fog_c)

# ------------------------------------------------------------------ ground

static func _ground() -> void:
	# the ground runs well past the map's edges so the camera never looks into a void
	var m := Mats.ground_for(L.id, L)
	var x0 := -35.0; var x1 := L.size.x * S + 35.0; var z1 := 35.0; var z0 := -L.size.y * S - 35.0
	var step := 12.0
	var holder := Node3D.new()
	holder.name = "Ground"
	root.add_child(holder)
	var x := x0
	while x < x1:
		var z := z0
		while z < z1:
			var b := Batch.new()
			var xe := minf(x + step, x1); var ze := minf(z + step, z1)
			b.mb(m).quad(Vector3(x, 0, z), Vector3(x, 0, ze), Vector3(xe, 0, ze), Vector3(xe, 0, z))
			b.commit(holder, "G", false)
			z += step
		x += step
	if L.id in ["forest", "critforest", "crisforest", "richisforest", "ieleridge", "uriasi", "hills", "vineyard", "walls", "biertanfort", "arena", "hollow"]:
		_macro_veil(Vector2(x1 - x0, z1 - z0), Vector3((x0 + x1) / 2.0, 0.02, (z0 + z1) / 2.0))

## A faint dark veil over the ground: shadowy hollows and paler stretches at a scale far larger than the
## texture's repeat, so its tiles don't line up into visible stripes.
static func _macro_veil(sz: Vector2, centre: Vector3) -> void:
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.fractal_octaves = 4
	noise.frequency = 0.012
	var n := 256
	var img := noise.get_seamless_image(n, n)
	var veil := Image.create(n, n, true, Image.FORMAT_RGBA8)
	for y in n:
		for x in n:
			var d := clampf((0.62 - img.get_pixel(x, y).r) * 1.6, 0.0, 1.0)
			veil.set_pixel(x, y, Color(0.02, 0.025, 0.02, d * 0.55))
	veil.generate_mipmaps()
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_texture = ImageTexture.create_from_image(veil)
	mat.uv1_scale = Vector3(sz.x / 22.0, sz.y / 22.0, 1)
	var mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = sz
	mi.mesh = pm
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(mi)
	mi.position = Vector3(centre.x, centre.y, -centre.z)

static func _roads() -> void:
	for r in L.cobbles:
		var b := Batch.new()
		b.mb(Mats.cobble()).flat_rect(u(r.get_center(), 0.02), r.size.x * S, r.size.y * S)
		b.commit(root, "Cobbles", false)
	for road in L.roads:
		var cob: bool = road.cobble
		var b := Batch.new()
		var mb := b.mb(Mats.cobble() if cob else Mats.road())
		var pts: Array = road.pts
		var w: float = road.width * S
		for i in pts.size():
			var a: Vector2 = pts[i]
			if cob: mb.disc(u(a, 0.013), w * 0.45, w * 0.45, 0.0, 16)
			if i == pts.size() - 1: break
			var c: Vector2 = pts[i + 1]
			var ang := rad_to_deg(atan2(-(c.y - a.y), c.x - a.x))
			mb.flat_rect(u((a + c) / 2.0, 0.014 if cob else 0.012), a.distance_to(c) * S, w, -ang)
		b.commit(root, "Road", false)

## Flat ground features (lakes, yards, carpets, graves, clearings): coloured shapes, one mesh per colour.
static func _decals() -> void:
	var groups := {}
	for d in L.decals:
		var sz: Vector2 = d.size
		if d.has("tex"):   # textured ground patch
			var tb := Batch.new()
			var tm: MeshBuilder = tb.mb(Mats.mat(d.tex, d.tile, d.col, 0.05))
			var ta := u(d.c, 0.008 + (d.order + 1000) * 0.0008)
			if d.disc: tm.disc(ta, sz.x * S / 2.0, sz.y * S / 2.0, d.rot, 40)
			else: tm.flat_rect(ta, sz.x * S, sz.y * S, d.rot)
			tb.commit(root, "Patch", false)
			continue
		if absf(sz.x) < 14.0 and absf(sz.y) < 14.0: continue   # ground specks: the texture covers them
		var c: Color = d.col
		if c.a < 0.5: continue   # faint shading: the lighting does this job now
		var faint := c.a < 1.0   # scattered blots of grass and moss: they only mottle the ground
		c = Color(roundf(c.r * 40.0) / 40.0, roundf(c.g * 40.0) / 40.0, roundf(c.b * 40.0) / 40.0, 0.3 if faint else 1.0)
		if not groups.has(c): groups[c] = Batch.new()
		var water := c.b > c.r * 1.25 and c.b > 0.15
		var mb: MeshBuilder = groups[c].mb(Mats.fade(c) if faint else Mats.plain(c, 0.85 if water else 0.1))
		var at := u(d.c, 0.008 + (d.order + 1000) * 0.0008)
		if d.disc: mb.disc(at, sz.x * S / 2.0, sz.y * S / 2.0, d.rot, 24)
		else: mb.flat_rect(at, sz.x * S, sz.y * S, d.rot)
	for c in groups: groups[c].commit(root, "Decal", false)
	for w in L.walls:
		var b := Batch.new()
		b.mb(Mats.stone()).box(u(w.c + Vector2(-w.size.x, w.size.y) / 2.0), u(w.c + Vector2(w.size.x, -w.size.y) / 2.0, 1.2), true)
		b.commit(root, "Wall")

# ------------------------------------------------------------------ houses

## Romanian families lived at the edges of the Saxon villages: the outer houses get the Romanian build.
static func _prep_houses() -> void:
	romanian_from = INF
	if L.id in ["sighisoara", "cellar", "crypt", "malcrypt", "tunnel", "sacristy", "stana"]: return
	var c := Vector2.ZERO; var n := 0
	for b in L.blocks:
		if b.style in ["church", "tower", "model"]:
			c += b.c; n += 1
	village_heart = c / n if n > 0 else L.size / 2.0
	var dists: Array[float] = []
	for b in L.blocks:
		if b.style == "house": dists.append(b.c.distance_to(village_heart))
	if dists.size() < 6: return
	dists.sort()
	romanian_from = dists[int(dists.size() * (0.45 if L.id in ["cris", "sapartoc"] else 0.65))]   # Criș and Șapartoc were more Romanian than most

# ------------------------------------------------------------------ buildings shaped from models

## Old church plaster: weathered, warm grey-ochre, never fresh white.
static func _old_plaster() -> Material:
	return Mats.mat("px_plaster0", 1.8, Color(0.74, 0.69, 0.6))

static func _church_model(b: Dictionary) -> String:
	if not b.get("big", true): return "chapel"
	var nm: String = str(b.get("name", "")).to_lower()
	match L.id:
		"saschiz": return "saschiz_church"
		"viscri": return "viscri_church"
		"biertanfort": return "biertan_church"
		"hillchurch": return "hill_church"
		"sighisoara": return "hill_church" if nm.contains("deal") else "village_church"   # the Church on the Hill
		"malancrav", "richisvillage": return "basilica"
		"sapartoc":
			if nm.contains("orto") or nm.contains("orth") or nm == "": return "orthodox"   # the map leaves the Orthodox one unnamed
			if nm.contains("reform"): return "reformed"
			return "village_church"
	return "village_church"

## A church, tower or house drawn from its model (ModelKit) in the materials its box would have had.
## False when there is no model for it, and the box is built as before.
static func _modelled(b: Dictionary, base: Transform3D, w: float, d: float, h: float, p: Vector2) -> bool:
	var style: String = b.style
	# blocks are laid out in the old build's space (north-south flipped, which the mesh builder undoes): bring the
	# block's frame into game space, where models are placed; there its footprint runs along local -z
	var F := Basis.from_scale(Vector3(1, 1, -1))
	base = Transform3D(F * base.basis * F, Vector3(base.origin.x, base.origin.y, -base.origin.z))
	var west := base.basis.inverse() * Vector3(-1, 0, 0)   # the tower end of a Saxon church
	match style:
		"church":
			var m := _church_model(b)
			if not ModelKit.exists(m): return false
			var orth := m == "orthodox"
			ModelKit.place(L, base, w, d, m, Mats.mat("px_planks", 0.7, Color(0.7, 0.66, 0.6), 0.05) if orth else Mats.roof_at(p), _old_plaster(), 12.0, "long", west)
			return true
		"tower":
			if b.get("church_tower", false) and ModelKit.exists(_church_model({"big": true})): return true   # the church model has it
			var m := "gate_tower" if (L.id == "viscri" and not b.solid) else "guild_tower"
			if L.id in ["uriasi"] or not ModelKit.exists(m): return false   # the giant's fortress is a ruin
			ModelKit.place(L, base, w, d, m, Mats.roof(), _old_plaster() if m == "gate_tower" else Mats.stone(), h * 1.3)
			return true
		"clocktower":
			if not ModelKit.exists("clocktower"): return false
			ModelKit.place(L, base, w, d, "clocktower", Mats.roof(), Mats.stone(), h * 1.1)
			return true
		"house":
			var roof_h := minf(minf(w, d) * 0.95, 3.8)
			if b.c.distance_to(village_heart) >= romanian_from:
				if not ModelKit.exists("house_ro"): return false
				ModelKit.place(L, base, w, d, "house_ro", _ro_roof(p), _ro_wall(p), h + roof_h)
				return true
			if b.get("dracul", false) and ModelKit.exists("house_big"):   # Casa Vlad Dracul: ochre, as it is painted now
				ModelKit.place(L, base, w, d, "house_big", Mats.mat("px_roof", 1.2, Color(0.55, 0.4, 0.38), 0.05), Mats.mat("px_plaster0", 1.8, Color(1.0, 0.74, 0.32)), h + roof_h)
				return true
			var m := "barn" if b.h >= 58.0 else ("house_big" if w * d > 70.0 else "house_saxon")
			if not ModelKit.exists(m): return false
			var wm2: Material = Mats.mat("px_planks", 1.1, Color(0.55, 0.45, 0.36), 0.04) if m == "barn" else Mats.saxon_plaster(p)
			ModelKit.place(L, base, w, d, m, Mats.roof_at(p), wm2, h + roof_h)
			return true
	return false

## A Romanian house's walls: mostly lime-washed white, some washed the old blue, a few of bare timber.
static func _ro_wall(p: Vector2) -> Material:
	match absi(int(p.x * 0.21) + int(p.y * 0.17)) % 6:
		0: return Mats.mat("px_planks", 1.1, Color(0.72, 0.6, 0.48), 0.04)
		1, 2: return Mats.mat("px_plaster0", 1.8, Color(0.72, 0.84, 0.95))
		_: return Mats.mat("px_plaster0", 1.8, Color(1.0, 0.98, 0.94))

## Its roof: silvered shingle or, on the newer ones, the same red tile as the Saxons'.
static func _ro_roof(p: Vector2) -> Material:
	if absi(int(p.x * 0.13) + int(p.y * 0.29)) % 2 == 0: return Mats.roof_at(p)
	return Mats.mat("px_planks", 0.7, Color(1.0, 0.97, 0.92), 0.05)

static func _block(b: Dictionary) -> void:
	var style: String = b.style
	if style in ["hidden", "vine", "model"]: return   # a "model" block is drawn by its 3D model
	if style == "wall": _note_wall(b)
	if style == "wall" and maxf(b.size.x, b.size.y) > 120.0:
		_ring_wall(b)
		return
	var p := Vector2(b.c.x, -b.c.y)   # where the block stood in the old build's 2D space: seeds its colours
	var w: float = b.size.x * S; var d: float = b.size.y * S; var h: float = maxf(0.25, b.h * S * HK)
	# keep rock and walls low enough to see over from the camera
	if style == "rock": h = minf(h, 1.3)
	elif style in ["wall", "stone", "ruin"]: h = minf(h, 2.2)
	var base := Transform3D(_yaw(-b.angle), u(b.c))
	var merged := style in ["stone", "rock", "ruin", "pew", "wall"]
	var bt: Batch = _chunk(_static, u(b.c)) if merged else Batch.new()
	bt.xf = base
	var mn := Vector3(-w / 2.0, 0, 0); var mx := Vector3(w / 2.0, h, d)
	var wall_mat: Material = Mats.stone(); var roof_mat: Material = Mats.roof()
	if _modelled(b, base, w, d, h, p): return
	match style:
		"house":
			if b.c.distance_to(village_heart) >= romanian_from:
				# a Carpathian mountain house: dark weathered timber (a few whitewashed), a tall hipped roof of
				# silvered shingles reaching out over the prispa, the porch on carved posts, a stone chimney
				wall_mat = _ro_wall(p)
				roof_mat = _ro_roof(p)
				bt.mb(wall_mat).box(mn, mx, false)
				_stone_base(bt, mn, mx)
				# the prispa runs along a long side: a deep house is built turned a quarter, porch to the west
				var turn := d > w * 1.1
				bt.xf = base * Transform3D(_yaw(90.0 if turn else 0.0), Vector3(0, 0, d / 2.0))
				var lw := d if turn else w; var ld := w if turn else d
				var lmn := Vector3(-lw / 2.0, 0, -ld / 2.0); var lmx := Vector3(lw / 2.0, h, ld / 2.0)
				var porch := minf(1.1, ld * 0.45)
				var rise := minf(minf(lw, ld) * 1.05, 3.8)
				bt.mb(roof_mat).hip(lmn, lmx, rise, 0.35, porch, 0.35)
				_chimney(bt, Vector3(lw * 0.18, h, ld * 0.12), rise * 0.75, p)
				_prispa(bt, lmn, lmx, porch)
				bt.xf = base
			else:
				# a Saxon street house: plaster in the family's colour, a steep red tile gable to the street
				wall_mat = Mats.saxon_plaster(p); roof_mat = Mats.roof_at(p)
				bt.mb(wall_mat).box(mn, mx, false)
				var rise := minf(minf(w, d) * 1.1, 3.8)
				bt.mb(roof_mat).gable(mn, mx, rise, 0.36)
				_chimney(bt, Vector3(w * 0.22, h, d / 2.0), rise * 0.7, p)
				if L.id == "sighisoara": _beams(bt, mn, mx)
				else: _stone_base(bt, mn, mx)
		"church":
			wall_mat = Mats.plaster()
			bt.mb(wall_mat).box(mn, mx, false)
			bt.mb(roof_mat).gable(mn, mx, minf(w, d) * 0.85, 0.2)
		"tower":
			wall_mat = Mats.plaster()
			mx.y = maxf(mx.y, 4.2)   # towers stand well above the 2.9 m ring wall
			bt.mb(wall_mat).box(mn, mx, false)
			bt.mb(roof_mat).pyramid(mn, mx, maxf(w, d) * 1.25, 0.12)
			_slits(bt, mn, mx)
		"clocktower":
			# Sighișoara's Clock Tower: a tall stone shaft, a timber gallery, a steep spire and four corner turrets
			wall_mat = Mats.mat("px_stone2", 1.6, Color(0.7, 0.68, 0.65), 0.2) if Mats.px() else Mats.plaster()
			if Mats.px(): roof_mat = Mats.mat("px_roof2", 1.2, Color(0.9, 0.82, 0.7), 0.35)
			bt.mb(Mats.mat("px_planks", 1.2, Color(0.6, 0.55, 0.5)) if Mats.px() else Mats.wood()).box(Vector3(mn.x - 0.35, mx.y - 1.1, mn.z - 0.35), Vector3(mx.x + 0.35, mx.y - 0.2, mx.z + 0.35), true, true)
			bt.mb(wall_mat).box(mn, mx, false)
			var sp := maxf(w, d)
			bt.mb(roof_mat).pyramid(mn, mx, sp * 2.6, 0.25)
			var tt := sp * 0.2
			for cx in [mn.x, mx.x]:
				for cz in [mn.z, mx.z]:
					var tmn := Vector3(cx - tt / 2.0, mx.y - 0.3, cz - tt / 2.0); var tmx := Vector3(cx + tt / 2.0, mx.y + tt * 1.1, cz + tt / 2.0)
					bt.mb(wall_mat).box(tmn, tmx, false)
					bt.mb(roof_mat).pyramid(tmn, tmx, tt * 2.2, 0.06)
			_slits(bt, mn, mx)
		"wall":
			bt.mb(wall_mat).box(mn, mx, true)
			bt.mb(wall_mat).merlons(mn, mx)
		"pew":
			bt.mb(Mats.wood()).box(mn, Vector3(mx.x, minf(mx.y, 0.5), mx.z), true)
		"ruin":
			bt.mb(wall_mat).ruin_box(mn, mx, int(p.x * 7 + p.y * 3))
		_:   # stone, rock
			if style == "rock": wall_mat = Mats.mat("castle_wall_slates", 2.4, Color(0.42, 0.4, 0.38))
			bt.mb(wall_mat).box(mn, mx, true)
	if style in ["house", "church"]:
		_windows(bt, mn, mx, style == "church", Mats.shutter(p) if style == "house" and L.id != "sighisoara" else null)
	if style == "house":
		bt.mb(Mats.wood()).cube(Vector3(0, 0.55, mn.z - 0.02), Vector3(0.6, 1.1, 0.05))   # the door
	if merged: return
	var node := bt.commit(root, "Block " + style)
	b.node = node
	if style in ["house", "tower", "church", "clocktower"]: _cut(node)

## A rubble-stone base under the wall, a little proud of it, as the mountain houses stand on.
static func _stone_base(bt: Batch, mn: Vector3, mx: Vector3) -> void:
	bt.mb(Mats.stone()).cube(Vector3((mn.x + mx.x) / 2.0, mn.y + 0.3, (mn.z + mx.z) / 2.0), Vector3(mx.x - mn.x + 0.12, 0.6, mx.z - mn.z + 0.12))

## A rough stone chimney poking through the roof of about half the houses, a lip of stone on top.
static func _chimney(bt: Batch, at: Vector3, up: float, seed_at: Vector2) -> void:
	if absi(int(seed_at.x * 0.31) * 5 + int(seed_at.y * 0.23)) % 2 != 0: return
	var mb := bt.mb(Mats.stone())
	mb.cube(at + Vector3(0, (up + 0.9) / 2.0, 0), Vector3(0.5, up + 0.9, 0.5))
	mb.cube(at + Vector3(0, up + 0.95, 0), Vector3(0.66, 0.14, 0.66))

## The prispa: a raised clay porch along the front, wooden posts holding up the long eave, and the blue band
## painted round the foot of the walls.
static func _prispa(bt: Batch, mn: Vector3, mx: Vector3, depth: float) -> void:
	var wood := bt.mb(Mats.plain(Color(0.32, 0.22, 0.14), 0.12))
	var w := mx.x - mn.x; var h := mx.y - mn.y
	var cx := (mn.x + mx.x) / 2.0
	bt.mb(Mats.plain(Color(0.18, 0.38, 0.78), 0.1)).cube(Vector3(cx, mn.y + 0.74, (mn.z + mx.z) / 2.0), Vector3(w + 0.04, 0.28, mx.z - mn.z + 0.04))
	bt.mb(Mats.plain(Color(0.55, 0.45, 0.36), 0.05)).cube(Vector3(cx, 0.12, mn.z - depth / 2.0), Vector3(w, 0.24, depth))
	var posts := maxi(3, int(w / 1.3) + 1)
	var ph := h - 0.3
	for i in posts:
		wood.cube(Vector3(mn.x + 0.1 + i * (w - 0.2) / (posts - 1), 0.24 + ph / 2.0, mn.z - depth + 0.12), Vector3(0.13, ph, 0.13))
	wood.cube(Vector3(cx, 0.24 + ph, mn.z - depth + 0.12), Vector3(w, 0.12, 0.14))   # the beam the eave rests on
	wood.cube(Vector3(cx, 0.55, mn.z - depth + 0.12), Vector3(w, 0.06, 0.05))        # a low rail between the posts

static func _windows(bt: Batch, mn: Vector3, mx: Vector3, church: bool, shutter) -> void:
	var w := mx.x - mn.x; var h := mx.y - mn.y
	var n := maxi(1, int(w / 1.3))
	var glow := bt.mb(Mats.plain(Color(0.2, 0.12, 0.05), 0.6, Color(1.4, 0.75, 0.25)))
	for i in n:
		if not church and n > 1 and i == n / 2: continue   # the door goes here
		var at := Vector3(mn.x + (i + 0.5) * w / n, mn.y + h * (0.55 if church else 0.6), mn.z - 0.01)
		glow.cube(at, Vector3(0.22 if church else 0.3, minf(1.1, h * 0.35) if church else 0.38, 0.04))
		if shutter != null and not church:
			for sx in [-0.26, 0.26]:
				bt.mb(Mats.plain(shutter, 0.15)).cube(at + Vector3(sx, 0, -0.01), Vector3(0.2, 0.44, 0.04))

## Saxon half-timbering: dark beams over the plaster of the street front.
static func _beams(bt: Batch, mn: Vector3, mx: Vector3) -> void:
	var mb := bt.mb(Mats.plain(Color(0.12, 0.08, 0.05), 0.15))
	var w := mx.x - mn.x; var h := mx.y - mn.y
	var z := mn.z - 0.03
	mb.cube(Vector3((mn.x + mx.x) / 2.0, mx.y - 0.06, z), Vector3(w, 0.12, 0.06))
	mb.cube(Vector3((mn.x + mx.x) / 2.0, mn.y + 0.1, z), Vector3(w, 0.14, 0.06))
	var posts := maxi(2, int(w / 1.1) + 1)
	var bw := (w - 0.1) / (posts - 1)
	for i in posts:
		var x := mn.x + 0.05 + i * bw
		mb.cube(Vector3(x, (mn.y + mx.y) / 2.0, z), Vector3(0.1, h, 0.06))
		if i < posts - 1 and i % 2 == 0:   # a diagonal brace in every other bay
			mb.cube(Vector3(x + bw / 2.0, mn.y + h * 0.45, z), Vector3(sqrt(bw * bw + h * h * 0.36), 0.08, 0.05), rad_to_deg(atan2(h * 0.6, bw)))

## A stone footing and dark arrow slits on every face of a defence tower.
static func _slits(bt: Batch, mn: Vector3, mx: Vector3) -> void:
	bt.mb(Mats.mat("castle_wall_slates", 2.4, Color(0.62, 0.6, 0.56))).box(mn - Vector3(0.08, 0, 0.08), Vector3(mx.x + 0.08, 0.7, mx.z + 0.08), true)
	var slit := bt.mb(Mats.plain(DARK, 0.0))
	var c := (mn + mx) / 2.0
	for f in [[Vector3(0, 0, 1), (mx.z - mn.z) / 2.0], [Vector3(0, 0, -1), (mx.z - mn.z) / 2.0], [Vector3(1, 0, 0), (mx.x - mn.x) / 2.0], [Vector3(-1, 0, 0), (mx.x - mn.x) / 2.0]]:
		var dir: Vector3 = f[0]
		for y in [0.55, 0.8]:
			slit.cube(Vector3(c.x, mn.y + (mx.y - mn.y) * y, c.z) + dir * (f[1] + 0.01), Vector3(0.04, 0.5, 0.12) if dir.x != 0.0 else Vector3(0.12, 0.5, 0.04))

# ------------------------------------------------------------------ walls and gates

static func _note_wall(b: Dictionary) -> void:
	var w: float = b.size.x * S; var d: float = b.size.y * S
	var along_x := w >= d
	var rot := _yaw(-b.angle)
	var c := u(b.c) + rot * Vector3(0, 0, d / 2.0)
	var axis := rot * (Vector3.RIGHT if along_x else Vector3(0, 0, 1))
	var length := w if along_x else d; var thick := d if along_x else w
	var h := 2.9 if maxf(b.size.x, b.size.y) > 120.0 else minf(2.2, maxf(0.25, b.h * S * HK))
	var seg := wall_ends.size()
	wall_ends.append({"end": c - axis * length / 2.0, "out": -axis, "thick": thick, "h": h, "seg": seg})
	wall_ends.append({"end": c + axis * length / 2.0, "out": axis, "thick": thick, "h": h, "seg": seg})

## A village ring wall as the Saxons built them: tall rubble-stone walls under a little tiled roof that
## sheltered the defenders' walkway, with buttresses stepping out on the field side. Built in short pieces
## so the ones between the camera and the hunter can turn see-through.
static func _ring_wall(b: Dictionary) -> void:
	var w: float = b.size.x * S; var d: float = b.size.y * S; var H := 2.9
	var along_x := w >= d
	var length := w if along_x else d; var thick := d if along_x else w
	var start := u(b.c) + Vector3(-w / 2.0, 0, 0)
	var axis := Vector3.RIGHT if along_x else Vector3(0, 0, 1)
	var across := Vector3(0, 0, 1) if along_x else Vector3.RIGHT
	var lvl_mid := u(L.size / 2.0)
	var wall_mid := start + axis * length / 2.0 + across * thick / 2.0
	var out_sign := 1.0 if (wall_mid - lvl_mid).dot(across) > 0.0 else -1.0
	var n := maxi(1, roundi(length / 3.0))
	var seg := length / n
	for i in n:
		var a := start + axis * (i * seg) + across * (thick / 2.0)
		var e := a + axis * seg
		var bt := Batch.new()
		bt.mb(Mats.rubble()).oriented_box(a - axis * 0.02, e + axis * 0.02, thick, H)
		bt.mb(Mats.roof()).oriented_gable(a - axis * 0.02, e + axis * 0.02, thick + 0.5, H, 0.5)
		if i % 2 == 0:   # a buttress leaning on the field side
			var c := (a + e) / 2.0 + across * out_sign * (thick / 2.0 + 0.3)
			bt.mb(Mats.rubble()).oriented_box(c - axis * 0.3, c + axis * 0.3, 0.6, H * 0.7)
		_cut(bt.commit(root, "RingWall"))

## A curved fortification wall, one piece per segment: pale stone-and-plaster wall, a tiled roof over its
## walkway, buttress piers on the inside of the middle ring, plain timber for the stairway's sides.
static func _curtain(cw: Dictionary) -> void:
	var pts: Array = cw.pts
	var gallery: bool = cw.style == "gallery"
	var t: float = cw.thick * S
	var H: float = 1.1 if gallery else cw.h * S * HK * 1.6
	if not gallery and pts.size() > 1:
		var seg := wall_ends.size()
		var p0 := u(pts[0]); var p1 := u(pts[1]); var q0 := u(pts[-1]); var q1 := u(pts[-2])
		wall_ends.append({"end": p0, "out": (p0 - p1).normalized(), "thick": t, "h": H, "seg": seg})
		wall_ends.append({"end": q0, "out": (q0 - q1).normalized(), "thick": t, "h": H, "seg": seg})
	var wall_mat: Material = Mats.wood() if gallery else (Mats.stone() if Mats.px() else Mats.mat("clay_plaster", 2.5, Color(0.8, 0.78, 0.72)))
	var centroid := Vector2.ZERO
	for p in pts: centroid += p
	centroid /= maxi(1, pts.size())
	for i in pts.size() - 1:
		if pts[i].distance_to(pts[i + 1]) < 1.0: continue
		var a := u(pts[i]); var b := u(pts[i + 1]); var mid := (a + b) / 2.0
		var dir := (b - a).normalized()
		a -= dir * t * 0.35; b += dir * t * 0.35   # overlap the joints
		var bt := Batch.new()
		bt.mb(wall_mat).oriented_box(a, b, t, H)
		if not gallery:
			bt.mb(Mats.roof()).oriented_gable(a, b, t + 0.35, H, 0.45)
			if cw.style == "arches" and i % 2 == 0:
				var inward := u(centroid) - mid; inward.y = 0; inward = inward.normalized()
				var n := Vector3.UP.cross(dir)
				if n.dot(inward) < 0.0: n = -n
				var c := mid + n * (t / 2.0 + 0.25)
				bt.mb(Mats.stone()).oriented_box(c - dir * 0.25, c + dir * 0.25, 0.5, H * 0.82)
		_cut(bt.commit(root, "Curtain"))

## The building (other than walls) whose footprint covers a point on the ground, if any.
static func _occupied(pt: Vector3):
	for b in L.blocks:
		if b.style in ["wall", "hidden", "vine", "pew"]: continue
		var w: float = b.size.x * S; var d: float = b.size.y * S; var m := 0.3
		var local := _yaw(-b.angle).inverse() * (Vector3(pt.x, 0, pt.z) - u(b.c))
		if absf(local.x) < w / 2.0 + m and local.z > -m and local.z < d + m: return b
	return null

## Where two walls stop facing each other across a short gap, that gap is a way through: give it a gatehouse.
static func _gates() -> void:
	var used := {}
	var passaged := []
	for i in wall_ends.size():
		if used.has(i): continue
		var ea: Dictionary = wall_ends[i]
		var best := -1; var bd := INF
		for j in wall_ends.size():
			if j == i or used.has(j): continue
			var eb: Dictionary = wall_ends[j]
			if eb.seg == ea.seg: continue
			var g: Vector3 = eb.end - ea.end; g.y = 0
			var dist := g.length()
			if dist < 1.0 or dist > 7.6: continue
			var gn := g / dist
			if rad_to_deg(ea.out.angle_to(gn)) > 28.0 or rad_to_deg(eb.out.angle_to(-gn)) > 28.0: continue
			if dist < bd:
				bd = dist; best = j
		if best < 0: continue
		used[i] = true; used[best] = true
		var e2: Dictionary = wall_ends[best]
		var in_gap = _occupied((ea.end + e2.end) / 2.0)
		if in_gap != null:
			# a gate tower stands in the gap: if it can be walked through, cut a passage through it
			if not in_gap.solid and not passaged.has(in_gap):
				passaged.append(in_gap)
				_passage(in_gap, (e2.end - ea.end).normalized())
			continue
		_gatehouse(ea.end, e2.end, maxf(ea.thick, e2.thick), maxf(ea.h, e2.h))
	# walk-through gate towers the pairing missed (a wide gap): the passage runs across the nearest wall
	for b in L.blocks:
		if not b.style in ["tower", "clocktower"] or b.solid or passaged.has(b): continue
		var c3 := u(b.c)
		var bd2 := INF; var dir := Vector3.RIGHT
		for we in wall_ends:
			var d2: float = (we.end - c3).length_squared()
			if d2 < bd2:
				bd2 = d2; dir = we.out
		if bd2 > 15.0 * 15.0: continue
		passaged.append(b)
		_passage(b, dir)

## A gate tower you can walk through gets a dark vaulted passage across it and open oak doors.
static func _passage(tower: Dictionary, wall_dir: Vector3) -> void:
	var c := u(tower.c) + _yaw(-tower.angle) * Vector3(0, 0, tower.size.y * S / 2.0)
	wall_dir.y = 0; wall_dir = wall_dir.normalized()
	var across := wall_dir.cross(Vector3.UP)
	var reach: float = maxf(tower.size.x, tower.size.y) * S * 0.5 + 0.06
	var bt := Batch.new()
	bt.mb(Mats.plain(DARK, 0.0)).oriented_box(c - across * reach, c + across * reach, 1.7, 2.3)
	for side in [-1.0, 1.0]:
		for lr in [-1.0, 1.0]:
			var hinge: Vector3 = c + across * side * reach + wall_dir * lr * 0.85
			var dir: Vector3 = (across * side * 0.95 - wall_dir * lr * 0.3).normalized()
			bt.mb(Mats.wood()).oriented_box(hinge, hinge + dir * 0.8, 0.08, 2.0)
	bt.commit(root, "Gate passage", false)

## Two stone posts, a lintel under a little tiled roof and two oak leaves standing open toward the fields.
static func _gatehouse(a: Vector3, b: Vector3, thick: float, h: float) -> void:
	a.y = 0; b.y = 0
	var dir := (b - a).normalized()
	var mid := (a + b) / 2.0
	var across := dir.cross(Vector3.UP)
	if (mid - u(L.size / 2.0)).dot(across) < 0.0: across = -across   # the field side
	var post := 0.55; var top := maxf(h + 0.5, 2.6); var pt := thick + 0.3
	var bt := Batch.new()
	var stone := bt.mb(Mats.rubble())
	stone.oriented_box(a - dir * post * 0.5, a + dir * post * 0.5, pt, top)
	stone.oriented_box(b - dir * post * 0.5, b + dir * post * 0.5, pt, top)
	var keep := bt.xf
	bt.xf = Transform3D(Basis(), Vector3.UP * (top - 0.45))
	stone.oriented_box(a, b, pt, 0.45)   # the lintel
	bt.xf = keep
	bt.mb(Mats.roof()).oriented_gable(a - dir * post, b + dir * post, pt + 0.6, top, 0.55)
	var leaf := maxf(0.3, (a.distance_to(b) - post) / 2.0); var lh := minf(top - 0.5, 2.1)
	for hs in [[a + dir * post * 0.5, 1.0], [b - dir * post * 0.5, -1.0]]:
		var ld: Vector3 = (dir * hs[1] * 0.25 + across * 0.97).normalized()
		var hinge: Vector3 = hs[0] + across * (pt * 0.5)
		bt.mb(Mats.wood()).oriented_box(hinge, hinge + ld * leaf, 0.09, lh)
	_cut(bt.commit(root, "Gatehouse"))

## The covered wooden stairway: posts down both sides and a tiled roof over the passage.
static func _covered_way(cw: Dictionary) -> void:
	var H := 1.9
	var posts := Batch.new()
	var roof := Batch.new()
	var pm := posts.mb(Mats.wood())
	if cw.width > 0.0:
		var a := u(cw.a); var b := u(cw.b)
		var dir := (b - a).normalized()
		var n := Vector3.UP.cross(dir)
		var half: float = cw.width * S / 2.0
		var s := 0.3
		while s < a.distance_to(b):
			for side in [-1.0, 1.0]:
				var c: Vector3 = a + dir * s + n * side * (half - 0.1)
				pm.box(c - Vector3(0.09, 0, 0.09), c + Vector3(0.09, H, 0.09), true)
			s += 1.6
		roof.mb(Mats.roof()).oriented_gable(a, b, cw.width * S + 0.3, H, 0.8)
	else:
		var r: Rect2 = cw.rect
		var x0 := r.position.x * S; var x1 := r.end.x * S; var z0 := -r.end.y * S; var z1 := -r.position.y * S
		var z := z0 + 0.3
		while z < z1:
			for x in [x0 + 0.1, x1 - 0.1]:
				pm.box(Vector3(x - 0.09, 0, z - 0.09), Vector3(x + 0.09, H, z + 0.09), true)
			z += 1.6
		roof.mb(Mats.roof()).gable(Vector3(x0 - 0.1, 0, z0), Vector3(x1 + 0.1, H, z1), 0.8, 0.25)
	posts.commit(root, "CoveredWay")
	cw.roof = roof.commit(root, "CoveredRoof")

# ------------------------------------------------------------------ trees

static func _tree_parts(bt: Batch, bark: Color, leaf_a: Color, leaf_b: Color) -> Dictionary:
	return {
		"bark": bt.mb(Mats.plain(bark, 0.05)), "leaves": bt.mb(Mats.plain(leaf_a, 0.08)), "leaves2": bt.mb(Mats.plain(leaf_b, 0.08)),
		"ground": bt.mb(Mats.plain(Color(0.13, 0.19, 0.1), 0.05)), "stone": bt.mb(Mats.plain(Color(0.33, 0.33, 0.31), 0.15)),
	}

static func _chunk(chunks: Dictionary, at: Vector3) -> Batch:
	var key := Vector2i(floori(at.x / 12.0), floori(at.z / 12.0))
	if not chunks.has(key): chunks[key] = Batch.new()
	return chunks[key]

static func _trees() -> void:
	var deep := L.id in Mats.WOODS
	var village := Mats.is_village(L.id)
	var chunks := {}
	for t in L.trees:
		var at := u(t.p)
		var seed_v := absi(int(t.p.x * 13 - t.p.y * 7))
		var rnd := NetRandom.new(seed_v)
		var bt := _chunk(chunks, at)
		bt.xf = Transform3D(Basis(), at)
		var dead: bool = not t.pine and deep and rnd.f() < 0.14
		var bark := Color(0.27, 0.26, 0.24) if dead else Color(0.2, 0.15, 0.11)
		if t.pine:
			Trees.spruce(_tree_parts(bt, bark, Color(0.07, 0.15, 0.12), Color(0.09, 0.19, 0.14)), Vector3.ZERO, t.sc, rnd)
		else:
			Trees.broadleaf(_tree_parts(bt, bark, Trees.leaf_color(seed_v, 0), Trees.leaf_color(seed_v, 1)), Vector3.ZERO, t.sc, rnd, dead)
		if not village: Trees.undergrowth(_tree_parts(bt, bark, Color.BLACK, Color.BLACK), Vector3.ZERO, t.sc, rnd)
	for k in chunks: chunks[k].commit(root, "Trees")

## The world doesn't stop at the map's edge: beyond it grows thick, dark forest (thinning to a meadow strip
## around the villages). Roads that leave the map keep a clear lane through it. Scenery only.
static func _wilds() -> void:
	if L.id in ["", "caves", "cellar", "crypt", "malcrypt", "tunnel", "gorge", "church", "sacristy"]: return
	var village := Mats.is_village(L.id)
	var deep := L.id in Mats.WOODS
	var map_m := L.size * S
	var margin := 15.0
	var spacing := 2.4 if village else 1.9
	# exits: triggers near an edge, each keeps a lane open straight out of the map
	var lanes := []
	for e in L.exits:
		var m: Vector2 = e * S
		var dl := m.x; var dr := map_m.x - m.x; var dt := m.y; var db := map_m.y - m.y
		var best := minf(minf(dl, dr), minf(dt, db))
		if best > 4.0: continue
		lanes.append([m, Vector2.LEFT if best == dl else (Vector2.RIGHT if best == dr else (Vector2.UP if best == dt else Vector2.DOWN))])
	var bark := Color(0.13, 0.1, 0.08); var dark := Color(0.07, 0.12, 0.09)
	var rust := Color(0.2, 0.12, 0.07) if deep else Color(0.15, 0.17, 0.09)
	var chunks := {}
	var rnd := NetRandom.new(hash(L.id) & 0x7fffffff)
	var x := -margin
	while x < map_m.x + margin:
		var z := -margin
		while z < map_m.y + margin:
			var px := x + (rnd.f() - 0.5) * spacing * 0.8
			var pz := z + (rnd.f() - 0.5) * spacing * 0.8
			z += spacing
			var ox := maxf(0.0, maxf(-px, px - map_m.x)); var oz := maxf(0.0, maxf(-pz, pz - map_m.y))
			var outside := sqrt(ox * ox + oz * oz)
			if outside < (4.5 if village else 0.8): continue
			if village and outside < 8.0 and rnd.f() < 0.6: continue   # a ragged forest edge
			var in_lane := false
			for ln in lanes:
				var rel: Vector2 = Vector2(px, pz) - ln[0]
				var along := rel.dot(ln[1])
				if along > -2.0 and absf(rel.x * ln[1].y - rel.y * ln[1].x) < 3.2 + along * 0.05:
					in_lane = true
					break
			if in_lane: continue
			var at := Vector3(px, 0, -pz)
			var bt := _chunk(chunks, at)
			var parts := _tree_parts(bt, bark, dark, rust)
			var sc := 0.85 + rnd.f() * 0.5
			if rnd.f() < (0.5 if deep else 0.3): Trees.spruce(parts, at, sc, rnd, true)
			else: Trees.broadleaf(parts, at, sc, rnd, false, true)
		x += spacing
	var _t0 := Time.get_ticks_msec()
	for k in chunks: chunks[k].commit(root, "Wilds")
	if OS.has_environment("PROF"): print("wilds commit ms ", Time.get_ticks_msec() - _t0, " chunks ", chunks.size())
