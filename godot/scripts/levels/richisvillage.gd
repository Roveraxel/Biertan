## Richiș (Rätsch) under an October frost: the hall church with the green men, and on the ridge road to
## Biertan seven Iele dancing out of season. Quest: The Brothers and the Iele.
extends Village

const RIDGE := Vector2(13600, 4500)

var dancers: Array[Prop] = []
var toader: Prop
var toader_home := Vector2.ZERO
var ring_at := Vector2.ZERO
var t := 0.0
var laugh_t := 0.0

func build() -> void:
	title = "RICHIȘ"
	subtitle = "Rätsch · The Brothers and the Iele"
	quest = RcQuest.new()
	arrive_flag = "rc_arrive"
	standard("richisvillage", 1499)
	ground = Color("2c342a")
	scatter(Rect2(Vector2.ZERO, size), 120, [Color("50565a"), Color("585e5c")])   # frost on the grass
	churches_and_houses()
	spawn = free_spot(Vector2(1900, 10600), 120.0)   # the road from Mălâncrav comes in from the south-west
	graves_and_trees()
	_quest_things()
	finish()

func _quest_things() -> void:
	var has := func(f: String) -> bool: return G.side_has(f)
	var church: Vector2 = m.boxes("churches")[0].c
	var freed: bool = has.call("rc_iele")
	var home := free_spot(church + Vector2(-700, -1100), 220.0)   # an open yard, so nobody stands behind a roof
	add_prop("npc", "ilie", "Moș Ilie", home, "E   Speak with Moș Ilie", Color("5a4a3a"))
	add_decor(home + Vector2(110, -10), "bench")
	if not has.call("rc_agree"): add_decor(home + Vector2(-90, -60), "nai")
	add_torch(home + Vector2(0, -60), 220.0, Color(1, 0.65, 0.35), 0.55)
	add_prop("npc", "petrea", "Petrea", free_spot(home + Vector2(-140, 60), 30.0), "E   Talk to Petrea")
	var den := free_spot(church + Vector2(1300, 1700), 50.0)
	add_prop("npc", "denisa", "Denisa · Herbalist", den, "E   Speak with Denisa", Color("5a4a5a"))
	add_decor(den + Vector2(90, -20), "decoction" if has.call("rc_brew") else "basil")
	var cel := free_spot(church + Vector2(-1700, 1400), 40.0)
	add_decor(cel, "trapdoor")
	add_decor(cel + Vector2(90, -30), "garlic_braid")
	add_prop("task", "cellar", "A cellar", cel + Vector2(0, 40), "E   Knock at the cellar")
	# Toader, dancing alone at the edge of a field; once the Iele are gone he sits with his brother
	toader_home = home + Vector2(-150, 20) if freed else free_spot(church + Vector2(3100, 2200), 60.0)
	toader = add_prop("npc", "toader", "Toader", toader_home, "E   Talk to Toader")
	if not freed: add_decor(toader_home + Vector2(0, 80), "iele_circle")
	# the ridge road to Biertan, shut, with the seven dancing on it
	var gate := nearest_road_point(RIDGE)
	RcQuest.ridge_gate = gate
	add_decor(gate + Vector2(0, -60), "ridge_barrier", 0.0 if freed else 40.0)
	if not freed:
		add_block(Rect2(gate.x - 260, gate.y - 160, 520, 60), "hidden", 0.0)
		ring_at = gate + Vector2(260, -330)
		for i in 7: dancers.append(add_prop("npc", "ieledancer", "", ring_at, "", Color("e0e0f0")))
		add_torch(ring_at, 520.0, Color(0.75, 0.8, 1), 0.55)
	add_prop("task", "ridge", "The road to Biertan" if freed else "The ridge path", gate + Vector2(0, 60), "E   Take the ridge road to Biertan" if freed else "E   Look at the ridge path")
	var fg := nearest_road_point(Vector2(8600, 600))
	RcQuest.forest_gate = fg
	add_prop("task", "forest", "The forest", fg, "E   Go into the forest")
	add_prop("troita", "troita", "Troiță", free_spot(fg + Vector2(160, 60), 30.0), "E   Pray at the troiță")
	add_decor(free_spot(fg + Vector2(160, 0), 30.0), "troita", 22.0)

func _process(dt: float) -> void:
	super(dt)
	t += dt
	# seven in a ring on the ridge, turning
	for i in dancers.size():
		if not is_instance_valid(dancers[i]): continue
		var a := t * 0.7 + i * TAU / 7.0
		dancers[i].pos = ring_at + Vector2(cos(a), sin(a) * 0.6) * 150.0
	if is_instance_valid(toader) and not G.side_has("rc_iele"):
		var a := t * 2.2
		toader.pos = toader_home + Vector2(cos(a), sin(a * 2.0) * 0.5) * 45.0
		laugh_t -= dt
		if laugh_t <= 0.0:
			laugh_t = 4.0 + randf() * 3.0
			Fx.text(toader.pos, "Hop! Hop!" if randf() < 0.5 else "Ha ha! The wind!", Color(0.9, 0.9, 1), 80.0)

func brothers() -> void:
	G.start_dialogue("The brothers", [
		"(Toader is sitting on the bench, very still, with frost in his hair. He looks at his hands, and then at his brother.)",
		"Toader: Ilie. You're holding the nai.",
		"Ilie: I am.",
		"Toader: ...You were always terrible at it.",
		"(Ilie laughs, and then he isn't laughing, and the two old men hold on to each other for a long time. You look at the ridge.)",
		"(Petrea tugs your sleeve and puts a little clay whistle in your hand.) For the road. Blow it once and the wind comes. Only once, then it has to rest.",
		"(Ilie takes a ring of dried flowers from the nail where the nai hung, and gives it to you.) From the Rusalii, years ago. The road to Biertan is open. Go carefully.",
	], func():
		G.side_add("rc_done"); G.side_add("token_flower_ring"); G.side_add("rc_whistle")
		G.player.coins += 25
		Audio.sfx("coin", -4.0)
		Hud.toast("Quest complete: The Brothers and the Iele.  Token: a ring of dried flowers")
		Hud.toast("Petrea's whistle: press G for one gust of wind (it rests between uses)."))
