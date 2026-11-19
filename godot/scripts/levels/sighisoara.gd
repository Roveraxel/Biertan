## Sighișoara, the citadel on the hill where the hunter's road begins. Laid out from the real town (halved for
## play): the wall ring and its nine guild towers, the Clock Tower gate over the lower town, the street grid,
## the covered Scholars' Stairs up to the Church on the Hill. The spiriduși's lair is under the Butchers' Tower.
extends Village

const GAP := 110.0   # gate passage width
const CLUTTER := [["barrel", 18.0, 3.0], ["barrels", 30.0, 2.0], ["crate", 20.0, 2.0], ["sacks", 24.0, 2.0], ["firewood", 34.0, 3.0],
	["handcart", 40.0, 1.0], ["haycart", 55.0, 0.7], ["bench", 20.0, 1.0], ["trough", 30.0, 0.8], ["cauldron", 22.0, 0.5],
	["wheel", 0.0, 1.0], ["laundry", 0.0, 1.0], ["crow", 0.0, 1.5], ["lantern", 8.0, 1.0]]

static var dracul_door := Vector2.ZERO   # the door of Casa Vlad Dracul, on the square
static var cellar_door := Vector2.ZERO   # the hunter climbs back out here

var butcher: Prop
var butcher_at_tower := Vector2.ZERO
var _citadel: Array
var _spawn_ref := Vector2.ZERO

var finale := false
var follower: Prop           # Azorel, at heel
var lorena_p: Prop
var mort: VampireBoss
var night := false
var night_t := 0.0
var bell_cd := 0.0
var _fin_t := 0.0
const DAWN_AFTER := 100.0

func build() -> void:
	title = "SIGHIȘOARA"
	subtitle = "The citadel on the hill · Autumn, Anno MDXXI"
	load_map("sighisoara")
	finale = FinQuest.on()
	quest = FinQuest.new() if finale else SigQuest.new()
	if finale: subtitle = "The citadel on the hill · The wedding of the dead"
	ground = Color("2c3326")
	tile = "tile_grass_village"
	rng = NetRandom.new(1521)
	_citadel = m.lines("citadel")[0]
	building_sets = [[m.boxes("houses"), 0.0], [m.boxes("towers"), 0.0]]
	wall_lines = m.lines("walls")
	scatter(Rect2(Vector2.ZERO, size), 300, [Color("3a402c"), Color("2a2e22"), Color("46443a")])
	var roads := m.lines("roads")
	var east_gate_x: float = m.at(60, 0).x
	for i in roads.size():
		var pts: Array = []
		for rp in roads[i]:
			if rp.x >= east_gate_x or inside(rp, _citadel): pts.append(rp)
		if pts.size() >= 2: add_path(pts, m.road_width[i], Color.WHITE, -990, "Cobbles")
	# the Clock Tower is vaulted over a passage, the only way in or out; the wall stops at its sides
	var gates := []
	for t in m.boxes("towers"):
		if t.name == "Turnul cu Ceas": gates.append(_fixed(t))
	# a small wooden gate in the wall by the Butchers' Tower, so the cellar door outside can be reached
	var door_ref := m.at(-116, -99)
	var pw := _wall_point(door_ref)
	var pdir := _wall_dir(pw)
	pw += pdir * (340.0 if pdir.y < 0.0 else -340.0)   # up the wall to the north, where the road comes in
	var pang := rad_to_deg(atan2(-pdir.y, pdir.x))
	var postern := {"c": pw, "size": Vector2(GAP, 90.0), "angle": pang}
	var cut := gates.duplicate(); cut.append(postern)
	for w in m.lines("walls"):
		for run in _cut_at_gates(w, cut): add_curtain(run, 45.0, 46.0, "ring")
	WoodGate.make(self, pw, GAP, rad_to_deg(-pdir.angle()), "Postern gate")
	for t0 in m.boxes("towers"):
		var t := _fixed(t0)
		var gate: bool = t.name == "Turnul cu Ceas"
		var h := 269.0 if t.style == "clocktower" else (150.0 if t.name == "Turnul Croitorilor" else 125.0)
		add_block_rotated(t.c, t.size, t.angle, t.style, h, not gate)
		if gate: _gate_flanks(t)
	for b in m.boxes("houses"):
		if b.style == "church": add_church(b, 52.0 if b.name.contains("Capela") or b.area < 250.0 else 78.0, not (b.name.contains("Capela") or b.area < 250.0))
		else: _row(b)
	spawn = free_spot(m.at(76, 30), 140.0)   # the open citadel square, Piața Cetății
	_spawn_ref = spawn
	# the covered Scholars' Stairs (Scara Acoperită), 1642, up to the Church on the Hill
	for s in m.lines("stairs"): add_covered_way(Rect2(), s[0], s[s.size() - 1], 130.0)
	_graves()
	_trees()
	_clutter()
	if finale: _finale()
	else: _tutorial()
	for g in gates:
		var dir := _wall_dir(g.c)
		var n := Vector2(-dir.y, dir.x)
		add_torch(g.c + n * (maxf(g.size.x, g.size.y) * 0.6), 260.0, Color(1, 0.62, 0.3), 0.8)
		add_torch(g.c - n * (maxf(g.size.x, g.size.y) * 0.6), 260.0, Color(1, 0.62, 0.3), 0.8)
	add_brazier(m.at(77, 29)).base_energy = 0.7
	add_torch(m.at(84, -10), 220.0, Color(1, 0.55, 0.3), 0.6)      # Casa Vlad Dracul
	add_torch(m.at(-118, -92), 220.0, Color(1, 0.5, 0.25), 0.7)    # Butchers' Tower
	edge_walls()
	# outside the Clock Tower gate only a small yard is open, where Vlad's cart waits
	var ya := m.at(80, -92); var yb := m.at(195, -92)
	add_block(Rect2(ya.x, ya.y, yb.x - ya.x, 40), "hidden", 0)
	var yc := m.at(156, -20); var yd := m.at(195, -20)
	add_block(Rect2(yc.x, yc.y - 40, yd.x - yc.x, 40), "hidden", 0)

func free_ok(p: Vector2, from: Vector2) -> bool:
	# stay off the town wall, and on the same side of it as the spot asked for
	return not near_wall(p, 45.0) and inside(p, _citadel) == inside(from, _citadel)

## The Clock Tower's surveyed outline takes in its annex; the tower itself is narrower.
func _fixed(t: Dictionary) -> Dictionary:
	if t.name != "Turnul cu Ceas": return t
	var f := t.duplicate()
	f.size = Vector2(250, 300)
	return f

## The point of the wall nearest to a spot.
func _wall_point(at: Vector2) -> Vector2:
	var best := INF; var q := at
	for w in m.lines("walls"):
		for i in w.size() - 1:
			var c := Geometry2D.get_closest_point_to_segment(at, w[i], w[i + 1])
			if c.distance_to(at) < best: best = c.distance_to(at); q = c
	return q

## Direction of the wall nearest to a point.
func _wall_dir(at: Vector2) -> Vector2:
	var best := INF; var dir := Vector2.RIGHT
	for w in m.lines("walls"):
		for i in w.size() - 1:
			var d := seg_dist(at, w[i], w[i + 1])
			if d < best and (w[i + 1] - w[i]).length_squared() > 1.0:
				best = d; dir = (w[i + 1] - w[i]).normalized()
	return dir

## Splits a wall line where it runs through a gate tower, into short pieces for the cutaway.
func _cut_at_gates(w: Array, gates: Array) -> Array:
	var runs := []
	var run := []
	for i in w.size() - 1:
		var a: Vector2 = w[i]; var b: Vector2 = w[i + 1]
		var steps := maxi(1, ceili(a.distance_to(b) / 20.0))
		for k in steps + 1:
			if k == 0 and i > 0: continue
			var p := a.lerp(b, k / float(steps))
			var stop := false
			for g in gates:
				if in_box(p, g, 10.0): stop = true
			if stop:
				if run.size() > 1: runs.append(run)
				run = []
				continue
			# keep a corner at the line's own vertices and every ~3 m between them
			if run.is_empty() or k == steps or run[-1].distance_to(p) >= 150.0: run.append(p)
	if run.size() > 1: runs.append(run)
	return runs

## Solid shoulders either side of a gate passage, so the tower can be walked through.
func _gate_flanks(t: Dictionary) -> void:
	var dir := _wall_dir(t.c)
	var wall_angle := rad_to_deg(atan2(-dir.y, dir.x))
	var delta := deg_to_rad(t.angle - wall_angle)
	var along := absf(t.size.x * cos(delta)) + absf(t.size.y * sin(delta))
	var across := absf(t.size.x * sin(delta)) + absf(t.size.y * cos(delta))
	var half := maxf(20.0, (along - GAP) / 2.0)
	for side in [-1.0, 1.0]:
		add_block_rotated(t.c + dir * side * (GAP / 2.0 + half / 2.0), Vector2(half, across), wall_angle, "hidden", 100.0)

## The survey draws a whole street row as one outline: split it into narrow houses of varied height, gable
## after gable, as the citadel's rows really stand.
func _row(b: Dictionary) -> void:
	var la := long_axis(b)
	var axis: Vector2 = la[0]; var length: float = la[1]; var depth: float = la[2]; var long_x: bool = la[3]
	# a deep block is two rows back to back: a house on the street, another on the yard behind
	var rows := 2 if depth > 520.0 else 1
	var row_depth := minf(depth / rows - (40.0 if rows > 1 else 0.0), 480.0)
	var n := maxi(1, roundi(length / (260.0 + rng.f() * 120.0)))
	var seg := length / n
	var across := Vector2(-axis.y, axis.x)
	for row in rows:
		var off := Vector2.ZERO if rows == 1 else across * (-1.0 if row == 0 else 1.0) * (depth / 4.0)
		for i in n:
			var c: Vector2 = b.c + off + axis * (-length / 2.0 + seg * (i + 0.5))
			var w := seg - 6.0
			var h := 44.0 + rng.f() * 18.0
			var sz := Vector2(w, row_depth) if long_x else Vector2(row_depth, w)
			# outlines fitted with boxes poke into the street: shrink a house until every street stays open
			var tries := 0
			var hit := func(s_sz: Vector2) -> bool:
				var r := minf(s_sz.x, s_sz.y) * 0.44
				var d := maxf(s_sz.x, s_sz.y) * 0.32
				return blocks_street(c, s_sz, b.angle, 0.98) or blocked(c, r) or blocked(c + axis * d, r) or blocked(c - axis * d, r)
			while tries < 4 and hit.call(sz):
				sz *= 0.82; tries += 1
			if minf(sz.x, sz.y) < 110.0 or hit.call(sz) or _on_the_square(c, sz, b.angle): continue
			add_block_rotated(c, sz, b.angle, "house", h)

## Piața Cetății stays open: no house stands on the market stalls, the well or the middle of the square.
func _on_the_square(c: Vector2, sz: Vector2, angle: float) -> bool:
	if c.distance_to(m.at(77, 29)) < 560.0: return true
	var box := {"c": c, "size": sz, "angle": angle}
	for q in [[88, 18], [62, 22], [92, 40], [66, 40], [76, 30]]:
		if in_box(m.at(q[0], q[1]), box, 110.0): return true
	return false

func _graves() -> void:
	var n := 0
	for cem in m.lines("cemeteries"):
		var bb := bounds(cem)
		var x := bb.position.x
		while x < bb.end.x and n < 140:
			var y := bb.position.y
			while y < bb.end.y and n < 140:
				var p := Vector2(x + rng.f() * 20.0, y + rng.f() * 20.0)
				y += 90.0
				if p.x < 40.0 or p.y < 40.0 or p.x > size.x - 40.0 or p.y > size.y - 40.0 or not inside(p, cem): continue
				add_block(Rect2(p.x - 9, p.y - 4, 18, 8), "stone", 14.0 + rng.f() * 8.0)
				n += 1
			x += 70.0

func _trees() -> void:
	var lt0 := m.at(135, 60); var lt1 := m.at(260, -175)
	var n := 0
	var x := 120.0
	while x < size.x - 120.0:
		var y := 120.0
		while y < size.y - 120.0:
			if n >= 260: return
			var p := Vector2(x + (rng.f() - 0.5) * 240.0, y + (rng.f() - 0.5) * 240.0)
			y += 340.0
			var wood := false
			for w in m.lines("woods"):
				if inside(p, w):
					wood = true
					break
			if not wood and inside(p, _citadel): continue
			if p.x > lt0.x and p.y > lt0.y and p.y < lt1.y: continue   # the lower town
			if not wood and rng.f() < 0.35: continue
			if near_road(p, 70.0) or near_building(p, 90.0) or near_wall(p, 120.0): continue
			add_tree(p, rng.f() < 0.2)
			n += 1
		x += 340.0

## Barrels, firewood, carts and crows against the house fronts, off the cobbles; market stalls and a well on
## the citadel square.
func _clutter() -> void:
	add_decor(m.at(66, 40), "well", 45.0)
	add_decor(m.at(88, 18), "stall", 55.0)
	add_decor(m.at(62, 22), "stall", 55.0, true)
	add_decor(m.at(92, 40), "stall", 55.0)
	var total := 0.0
	for c in CLUTTER: total += c[2]
	var roads := m.lines("roads")
	var n := 0
	for i in roads.size():
		if n >= 420: break
		var width: float = m.road_width[i]
		if width < 140.0: continue
		var road: Array = roads[i]
		var next := 200.0 + rng.f() * 400.0
		for k in road.size() - 1:
			if n >= 420: break
			var a: Vector2 = road[k]; var b: Vector2 = road[k + 1]
			var length := a.distance_to(b)
			if length < 1.0: continue
			var dir := (b - a) / length; var nrm := Vector2(-dir.y, dir.x)
			var s := next
			while s < length:
				var side := -1.0 if rng.f() < 0.5 else 1.0
				var p := a + dir * s + nrm * side * (width / 2.0 + 40.0)
				next = s
				var skip := p.distance_to(_spawn_ref) < 200.0 or p.x < 60.0 or p.y < 60.0 or p.x > size.x - 60.0 or p.y > size.y - 60.0
				if not skip and p.x < m.at(60, 0).x and not inside(p, _citadel): skip = true
				if not skip: skip = near_road(p, -10.0) or near_building(p, 4.0) or near_wall(p, 40.0)
				if not skip:
					var pick := rng.f() * total
					var c: Array = CLUTTER[0]
					for cc in CLUTTER:
						pick -= cc[2]
						if pick <= 0.0:
							c = cc
							break
					add_decor(p, c[0], c[1], rng.f() < 0.5)
					n += 1
				s += 260.0 + rng.f() * 320.0
			next = maxf(0.0, next - length)

## The camera-facing front of the house nearest to g.
func _facade(g: Vector2) -> Vector2:
	var best: Dictionary = m.boxes("houses")[0]; var bd := INF
	for b in m.boxes("houses"):
		if g.distance_to(b.c) < bd:
			bd = g.distance_to(b.c); best = b
	var p: Vector2 = best.c
	while in_box(p, best, 2.0): p.y += 4.0
	p.x = clampf(g.x, p.x - best.size.x * 0.3, p.x + best.size.x * 0.3)
	while in_box(p, best, 2.0): p.y += 4.0
	return p

## A free spot that can be walked to in a straight line from where the hunter starts: the people and the
## notice board of the opening job all stand in the open on the square.
func _on_square(g: Vector2, clear: float) -> Vector2:
	var ok := func(p: Vector2) -> bool:
		return not blocked(p, clear) and not near_building(p, clear) and not near_wall(p, 45.0) and line_clear(spawn, p)
	if ok.call(g): return g
	var r := 30.0
	while r <= 700.0:
		for k in 16:
			var p := g + Vector2.from_angle(k * PI / 8.0) * r
			if ok.call(p): return p
		r += 30.0
	return free_spot(g, clear)

## The bacon thieves: the butcher on the square, the clues and the cellar at the Butchers' Tower.
func _tutorial() -> void:
	var at := func(x: float, y: float) -> Vector2: return free_spot(m.at(x, y))
	# Azorel waits by the hunter on the square; the notice board; Vlad's cart for the road east
	add_prop("npc", "azorel", "Azorel", _on_square(m.at(76, 30) + Vector2(-90, 60), 50.0), "E   Speak to Azorel", Color("d8d0c0"))
	var nb := _on_square(m.at(76, 30) + Vector2(220, -60), 60.0)
	add_decor(nb + Vector2(0, -16), "notice_board", 20.0)
	add_prop("task", "notice", "Notice board", nb, "E   Read the notice board")
	add_prop("npc", "vlad", "Vlad Laurențiu · Merchant", at.call(150, -62), "E   Speak with Vlad Laurențiu", Color("4a5a6a"))
	add_decor(at.call(160, -70), "horse_cart", 70.0)   # Vlad's căruță, horse and all
	var tr: Vector2 = at.call(135, -82)   # a troiță by the road out of the gate yard
	add_decor(tr, "troita", 22.0)
	add_prop("troita", "troita", "Troiță", tr + Vector2(0, 30), "E   Pray at the troiță")
	# Meister Thomas keeps his stall on the square until he hands out the job, then waits at the tower
	var at_square := _on_square(m.at(86, 12), 40.0)
	butcher_at_tower = at.call(-92, -76)
	butcher = add_prop("npc", "butcher", "Meister Thomas · Guild master", butcher_at_tower if G.side_has("sig_job") else at_square, "E   Speak with Meister Thomas", Color("6a3a30"))
	var face := _facade(m.at(86, -8))   # hung on the house front, facing the square
	_dracul_house(face)
	add_decor(face, "portrait")
	add_prop("task", "portrait", "Casa Vlad Dracul", face + Vector2(0, 26), "E   Look into Casa Vlad Dracul")
	# the butchers' quarter by the tower
	var wife: Vector2 = at.call(-100, -80)
	add_prop("npc", "butcherwife", "Frau Gertrud", wife, "E   Speak with Frau Gertrud", Color("5a4a5a"))
	# Mihai plays by the woodpile behind Gertrud's kitchen, a few steps from the tower
	var mihai_at := free_spot(wife + Vector2(180, -40), 75.0)
	add_prop("npc", "child", "Mihai", mihai_at, "E   Speak with Mihai", Color("6a5a40"))
	var hearth := free_spot(wife + Vector2(-60, -40))
	add_decor(hearth + Vector2(0, -12), "hearth", 26.0)
	add_prop("task", "hearth", "Hearth", hearth, "E   Look at the hearth")
	add_torch(wife + Vector2(-60, -40), 160.0, Color(1, 0.55, 0.25), 0.6)
	for c in [["flour", -97, -86, "flour"], ["grating", -107, -91, "grating"], ["hook", -91, -97, "hook_wall"]]:
		var cp: Vector2 = at.call(c[1], c[2])
		if c[0] == "hook":
			var hw := wall_door(cp, 320.0, func(p): return inside(p, _citadel) and not near_wall(p, 55.0))
			if hw != cp: cp = hw + Vector2(0, 14)
		add_decor(cp + Vector2(0, -8), c[3])
		add_prop("clue", c[0], "", cp, "E   Examine")
	var smoke_at: Vector2 = at.call(-112, -114)
	add_decor(smoke_at + Vector2(0, -6), "grating").smoke = true   # the cellar breathes out through the street
	add_prop("clue", "smoke", "", smoke_at, "E   Examine")
	var cd0: Vector2 = at.call(-116, -99)
	cellar_door = cellar_tower(cd0, 500.0, func(p): return inside(p, _citadel) and not near_wall(p, 90.0))   # the way down, in a cellar tower
	var cw := cellar_door - Vector2(0, 16)
	add_prop("task", "cellar", "Cellar door", cellar_door, "E   Try the cellar door")
	var gs: Vector2 = cw + Vector2(170, 8)   # the guild's sign hangs beside the cellar door
	add_decor(gs + Vector2(0, -10), "guild_sign")
	add_prop("task", "sign", "Guild sign", gs + Vector2(0, 14), "E   Look at the guild sign")
	var crate: Vector2 = free_spot(cw + Vector2(96, 26), 38.0)
	add_decor(crate + Vector2(0, -14), "crate", 16.0)
	add_prop("task", "crate", "Crate", crate, "E   Look at the crate")

## After giving the job Meister Thomas walks down to the tower, so the rest of the quest stays there.
func butcher_to_tower() -> void:
	butcher.walk(find_path(butcher.pos, butcher_at_tower, 8.0, butcher), 70.0)
	spots["butcher"] = butcher_at_tower


# ------------------------------------------------------------------ act 3: the last night and the morning after

func ambient() -> Color:
	if not finale: return super()
	if night: return Color(0.2, 0.22, 0.34)
	if G.side_has("fin_dawn"): return Color(0.88, 0.68, 0.5)   # sunrise on a wedding morning
	return Color(0.95, 0.9, 0.82).lerp(Color(0.12, 0.14, 0.3), 0.7)

func _finale() -> void:
	var has := func(f: String) -> bool: return G.side_has(f)
	var sq := m.at(76, 30)
	var at := func(x: float, y: float) -> Vector2: return free_spot(m.at(x, y))
	follower = add_prop("npc", "azorel", "Azorel", _on_square(sq + Vector2(-90, 60), 50.0), "E   Azorel", Color("d8d0c0"))
	var tr: Vector2 = at.call(135, -82)
	add_decor(tr, "troita", 22.0)
	add_prop("troita", "troita", "Troiță", tr + Vector2(0, 30), "E   Pray at the troiță")
	# the spiriduși at the Butchers' Tower, and Meister Thomas
	var bt: Vector2 = at.call(-92, -76)
	add_prop("npc", "captain", "The spiriduș captain", bt + Vector2(70, 40), "E   Speak with the captain")
	add_prop("npc", "butcher", "Meister Thomas · Guild master", bt, "E   Speak with Meister Thomas", Color("6a3a30"))
	add_decor(bt + Vector2(-80, -10), "hams_rack", 30.0)
	# the baron, at the house with the dragon on its sign
	var face := _facade(m.at(86, -8))
	_dracul_house(face)
	add_decor(face, "portrait")
	var dawn: bool = has.call("fin_dawn")
	# before he hands over the key he is inside the house; afterwards he comes out onto the square
	if has.call("fin_lorena"):
		add_prop("npc", "baron", "The baron of Biertan", _on_square(sq + Vector2(160, -40), 50.0), "E   Speak with the baron", Color("5a2030"))
	add_prop("task", "dracul_door", "Casa Vlad Dracul", dracul_door, "E   Go into the house with the dragon")
	# the Tinsmiths' Tower, hung with garlic from the inside
	var tw := Vector2.ZERO
	for t in m.boxes("towers"):
		if t.name == "Turnul Cositorarilor": tw = t.c
	var door := free_spot(tw + Vector2(0, -150), 40.0)
	add_decor(door + Vector2(-40, -20), "garlic_braid"); add_decor(door + Vector2(40, -20), "garlic_braid", 0.0, true)
	add_prop("task", "tower", "The Tinsmiths' Tower", door, "E   Unlock the tower")
	if has.call("fin_lorena"): lorena_p = add_prop("npc", "lorena", "Lorena", _on_square(sq + Vector2(40, 90), 50.0), "E   Speak with Lorena", Color("5a3a30"))
	# the Clock Tower bell
	var clock := Vector2.ZERO
	for t in m.boxes("towers"):
		if t.style == "clocktower": clock = t.c
	add_decor(free_spot(clock + Vector2(-160, 120), 30.0), "bell_rope")
	add_prop("task", "bell", "The Clock Tower bell", free_spot(clock + Vector2(-160, 160), 30.0), "E   Ring the bell")
	if dawn:
		# the wedding of the dead wants three things
		var cart: Vector2 = at.call(150, -62)
		add_decor(at.call(160, -70), "haycart", 55.0)
		add_prop("npc", "bvlad", "Vlad Laurențiu", cart, "E   Speak with Vlad")
		add_prop("npc", "bmagda", "Magda", cart + Vector2(110, 0), "E   Speak with Magda")
		add_prop("npc", "finpriest", "Father Bálint", _on_square(sq + Vector2(-240, -80), 50.0), "E   Wake the priest", Color("3a3430"))
		var j := _on_square(sq + Vector2(260, 80), 60.0)
		add_decor(j + Vector2(0, -30), "joimarita", 20.0)
		add_prop("task", "joimarita", "Joimărița", j + Vector2(0, 40), "E   Speak with Joimărița")
	var st: Array = m.lines("stairs")[0]
	add_prop("task", "stair", "The Scholars' Stair", free_spot(st[0] + (st[1] - st[0]).normalized() * 120.0, 40.0), "E   Climb to the Church on the Hill")

func _process(dt: float) -> void:
	super(dt)
	if not finale or not is_instance_valid(G.player): return
	var pl: Player = G.player
	if not G.side_has("fin_arrive") and G.state == G.State.PLAY and not G.transitioning:
		_fin_t += dt
		if _fin_t > 0.6: quest.arrive()
	if is_instance_valid(follower):   # Azorel, limping, half a pace ahead
		var to := pl.pos + Vector2(50, 20) - follower.pos
		if to.length() > 60.0: follower.pos += to.limit_length(200.0 * dt)
	if not night or G.state != G.State.PLAY: return
	bell_cd = maxf(0.0, bell_cd - dt)
	night_t += dt
	if night_t >= DAWN_AFTER and is_instance_valid(mort): mort_down(mort)

func midnight() -> void:
	night = true; night_t = 0.0
	WorldBuilder.apply_darkness(self)
	var b := _prop("baron")
	var at := b.pos if b else spawn
	if b: remove_prop(b)
	Audio.sfx("bell", -2.0, 0.6)
	Hud.banner("MIDNIGHT", "He warned you. Hold him until first light. The Clock Tower bell pins him.")
	mort = spawn_enemy("strigoi_mort", at, VampireBoss)
	Audio.set_music("music_vlad", -6.0)

func night_line() -> String:
	return "Hold him until first light. Ring the Clock Tower bell to pin him, then strike. (Dawn in %d s)" % ceili(maxf(0.0, DAWN_AFTER - night_t))

func bell_ready() -> bool: return night and is_instance_valid(mort) and mort.stun_t2 <= 0.0 and bell_cd <= 0.0

func ring_bell() -> void:
	if not night or not is_instance_valid(mort):
		G.start_dialogue("The Clock Tower bell", ["The rope of the great bell. Seven wooden figures up there keep the days of the week; tonight they are all looking down."])
		return
	if bell_cd > 0.0:
		Hud.toast("The bell is still swinging back.")
		return
	bell_cd = 8.0
	mort.stun_t2 = 4.5
	Audio.sfx("bell", 0.0, 0.6)
	Fx.shake(0.3)
	Fx.ring(mort.pos, Color(1, 0.85, 0.5, 0.9), 140.0, 0.6)
	Hud.toast("DONG. The bell's voice pins him where he stands. Strike!")

## Worn down, or simply outlasted: either way the sky is going grey.
func mort_down(v: VampireBoss) -> void:
	if not night: return
	night = false
	G.boss = null
	var at := v.pos
	v.queue_free()
	mort = null
	G.side_add("fin_dawn")
	G.start_dialogue("First light", [
		"(Grey over the Clock Tower. A cock, somewhere in the lower town. The thing in front of you stops in the middle of a step, like a man who has forgotten why he came into a room.)",
		"(Then it is only him again. On his knees on the cobbles, in a coat two hundred years old, with a bandaged hand.)",
		"The baron: Did I hurt anyone? (No.) You are sure. (Yes.) ...Thank you. That is twice I have had to ask a stranger that. I do not want there to be a third.",
		"Two hundred years, hunter. I never asked for one of them. All I ever wanted was to stand up in a church beside somebody.",
		"Lorena, from the tower steps, with her arms folded: Then somebody had better bury him properly. As a groom. It is what he is owed, and it is the only thing that will hold.",
		"(The wedding of the dead: the unmarried are buried in their wedding clothes, with a fir tree standing where the bride should. Biertan refused it to him in 1321.)",
		"The baron: (very quietly) I should like that. If it is not too much trouble.",
	], func():
		G.player.coins += 50
		Audio.set_music("music_hub", -9.0)
		Hud.toast("A wedding of the dead wants a fir tree, a priest and a table.")
		Loader.goto_level("sighisoara", at))

func _prop(pid: String) -> Prop:
	for p in props:
		if is_instance_valid(p) and p.id == pid: return p
	return null

## Casa Vlad Dracul stands out on the square: ochre walls, a dark roof, the dragon sign over the door, lamps.
func _dracul_house(face: Vector2) -> void:
	var best: Dictionary = {}; var bd := INF
	for b in blocks:
		if b.style == "house" and b.c.distance_to(face) < bd:
			bd = b.c.distance_to(face); best = b
	if not best.is_empty():
		best["dracul"] = true
		best.h = maxf(best.h, 64.0)
	dracul_door = face + Vector2(60, 10)
	add_decor(face + Vector2(-70, -4), "guild_sign")
	add_decor(face + Vector2(130, 6), "lamp_lit")
	add_torch(face + Vector2(60, 30), 260.0, Color(1, 0.6, 0.3), 0.8)
