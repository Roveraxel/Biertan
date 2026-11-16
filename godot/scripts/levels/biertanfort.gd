## Biertan (Birthälm): the covered stair up the hill, three rings of wall, the marriage prison against the
## outer wall, and the hall church on top. By day it is a busy, friendly place with the baron's table laid in
## the middle ring; by night (once the hunter has said what the baron is) the gates shut and each ring has its guard.
extends Level

const K := 1.5   # the fortress was first laid out at two thirds of this size; absolute points below are scaled by K
const C := Vector2(1950, 1725)
const RX := [1575.0, 1080.0, 630.0]
const RY := [1350.0, 900.0, 480.0]
const GATE_DEG := [90.0, 20.0, 270.0]
const HEIGHT := [34.0, 42.0, 54.0]
const GATE_WIDTH := 150.0

var gates: Array[Gate] = []
var guard: Array = [[], [], []]
var spouse1: Prop
var spouse2: Prop
var _arrive_t := 0.0

static func on_ring(i: int, deg: float, extra := 0.0) -> Vector2:
	var a := deg_to_rad(deg)
	return C + Vector2((RX[i] + extra) * cos(a), (RY[i] + extra) * sin(a))

static func in_band(i: int, deg: float, t := 0.5) -> Vector2:
	var a := deg_to_rad(deg)
	var rx: float = lerpf(RX[i + 1], RX[i], t) if i < 2 else lerpf(420.0, RX[2], t)
	var ry: float = lerpf(RY[i + 1], RY[i], t) if i < 2 else lerpf(220.0, RY[2], t)
	return C + Vector2(rx * cos(a), ry * sin(a))

func ambient() -> Color:
	return Color(0.95, 0.9, 0.82).lerp(Color(0.12, 0.14, 0.3), 0.85 if BtQuest.night() else 0.35)

func build() -> void:
	var night := BtQuest.night()
	title = "BIERTAN"
	subtitle = "Birthälm · The Locked Door" if night else "Birthälm · The Baron's Table"
	size = Vector2(2600, 2900) * K
	spawn = Vector2(1300, 2780) * K
	ground = Color("262a20")
	quest = BtQuest.new()
	rng = NetRandom.new(1519)
	var has := func(f: String) -> bool: return G.side_has(f)
	var road := [Vector2(1300, 2900), Vector2(1300, 2820), Vector2(800, 2680), Vector2(650, 2520), Vector2(1000, 2400),
		Vector2(1650, 2330), Vector2(1800, 2240), Vector2(1500, 2170), Vector2(1300, 2150), Vector2(1300, 2050)]
	road = road.map(func(v): return v * K)
	for d in [75.0, 55.0, 35.0, 20.0]: road.append(in_band(0, d))
	road.append(on_ring(1, 20.0))
	for d in [0.0, -25.0, -50.0, -75.0, -90.0]: road.append(in_band(1, d))
	road.append(on_ring(2, 270.0))
	for d in [285.0, 320.0, 350.0, 15.0, 45.0, 75.0, 90.0]: road.append(in_band(2, d))
	add_path(road, 110.0)
	scatter(Rect2(Vector2.ZERO, size), 2600, [Color("333a28"), Color("1a1e16"), Color("44463a")])
	for d in [145.0, 155.0, 165.0, 175.0, 185.0, 195.0, 205.0, 215.0, 228.0, 240.0, 250.0]:   # graves in the middle band
		var g := in_band(1, d)
		add_block(Rect2(g.x - 9, g.y - 4, 18, 8), "stone", 14.0 + rng.f() * 8.0)
	add_block(Rect2(-200, -200, size.x + 400, 200), "hidden", 0.0)
	add_block(Rect2(-200, size.y, size.x + 400, 200), "hidden", 0.0)
	add_block(Rect2(-200, -200, 200, size.y + 400), "hidden", 0.0)
	add_block(Rect2(size.x, -200, 200, size.y + 400), "hidden", 0.0)
	for i in 3:
		var gw := rad_to_deg(GATE_WIDTH / 2.0 / ((RX[i] + RY[i]) / 2.0))
		var pts := []
		var d: float = GATE_DEG[i] + gw
		while d <= GATE_DEG[i] + 360.0 - gw + 0.01:
			pts.append(on_ring(i, d))
			d += 360.0 / 64.0
		pts.append(on_ring(i, GATE_DEG[i] + 360.0 - gw))
		add_curtain(pts, 34.0 + i * 4.0, HEIGHT[i], "arches" if i == 1 else "ring")
		var a := deg_to_rad(GATE_DEG[i])
		var tangent := Vector2(-RX[i] * sin(a), RY[i] * cos(a))
		var gate := Gate.make(self, on_ring(i, GATE_DEG[i]), Vector2(GATE_WIDTH + 10.0, 40.0), -rad_to_deg(tangent.angle()))
		gates.append(gate)
		if not night or has.call("bt_bolt%d" % i): gate.open()
		add_torch(on_ring(i, GATE_DEG[i], 70.0), 200.0, Color(1, 0.45, 0.3), 0.6)
		for s in [-1.0, 1.0]:
			var tw := on_ring(i, GATE_DEG[i] + s * (gw + 4.0))
			add_block(Rect2(tw.x - 40, tw.y - 40, 80, 80), "tower", 80.0 + i * 20.0)
	for d in [30.0, 150.0, 210.0, 330.0]:
		var tw := on_ring(0, d)
		add_block(Rect2(tw.x - 45, tw.y - 45, 90, 90), "tower", 90.0)
	var clock := on_ring(2, 270.0, -70.0)
	add_block(Rect2(clock.x - 150, clock.y - 50, 70, 70), "tower", 170.0)
	var maus := on_ring(2, 300.0); add_block(Rect2(maus.x - 45, maus.y - 45, 90, 90), "tower", 120.0)
	var cath := on_ring(2, 60.0); add_block(Rect2(cath.x - 45, cath.y - 45, 90, 90), "tower", 120.0)
	var bell := in_band(2, 230.0, 0.35); add_block(Rect2(bell.x - 35, bell.y - 35, 70, 70), "tower", 150.0)
	add_block(Rect2(C.x - 300, C.y - 130, 600, 260), "church", 70.0)
	add_block(Rect2(C.x - 380, C.y - 70, 90, 140), "tower", 130.0)
	add_brazier(Vector2(C.x - 110, C.y + 175))
	add_brazier(Vector2(C.x + 110, C.y + 175))
	add_torch(Vector2(C.x, C.y + 170), 240.0, Color(1, 0.6, 0.35), 0.8)
	add_prop("task", "church", "The church door", Vector2(C.x, C.y + 160), "E   Enter the church")
	var stair_top := on_ring(0, 90.0).y + 30.0
	add_covered_way(Rect2(C.x - 130, stair_top, 260, 2200.0 * K - stair_top))
	for k in 200:
		var p := Vector2(rand(40, size.x - 40), rand(40, size.y - 40))
		var dx := (p.x - C.x) / (RX[0] + 70.0); var dy := (p.y - C.y) / (RY[0] + 70.0)
		if dx * dx + dy * dy < 1.0 or _road_dist(p, road) < 110.0: continue
		add_tree(p, true)
	add_prop("task", "down", "Back down the hill", Vector2(1300, 2860) * K, "E   Go back down to the road")
	# the marriage prison: a little tower against the outer wall, west of the gate
	var prison := in_band(0, 125.0, 0.75)
	add_block(Rect2(prison.x - 50, prison.y - 50, 100, 100), "tower", 95.0)
	add_prop("task", "prison", "The marriage prison", prison + Vector2(0, 75), "E   The marriage prison")
	if not night:
		var inw := (C - prison).normalized() * 190.0   # in front of the prison, toward the middle: clear of the wall
		spouse1 = add_prop("npc", "spouse1", "A husband", prison + inw + Vector2(-60, 0), "E   Talk to them", Color("6a5a4a"))
		spouse2 = add_prop("npc", "spouse2", "A wife", prison + inw + Vector2(60, 10), "E   Talk to them", Color("7a5a5a"))
	if night: _guards()
	else: _day()

## Biertan by day: the market at the foot of the stair, the baron's table by the church, one thing in each wall.
func _day() -> void:
	var has := func(f: String) -> bool: return G.side_has(f)
	var fled: bool = has.call("bt_fled")
	for it in [["market1", "A woman with a basket", Vector2(1040, 2700) * K], ["market2", "The chestnut seller", Vector2(1560, 2730) * K], ["market3", "An old man", Vector2(930, 2560) * K]]:
		add_prop("npc", it[0], it[1], it[2], "E   Talk")
	add_decor(Vector2(1610, 2700) * K, "barrel"); add_decor(Vector2(1000, 2760) * K, "crate"); add_decor(Vector2(880, 2600) * K, "bench")
	add_torch(Vector2(1300, 2650) * K, 420.0, Color(1, 0.75, 0.5), 0.6)
	# Vlad and Magda, by the old graves in the middle ring (at the foot of the stair once it is over)
	var gr := in_band(1, 195.0)
	add_prop("task", "grave", "An old grave", gr + Vector2(0, 30), "E   Look at the grave")
	var cart := Vector2(1480, 2800) * K if fled else gr + Vector2(150, 60)
	add_decor(cart + Vector2(0, -40), "handcart", 30.0)
	var v := add_prop("npc", "bvlad", "Vlad Laurențiu", cart + Vector2(-55, 30), "E   Speak with Vlad")
	var mg := add_prop("npc", "bmagda", "Magda", cart + Vector2(55, 30), "E   Speak with Magda")
	v.facing = Vector2(1, 0); mg.facing = Vector2(-1, 0)
	add_decor(in_band(0, 62.0), "kennel", 26.0)
	add_prop("clue", "kennel", "A kennel", in_band(0, 62.0) + Vector2(0, 50), "E   Look at the kennel")
	# the sexton's house in the inner ring, the best house inside the walls
	var sh := in_band(2, 150.0)
	add_block(Rect2(sh.x - 70, sh.y - 55, 140, 110), "house", 48.0)
	add_prop("task", "ledger", "The sexton's house", sh + Vector2(0, 85), "E   Look inside")
	if fled: return
	# the baron's table
	var tb := in_band(1, 62.0)
	# his supper terrace: a paved court of its own in the middle ring, lanterns on posts at its corners
	add_cobbles(Rect2(tb - Vector2(250, 140), Vector2(500, 260)))
	for cx in [-230.0, 230.0]:
		for cy in [-125.0, 105.0]:
			add_decor(tb + Vector2(cx, cy), "lantern_iron", 10.0)
			add_torch(tb + Vector2(cx, cy - 10.0), 160.0, Color(1, 0.7, 0.4), 0.5)
	add_decor(tb + Vector2(-160, 95), "bench", 20.0); add_decor(tb + Vector2(160, 95), "bench", 20.0, true)
	add_decor(tb, "long_feast", 50.0)
	add_decor(tb + Vector2(-90, -10), "wine_mug")
	add_torch(tb, 380.0, Color(1, 0.7, 0.4), 0.8)
	add_prop("clue", "salt", "The baron's table", tb + Vector2(-140, 70), "E   Look at the table")
	add_prop("clue", "wine", "The baron's cup", tb + Vector2(120, 70), "E   Look at his cup")
	add_decor(in_band(1, 38.0), "oven", 40.0)
	add_prop("clue", "garlic", "The kitchen", in_band(1, 38.0) + Vector2(0, 60), "E   Look round the kitchen")
	for i in 3: add_prop("npc", "servant", "A servant", tb + Vector2(-160 + i * 160, -95), "E   Talk")
	add_prop("clue", "servant", "The servants", tb + Vector2(0, -60), "E   Look at the servants")
	var at_door: bool = has.call("bt_supper")
	var where := Vector2(1300, 2540) * K
	if has.call("bt_invited"): where = tb + Vector2(230, 20)
	if at_door: where = Vector2(C.x - 80, C.y + 200)
	add_prop("npc", "baron", "The baron of Biertan", where, "E   Speak with the baron", Color("5a2030"))
	add_prop("npc", "bsexton", "The sexton", Vector2(C.x - 200, C.y + 205) if at_door else sh + Vector2(110, 80), "E   Speak with the sexton", Color("3a3430"))

## The baron walks up to his table once the hunter has been asked.
func seat_baron() -> void:
	var b := _prop("baron")
	if b: b.pos = in_band(1, 62.0) + Vector2(230, 20)
	spots["baron"] = in_band(1, 62.0) + Vector2(230, 20)

func _prop(pid: String) -> Prop:
	for p in props:
		if is_instance_valid(p) and p.id == pid: return p
	return null

## Biertan by night: the guards of the three walls.
func _guards() -> void:
	var has := func(f: String) -> bool: return G.side_has(f)
	if not has.call("bt_bolt0"):
		# each wall's guards wait in front of its gate, on the side the hunter comes from
		for i in 3: _guard(0, "thrall", on_ring(0, 72.0 + i * 12.0, 170.0))
		var lair := on_ring(0, 55.0, 330.0)
		for o in [Vector2(-120, -60), Vector2(110, -90), Vector2(150, 70), Vector2(-90, 100)]:
			var w := _guard(0, "wolf", lair + o)
			w.aggro = 1.0; w.flee_low = true
			w.fled.connect(func(_e): _guard_down(0))
		add_trigger(Rect2(lair.x - 260, lair.y - 220, 520, 440), func():
			var any := false
			for e in guard[0]:
				if is_instance_valid(e) and e.kind == "wolf" and e.aggro < 10.0:
					e.aggro = 3000.0; e.state = "chase"; any = true
			if any:
				Audio.sfx("howl", -6.0, 0.9)
				Hud.toast("Rot-eyed wolves rise out of the bracken."))
	if not has.call("bt_bolt1"):
		for d in [-5.0, 12.0, 30.0, 45.0]:
			var gp := in_band(0, d, 0.45)
			add_block(Rect2(gp.x - 9, gp.y - 34, 18, 8), "stone", 16.0)   # the old graves by the middle gate, where they rise
			_guard(1, "moroi", gp)
		for d in [5.0, 38.0]: _guard(1, "strigoi", in_band(0, d, 0.6))
	if not has.call("bt_bolt2"):
		for d in [250.0, 290.0]: _guard(2, "thrall", in_band(1, d))   # the baron's grey servants
		var s := _guard(2, "sexton", in_band(1, 270.0, 0.6))
		s.hp = 260.0; s.max_hp = 260.0; s.dmg = 18.0
		s.flee_low = true   # he does not stay to lose
		s.fled.connect(func(_e):
			Hud.toast("The sexton drops his keys and runs for the wall.")
			_guard_down(2))
		s.call_thralls.connect(func(_e):
			for o in [Vector2(-120, 0), Vector2(120, 0)]: _guard(2, "thrall", in_band(1, 270.0, 0.6) + o))

func _guard(ring: int, kind: String, g: Vector2) -> Enemy:
	var e := spawn_enemy(kind, g)
	guard[ring].append(e)
	if kind != "wolf" or ring != 0: e.died.connect(func(_e): _guard_down(ring))
	spots["guard%d" % ring] = g
	return e

func _guard_down(ring: int) -> void:
	for e in guard[ring]:
		if is_instance_valid(e) and e.hp > 0.0 and not e.fleeing and not e.fainted: return
	if G.side_has("bt_bolt%d" % ring): return
	G.side_add("bt_bolt%d" % ring)
	gates[ring].open()
	Audio.sfx("ward")
	Hud.banner("THE %s GATE OPENS" % ["OUTER", "MIDDLE", "INNER"][ring],
		["The wolves are gone into the bracken. Up by the middle gate, the old graves are not quiet.", "The graves are still. Above you, the baron's own servants line the inner wall.", "The last gate. The church door stands in front of you, and behind it the door of 1515."][ring])

func reconciled() -> void:
	var prison := in_band(0, 125.0, 0.75)
	var inw := (C - prison).normalized() * 260.0
	if is_instance_valid(spouse1): spouse1.pos = prison + inw + Vector2(-30, 0)
	if is_instance_valid(spouse2): spouse2.pos = prison + inw + Vector2(30, 0)
	spots["spouse1"] = prison + inw + Vector2(-30, 0)

func _process(dt: float) -> void:
	super(dt)
	var due := not G.side_has("bt_arrive") or (BtQuest.night() and not G.side_has("bt_night_seen"))
	if not due or G.state != G.State.PLAY or G.transitioning:
		_arrive_t = 0.0
		return
	_arrive_t += dt
	if _arrive_t > 0.6: quest.arrive()

func _road_dist(p: Vector2, road: Array) -> float:
	var best := INF
	for i in road.size() - 1: best = minf(best, dist_to_segment(p, road[i], road[i + 1]))
	return best
