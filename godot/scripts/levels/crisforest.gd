## Muma Pădurii's wood, west of Criș: a pack lying up by the path, four snares (the last holds a bear), the
## old oak, and on the way home a rot-touched pack whose alpha carries the mark. No wolf is killed here.
extends Level

const TRAIL := [Vector2(160, 2600), Vector2(1000, 2450), Vector2(1900, 2700), Vector2(2800, 2400), Vector2(3700, 2250), Vector2(4600, 2450),
	Vector2(5500, 2700), Vector2(6400, 2500), Vector2(7300, 2300), Vector2(8200, 2450), Vector2(8900, 2500)]
const OAK := Vector2(9100, 2450)
const DEN := Vector2(2300, 2350)       # where the first pack lies up
const FOX_AT := Vector2(3700, 2080)
const DEER_AT := Vector2(4900, 2700)
const OWL_AT := Vector2(6100, 2420)
const BEAR_AT := Vector2(7500, 2150)
const MAGDA_COL := Color(1, 0.85, 0.7)

var pack: Array[Enemy] = []
var hunt: Array[Enemy] = []
var bear: Enemy
var hunting := false
var fled := 0
var hunt_total := 0
var magda_thrown := false
var mark_t := 0.0
var runners: Array[Dictionary] = []

func build() -> void:
	title = "THE FOREST OF CRIȘ"
	subtitle = "Muma Pădurii's wood"
	size = Vector2(10000, 5000)
	spawn = Vector2(320, 2580)
	ground = Color("20261a")
	tile = ""
	quest = CsQuest.new()
	rng = NetRandom.new(1453)
	var has := func(f: String) -> bool: return G.side_has(f)
	scatter(Rect2(Vector2.ZERO, size), 520, [Color("2c3220"), Color("24281c"), Color("3a2e20")])
	add_path(TRAIL, 90.0)
	var x := 80.0
	while x < size.x - 60.0:
		var y := 80.0
		while y < size.y - 60.0:
			var p := Vector2(x + (rng.f() - 0.5) * 120.0, y + (rng.f() - 0.5) * 120.0)
			y += 150.0
			if _trail_dist(p) < 170.0 or p.distance_to(OAK) < 650.0 or p.distance_to(DEN) < 380.0: continue
			var near_snare := false
			for s in [FOX_AT, DEER_AT, OWL_AT, BEAR_AT]:
				if p.distance_to(s) < (480.0 if s == BEAR_AT else 220.0): near_snare = true
			if near_snare or rng.f() < 0.25: continue
			add_tree(p, rng.f() < 0.3)
		x += 150.0
	add_wall(Vector2(size.x / 2.0, -20), Vector2(size.x, 40))
	add_wall(Vector2(size.x / 2.0, size.y + 20), Vector2(size.x, 40))
	add_wall(Vector2(-20, size.y / 2.0), Vector2(40, size.y))
	add_wall(Vector2(size.x + 20, size.y / 2.0), Vector2(40, size.y))
	add_prop("task", "exit", "Back to Criș", Vector2(200, 2600), "")
	add_trigger(Rect2(0, 2300, 60, 600), leave)
	# the first pack, lying up in the undergrowth by the path in
	if not has.call("cs_pack1"):
		for o in [Vector2(-260, -200), Vector2(240, -240), Vector2(300, 220), Vector2(-220, 250)]:
			var w := spawn_enemy("wolf", DEN + o)
			w.aggro = 1.0; w.flee_low = true
			w.fled.connect(func(_e): _pack_fled())
			pack.append(w)
		add_trigger(Rect2(DEN.x - 380, DEN.y - 320, 760, 640), _wake_pack)
	# the snares
	if not has.call("cs_fox"):
		add_decor(FOX_AT, "fox_snare"); add_prop("task", "fox", "A fox in a snare", FOX_AT + Vector2(0, 50), "E   Prise the wire open")
	if not has.call("cs_deer"):
		add_decor(DEER_AT, "deer_snare"); add_prop("task", "deer", "A deer in a snare", DEER_AT + Vector2(0, 60), "E   Cut the rope")
	if not has.call("cs_owl"):
		add_decor(OWL_AT, "owl_snare"); add_prop("task", "owl", "An owl in a net", OWL_AT + Vector2(0, 50), "E   Untangle the net")
	if not has.call("cs_bear"):
		add_decor(BEAR_AT + Vector2(80, 40), "leg_trap")
		if has.call("cs_bear_down"): _bear_down(BEAR_AT)
		else:
			bear = spawn_enemy("snarebear", BEAR_AT)
			bear.aggro = 0.0
			bear.died.connect(func(_e): _bear_down(bear.pos))
			add_prop("task", "bear", "Something big in a snare", BEAR_AT + Vector2(0, 170), "E   Go closer")
	# the old oak
	add_decor(OAK + Vector2(0, -60), "oak_twig")
	add_tree(OAK + Vector2(0, -120))
	add_tree(OAK + Vector2(-160, -40))
	add_torch(OAK, 340.0, Color(0.65, 0.85, 0.55), 0.35)
	if not has.call("cs_muma"): add_prop("npc", "muma", "Muma Pădurii", OAK + Vector2(0, 40), "E   Face her", Color("4a5a3a"))
	add_torch(Vector2(4600, 2450), 240.0, Color(0.7, 0.75, 1), 0.22)
	if has.call("cs_muma") and not has.call("cs_wolves"): _start_hunt()

func _trail_dist(p: Vector2) -> float:
	var best := INF
	for k in TRAIL.size() - 1: best = minf(best, dist_to_segment(p, TRAIL[k], TRAIL[k + 1]))
	return best

func _prop(pid: String) -> Prop:
	for p in props:
		if is_instance_valid(p) and p.id == pid: return p
	return null

func _drop(pid: String) -> void:
	var p := _prop(pid)
	if p: remove_prop(p)

# ------------------------------------------------------------------ pack one, and Magda

func _wake_pack() -> void:
	var any := false
	for w in pack:
		if is_instance_valid(w) and w.aggro < 10.0:
			w.aggro = 2000.0; w.state = "chase"; any = true
	if not any: return
	Audio.sfx("howl", -6.0)
	Hud.toast("The undergrowth comes alive.")
	# Magda, who got here first, comes the other way at a dead run
	var from := DEN + Vector2(500, -60)
	_run(add_prop("npc", "magda", "Magda", from, "", Color("8a3a4a")), from, Vector2(150, 2650), 2.2, "VLAAAAAD!!!")

func _run(who: Prop, from: Vector2, to: Vector2, secs: float, shout: String) -> void:
	Fx.text(from, shout, MAGDA_COL, 70.0)
	runners.append({who = who, from = from, to = to, secs = secs, shout = shout, t = 0.0})

func _pack_fled() -> void:
	for w in pack:
		if is_instance_valid(w) and not w.fleeing: return
	if not G.side_has("cs_pack1"):
		G.side_add("cs_pack1")
		Hud.toast("The pack breaks and runs. Not one of them dead.")

# ------------------------------------------------------------------ the snares and the bear

func free_animal(p: Prop) -> void:
	var lines: Array
	match p.id:
		"fox": lines = ["(The fox snaps at you twice, then lets you get your fingers under the wire.)", "(You prise it open. The fox looks at you as if you set it, and is gone.)"]
		"deer": lines = ["(A young roe deer, tangled to the knees, eyes white. You talk to it the way the shepherds talk to sheep.)", "(One cut, and it is away through the beeches, all legs.)"]
		_: lines = ["(An owl in a fowler's net, wings twisted. It clacks its beak at you, furious.)", "(Strand by strand. When the last one comes away it hops onto a branch, turns its head right round, and stares at you until you leave.)"]
	G.start_dialogue(p.display, lines, func():
		G.side_add("cs_" + p.id)
		for d in decors.duplicate():
			if is_instance_valid(d) and d.sprite_name == p.id + "_snare": remove_decor(d)
		remove_prop(p)
		Audio.sfx("blip", -6.0, 1.2)
		Hud.toast("Freed %d/4" % (CsQuest.freed() + (1 if G.side_has("cs_bear") else 0))))

func wake_bear() -> void:
	if not is_instance_valid(bear) or bear.aggro > 10.0: return
	G.start_dialogue("The last snare", [
		"(A bear. A big brown Carpathian bear, a steel trap on its hind leg, blood in the leaves. It has been here for days.)",
		"(It sees you. The chain snaps.)",
		"Where is Azorel when you need him?",
	], func():
		bear.aggro = 3000.0; bear.state = "chase"
		Audio.sfx("boss_roar", -2.0, 0.7)
		Hud.banner("THE BEAR IN THE SNARE", "Beat it back. Don't kill it.")
		_drop("bear"))

func _bear_down(at: Vector2) -> void:
	if not G.side_has("cs_bear_down"):
		G.side_add("cs_bear_down")
		Hud.toast("The bear sinks down, panting. Now free it.")
	add_prop("task", "bandage", "The bear", at + Vector2(0, 80), "E   Free and bandage the bear")

func bandage_bear() -> void:
	G.start_dialogue("The bear", [
		"(You open the trap with your boot and both hands. The bear watches you the whole time and does not move.)",
		"(You bind the leg with a strip of your own shirt. It smells of you now. That can't be good.)",
		"(It gets up, slowly, and lumbers off into the beeches without looking back.)",
	], func():
		G.side_add("cs_bear")
		if is_instance_valid(bear): bear.queue_free()
		for e in Enemy.fainted_ones.duplicate():
			if is_instance_valid(e) and e.kind == "snarebear": e.queue_free()
		_drop("bandage")
		Hud.toast("Freed %d/4" % (CsQuest.freed() + 1)))

# ------------------------------------------------------------------ Muma Pădurii

func meet_muma() -> void:
	if not CsQuest.all_freed():
		G.start_dialogue("Muma Pădurii", ["(An old woman under the oak, ugly as a burl, bark for skin, moss in her hair. She does not look at you.)", "My animals are hanging in your people's wire, hunter. Come back when they aren't."])
		return
	if G.side_has("cs_muma"): return
	G.start_dialogue("Muma Pădurii", [
		"(She steps out from under the oak. Up close she is uglier, and older, and much taller than she was a moment ago.)",
		"Wire in my hornbeams. Traps on my paths. Three of my oaks down for firewood, and not a word asked. And now a hunter.",
		"You let them go. All of them. Even the bear, who would have had your face off. Hm.",
		"Hear me: never raise a cross as a weapon in my wood. I was here before the first priest and I will be here after the last.",
		"(You ask her about the rot. About the madness in Criș.)",
		"(She stares at you for a long time.) It's the bread, boy. Everyone's tripping.",
		"The wolves are another matter. Something has its hand on them. The rot is behind the wolves, and it knows you are here.",
		"(She snaps a twig from the oak and pushes it into your coat.) Go home by the path. Don't run.",
	], func():
		G.side_add("cs_muma")
		_drop("muma")
		Audio.sfx("howl", -4.0, 0.8)
		_start_hunt())

# ------------------------------------------------------------------ pack two, rot-touched

func _start_hunt() -> void:
	hunting = true; fled = 0; hunt.clear()
	for g in [Vector2(6200, 1900), Vector2(6400, 3100), Vector2(5600, 1700), Vector2(5400, 3300), Vector2(4700, 2000), Vector2(4500, 3000)]:
		var w := spawn_enemy("wolf", g)
		w.hp = 26.0; w.max_hp = 26.0; w.speed = 165.0; w.aggro = 3000.0; w.state = "chase"; w.flee_low = true
		w.fled.connect(func(_e): _hunt_fled())
		hunt.append(w)
	var a := spawn_enemy("wolf", Vector2(5000, 2500))
	a.hp = 70.0; a.max_hp = 70.0; a.speed = 158.0; a.dmg = 11.0; a.aggro = 3000.0; a.state = "chase"; a.flee_low = true; a.rot_mark = true
	if a.fig: a.fig.scale *= 1.25
	a.fled.connect(func(_e): _hunt_fled())
	hunt.append(a)
	hunt_total = hunt.size()
	Hud.banner("THE ROT-TOUCHED PACK", "Red eyes between the trees. The alpha has a mark burning on its flank.")
	magda_thrown = false

func _hunt_fled() -> void:
	fled += 1
	if not magda_thrown and fled >= 2:
		magda_thrown = true
		var from: Vector2 = G.player.pos + Vector2(-420, 180)
		var mg := add_prop("npc", "magda", "Magda", from, "", Color("8a3a4a"))
		G.player.haste_t = 30.0
		Hud.toast("Magda's bandage: faster on your feet for 30 seconds.")
		_run(mg, from, from + Vector2(-900, 300), 1.6, "HAIDA!")
		Fx.text(from, "Your feet look swollen, take this!", MAGDA_COL, 70.0)
	var alpha_left := false
	for w in hunt:
		if is_instance_valid(w) and not w.fleeing and w.rot_mark: alpha_left = true
	if alpha_left and fled < hunt_total: return
	if not hunting: return
	hunting = false
	for w in hunt:
		if is_instance_valid(w) and not w.fleeing:
			w.flee_low = true; w.hp = 1.0; w.hurt(0.1, Vector2.RIGHT)
	G.side_add("cs_wolves")
	Hud.banner("THE MARK IS BROKEN", "The alpha shakes itself like a wet dog, looks at you, and trots off. The rest follow.")

## Where the marked alpha is, or null once it has run.
func alpha_pos() -> Variant:
	for w in hunt:
		if is_instance_valid(w) and not w.fleeing and w.rot_mark: return w.pos
	return null

func hunt_line() -> String:
	var left := 0; var alpha := false
	for w in hunt:
		if is_instance_valid(w) and not w.fleeing:
			left += 1
			if w.rot_mark: alpha = true
	return "Break the rot mark on the alpha's flank. (%d wolves on you)" % left if alpha else "Get back to Criș."

func _process(dt: float) -> void:
	super(dt)
	for r in runners.duplicate():
		r.t += dt
		if not is_instance_valid(r.who): runners.erase(r); continue
		r.who.pos = r.from.lerp(r.to, minf(r.t / r.secs, 1.0))
		if randf() < dt * 3.0: Fx.text(r.who.pos, r.shout, MAGDA_COL, 70.0)
		if r.t >= r.secs:
			remove_prop(r.who); runners.erase(r)
	if not hunting: return
	mark_t -= dt
	var a = alpha_pos()
	if mark_t > 0.0 or a == null: return
	mark_t = 0.45   # the rot mark burns on its flank, a dull red pulse
	Fx.ring(a + Vector2(0, -10), Color(0.75, 0.12, 0.15, 0.9), 34.0, 0.4)

func leave() -> void:
	if G.state != G.State.PLAY or G.transitioning: return
	if hunting:
		Hud.toast("They'd follow you right into the village. Deal with them here.")
		return
	Loader.goto_level("cris", CsQuest.forest_gate + Vector2(150, 60) if CsQuest.forest_gate != Vector2.ZERO else null)
