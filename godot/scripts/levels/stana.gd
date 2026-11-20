## The prologue: a high pasture above Sibiu on the last evening of summer. The hunter has spent the season
## minding animals with Azorel, his Carpathian shepherd dog. He dozes on the hill until Azorel licks him awake;
## then he drives the cows back into the stână before dark, closes the gate, and a wolf pack comes out of the
## spruce. Walking, the dash, E and the blade are learned here, one at a time. Next morning they go down to
## the valley, and the road starts in Sighișoara.
extends Level

const HILL := Vector2(650, 620)
const FOLD := Rect2(1900, 1050, 640, 440)
const GATE := Vector2(1900, 1270)
const GATE_HALF := 95.0
const WOLF_FROM := Vector2(2860, 420)

var step := 0            # 0 asleep, 1 herding, 2 wolves, 3 done
var cows: Array[Enemy] = []
var wolves: Array[Enemy] = []
var roused := {}
var azorel: Prop
var gate: Prop
var zzz_t := 0.0
var hint_t := 0.0
var bite_t := 0.0
var hint := 0
var azorel_coming := false
var wolves_come := false
var gate_open := false
var _gap: Array = []          # the wattle hurdles that make the shut gate
var _cow_path := {}
var _cow_t := {}

func build() -> void:
	title = "THE STÂNĂ"
	subtitle = "High pasture above Sibiu, the last evening of summer"
	size = Vector2(3000, 2200)
	spawn = HILL
	ground = Color("1a2416")
	rng = NetRandom.new(77)
	scatter(Rect2(Vector2.ZERO, size), 700, [Color("222e1c"), Color("141c12")])
	var road := [HILL + Vector2(60, -40), Vector2(1200, 900), Vector2(1650, 1220), GATE + Vector2(-30, 0)]
	add_path(road, 70.0)
	# spruce all round the high pasture, a few standing alone on the grass
	var keep_out := FOLD.grow(180.0)
	for i in 260:
		var p := Vector2(rand(0.0, size.x), rand(0.0, size.y))
		var edge := p.x < 260.0 or p.x > size.x - 260.0 or p.y < 230.0 or p.y > size.y - 230.0
		if not edge and rand(0.0, 1.0) > 0.06: continue
		if p.distance_to(HILL) < 280.0 or keep_out.has_point(p): continue
		var on_road := false
		for j in road.size() - 1:
			if Geometry2D.get_closest_point_to_segment(p, road[j], road[j + 1]).distance_to(p) < 85.0:
				on_road = true; break
		if on_road: continue
		add_tree(p, true)
	_fence(false)
	_fence(true)   # the gate starts shut: the hunter opens it himself
	add_block(Rect2(FOLD.end.x - 220.0, FOLD.position.y + 30.0, 180.0, 120.0), "house", 46.0).timber = true   # the shepherds' hut
	add_brazier(Vector2(FOLD.end.x - 130.0, FOLD.position.y + 220.0))
	add_decor(FOLD.position + Vector2(120, 80), "haystack_plain", 30.0)
	add_decor(FOLD.position + Vector2(280, 70), "livestock_trough", 20.0)
	add_decor(FOLD.position + Vector2(190, 140), "butter_churn", 12.0)
	add_decor(FOLD.position + Vector2(240, 145), "cheese_wheel", 10.0)
	add_decor(FOLD.end + Vector2(-60, -60), "firewood", 20.0)
	add_decor(HILL + Vector2(-70, 20), "stubs")
	for c in [Vector2(1050, 480), Vector2(1450, 360), Vector2(480, 1320), Vector2(1100, 1520), Vector2(1550, 1820), Vector2(2350, 1880)]:
		var cow := spawn_enemy("cow", c)
		cow.harmless = true   # nobody takes a blade to the cows he is paid to mind
		cows.append(cow)
	azorel = add_prop("npc", "azorel", "Azorel", Vector2(1350, 900), "", Color("d8d0c0"))
	add_decor(Vector2(560, 520), "sheep_lie", 16.0)
	add_prop("task", "lost_lamb", "Lost lamb", Vector2(560, 540), "E   Free the lamb from the brambles")
	gate = add_prop("task", "gate", "Gate", GATE + Vector2(-40, 0), "E   Open the gate")

func on_enter() -> void:
	G.player.unarmed = true   # the knife stays in his belt for the cows
	G.dusk = 0.36
	WorldBuilder.apply_darkness(self)
	_intro()

var _hay: Decor
func _intro() -> void:
	G.player.frozen = true
	# asleep in the hay with his hat over his face, until Azorel finds him
	G.player.visible = false
	_hay = add_decor(G.player.pos + Vector2(0, 6), "hunter_hay")
	Hud.set_black(1.0)
	await get_tree().process_frame
	await G.show_story("prologue")
	await Hud.fade_to(0.0, 0.8)   # the card leaves the screen black; open on the hill
	await G.wait(1.2)
	azorel_coming = true

## Wattle fence round the fold; the gap on the hill side is the gate until it is shut.
func _fence(shut: bool) -> void:
	var side := func(a: Vector2, b: Vector2, west: bool):
		var length := a.distance_to(b)
		var vert := absf(a.x - b.x) < 1.0
		var d := 0.0
		while d <= length:
			var q := a.lerp(b, d / length)
			var in_gap := west and absf(q.y - GATE.y) < GATE_HALF
			if in_gap == shut:
				var dd := add_decor(q, "wattle_fence", 30.0, int(d / 44.0) % 2 == 0)
				if vert: dd.rotation.y = PI / 2.0
				if in_gap: _gap.append(dd)
			d += 44.0
	var tl := FOLD.position; var br := FOLD.end
	if not shut:
		side.call(tl, Vector2(br.x, tl.y), false)
		side.call(Vector2(br.x, tl.y), br, false)
		side.call(Vector2(tl.x, br.y), br, false)
	side.call(tl, Vector2(tl.x, br.y), true)

func _clamp_in(a) -> void:
	var p: Vector2 = a.pos
	var c := p.clamp(Vector2(140, 140), size - Vector2(140, 140))
	if c != p: a.pos = c

func penned() -> int:
	var n := 0
	for c in cows:
		if FOLD.has_point(c.pos): n += 1
	return n

func _process(dt: float) -> void:
	super(dt)
	if not built or not is_instance_valid(G.player): return
	var pp: Vector2 = G.player.pos
	if step == 0:
		G.player.frozen = true   # asleep until Azorel gets to him
		if is_instance_valid(_hay): G.player.visible = false
		zzz_t -= dt
		if zzz_t <= 0.0 and G.state == G.State.PLAY:
			zzz_t = 1.6
			Fx.text(pp + Vector2(20, -20), "z z z", Color(0.8, 0.82, 0.9), 10.0)
		if azorel_coming:
			var to := pp + Vector2(45, 10) - azorel.pos
			if to.length() > 8.0: azorel.steer_to(pp + Vector2(45, 10), 210.0, dt)
			else:
				azorel_coming = false
				_wake()
		return
	_clamp_in(G.player)
	# Azorel keeps at your heels while you herd, and goes for the wolves when they come
	var a := azorel.pos
	var prey: Enemy = null; var pd := 9999.0
	if step == 2:
		for w in wolves:
			if is_instance_valid(w) and w.hp > 0.0 and a.distance_to(w.pos) < pd:
				pd = a.distance_to(w.pos); prey = w
	var goal: Vector2 = prey.pos if prey else pp + Vector2(-60, 30)
	var to := goal - a
	azorel.steer_to(goal, 260.0 if prey else 220.0, dt, 34.0 if prey else 50.0)
	bite_t -= dt
	if prey and pd < 48.0 and bite_t <= 0.0:
		bite_t = 0.7
		prey.hurt(6.0, to.normalized())
		Fx.text(a, "GRRR!", Fx.AMBER, 50.0)
		Audio.sfx("growl", -8.0, randf_range(1.2, 1.4))
	if step == 1:
		# a cow knows its way home at dusk: once the hunter (or the dog) gets it moving it plods to the gate
		# and in, and only shies aside when he walks right into it
		var gate_out := GATE + Vector2(-70, 0)
		var gate_in := GATE + Vector2(120, 0)
		var mid := FOLD.get_center()
		for c in cows:
			var cp := c.pos
			if FOLD.has_point(cp):
				c.home = mid
				if cp.distance_to(GATE) < 130.0: c.herd((mid - cp).normalized() * 90.0)   # away from the open gate
				continue
			if cp.distance_to(pp) < 230.0 or cp.distance_to(azorel.pos) < 150.0: roused[c] = true
			if not roused.has(c): continue
			# with the gate shut they gather in front of it; open, they walk in. A route round the fence, never through it.
			var dest := gate_in if gate_open else gate_out + Vector2(-60, 0)
			_cow_t[c] = _cow_t.get(c, 0.0) - dt
			var path: Array = _cow_path.get(c, [])
			if _cow_t[c] <= 0.0 or path.is_empty():
				path = find_path(cp, dest, 16.0, null, 260.0)
				if gate_open and dest == gate_in: path.append(mid)
				_cow_path[c] = path; _cow_t[c] = 1.5
			while path.size() > 1 and cp.distance_to(path[0]) < 28.0: path.pop_front()
			var g: Vector2 = path[0] if not path.is_empty() else dest
			if cp.distance_to(dest) < 40.0 and not gate_open: continue   # waits at the gate
			var v := (g - cp).normalized() * 105.0
			var away := cp - pp
			if away.length() < 80.0: v += away.normalized() * 60.0
			c.herd(v)
			_clamp_in(c)   # the pasture ends at the spruce: nothing wanders off the map
		_hints(dt)
	elif step == 2 and wolves_come:
		var any := false
		for w in wolves:
			if is_instance_valid(w) and w.hp > 0.0 and not w.fainted: any = true
		if not any:
			step = 3
			_morning()

func _hints(dt: float) -> void:
	hint_t += dt
	if hint == 0 and hint_t > 1.5:
		hint = 1; Hud.toast("WASD to walk. Open the gate of the stână (E), then go to each cow: once it is moving it knows the way home.")
	elif hint == 1 and hint_t > 14.0:
		hint = 2; Hud.toast("SPACE to dash. The last ones have wandered far.")
	if hint >= 1 and hint < 3 and penned() == cows.size():
		hint = 3; Hud.toast("All in. Walk to the gate and press E to close it.")

func _wake() -> void:
	Audio.sfx("dodge", -10.0, 0.8)
	if is_instance_valid(_hay): remove_decor(_hay)   # up out of the hay, hat back on his head
	add_decor(HILL + Vector2(-48, -14), "hay", 0.0)
	G.player.visible = true
	await G.say("Azorel", [
		"(Something warm and wet across your face. You push the hat off your eyes: Azorel, licking you awake, very pleased with himself.)",
		"(The sun is already behind the ridge. Down the slope the cows have wandered all over the pasture.)"])
	await G.say("You", ["You're right, Azorel. Let's take them back to the stână. It's getting dark."])
	G.player.frozen = false
	step = 1; hint_t = 0.0; hint = 0

func _open_gate() -> void:
	gate_open = true
	for d in _gap:
		if is_instance_valid(d):
			d.set_solid(false); d.queue_free(); decors.erase(d)
	_gap.clear()
	_cow_path.clear()
	Audio.sfx("hit", -10.0, 0.8)
	gate.prompt = "E   Close the gate"
	Hud.toast("The gate is open. Bring them in.")

func _close_gate() -> void:
	if penned() < cows.size():
		G.start_dialogue("Gate", ["Not yet: %d of %d cows are in. Azorel looks at you, then at the ones still out on the grass." % [penned(), cows.size()]])
		return
	_fence(true)
	gate.retire()
	for c in cows: c.home = FOLD.get_center()
	step = 2
	Audio.sfx("hit", -8.0, 0.6)
	Hud.toast("The gate is shut. The cows settle.")
	await G.wait(2.5)
	Fx.text(WOLF_FROM, "AWOOOO", Color(0.8, 0.82, 0.9), 60.0)
	Audio.sfx("howl", -4.0)
	await G.wait(1.5)
	for o in [Vector2(0, 0), Vector2(-120, -60), Vector2(80, -110), Vector2(-60, 90)]:
		var w := spawn_enemy("wolf", WOLF_FROM + o)
		w.state = "chase"; w.aggro = 3000.0
		wolves.append(w)
	wolves_come = true
	G.player.unarmed = false
	Fx.text(G.player.pos + Vector2(0, -30), "*the knife comes out of his belt*", Color(0.85, 0.85, 0.9), 50.0)
	Audio.sfx("swing", -4.0, 0.7)
	Hud.banner("WOLVES", "You pull the knife from your belt. Click or J to strike, SPACE to dodge. Azorel goes for their throats.")

func _morning() -> void:
	await G.wait(1.5)
	Audio.sfx("hunter_easy", -2.0)
	await G.say("You", ["(The last wolf runs for the trees. Azorel trots back, tail high, and leans against your leg.)", "Good dog. Tomorrow we go down."])
	G.side_add("prologue_done")
	await G.show_story("descent")
	Loader.goto_level("sighisoara")

# ------------------------------------------------------------------ quest hooks

func talk(npc: String) -> bool:
	if npc != "azorel": return false
	G.start_dialogue("Azorel", ["(Azorel sits by the gate, ears up, watching the dark trees.)" if step >= 2 else "(Azorel looks at the cows, then at you, then at the cows. He has been doing this job longer than you.)"])
	return true

func use(p: Prop) -> void:
	if p.id == "gate":
		if gate_open: _close_gate()
		else: _open_gate()
	elif p.id == "lost_lamb":
		G.player.potions += 1
		G.player.coins += 10
		remove_prop(p)
		G.start_dialogue("Lost lamb", [
			"(You part the brambles carefully. The lamb scrambles free and trots straight toward the fold.)",
			"(Azorel gives one approving bark. Found 10 coins and a spare tincture tucked in the shepherd's pouch nearby.)"
		])

func pending(p: Prop) -> bool:
	return p.id == "gate" and step == 1 and (not gate_open or penned() == cows.size())

func target() -> Array:
	var pp: Vector2 = G.player.pos
	if step == 1:
		if not gate_open or penned() == cows.size(): return [GATE, "Gate"]
		var best: Enemy = null; var bd := 1e9
		for c in cows:
			if not FOLD.has_point(c.pos) and pp.distance_to(c.pos) < bd:
				bd = pp.distance_to(c.pos); best = c
		return [best.pos, "Stray cow"] if best else []
	if step == 2:
		for w in wolves:
			if is_instance_valid(w) and w.hp > 0.0: return [w.pos, "Wolf"]
	return []

func objective() -> String:
	match step:
		0: return "Asleep on the hill."
		1: return "Open the gate of the stână." if not gate_open else ("Close the gate of the stână." if penned() == cows.size() else "Drive the cows into the stână before dark. %d/%d" % [penned(), cows.size()])
		2: return "Drive off the wolves."
	return "Rest. Tomorrow you go down to the valley."
