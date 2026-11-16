## The Saxon graveyard by the Church on the Hill, Sighișoara: the wedding of the dead. The coffin is open, the
## fir tree stands where the bride should, and the groom gets cold feet. Then the sexton comes for his master,
## raises the graveyard and brings the last of his wolves, and the wedding has to be defended.
extends Level

const ALTAR := Vector2(1200, 760)
const WAVE_TIME := [0.0, 34.0, 40.0]
const SAY := Color(1, 0.88, 0.6)

var phase := 0               # 0 before, 1-2 waves, 3 the sexton, 4 judgement done
var wave_t := 0.0
var courage := 100.0         # the wedding holds as long as the guests do
var foes: Array[Enemy] = []
var sexton: Enemy
var allies := {}             # id -> Prop
var ally_t := 2.0
var ally_i := 0
var stake_decor: Decor
var follower: Prop
var _arrive_t := 0.0

static func has(f: String) -> bool: return G.side_has(f)

func ambient() -> Color:
	if phase in [1, 2, 3]: return Color(0.3, 0.3, 0.42)   # his earth takes the light out of the morning
	return Color(0.68, 0.55, 0.4)   # a low sun: bright grass washes out under anything stronger

func build() -> void:
	title = "THE CHURCH ON THE HILL"
	subtitle = "The Saxon graveyard · A wedding"
	size = Vector2(2400, 1800)
	spawn = Vector2(1200, 1640)
	ground = Color("2a3024")
	quest = FinQuest.new()
	rng = NetRandom.new(1345)
	scatter(Rect2(Vector2.ZERO, size), 420, [Color("38402c"), Color("242a1e"), Color("4a4a38")])
	add_path([Vector2(1200, 1800), Vector2(1200, 900)], 110.0)
	add_block(Rect2(800, 120, 800, 300), "church", 90.0)
	add_block(Rect2(700, 180, 100, 160), "tower", 170.0)
	add_block(Rect2(-200, -200, 2800, 200), "hidden", 0.0)
	add_block(Rect2(-200, 1800, 2800, 200), "hidden", 0.0)
	add_block(Rect2(-200, -200, 200, 2200), "hidden", 0.0)
	add_block(Rect2(2400, -200, 200, 2200), "hidden", 0.0)
	for i in 46:   # the old stones, in rows, as the Saxons liked them
		var g := Vector2(160.0 + (i % 12) * 190.0 + rng.f() * 30.0, 520.0 + (i / 12) * 300.0 + rng.f() * 40.0)
		if g.distance_to(ALTAR) < 330.0 or absf(g.x - 1200.0) < 110.0: continue
		add_block(Rect2(g.x - 11, g.y - 5, 22, 10), "stone", 18.0 + rng.f() * 12.0)
	for p in [Vector2(260, 300), Vector2(2140, 300), Vector2(200, 1500), Vector2(2200, 1500), Vector2(520, 1700), Vector2(1880, 1700)]: add_tree(p, true)
	# the wedding
	add_decor(ALTAR + Vector2(0, 120), "long_feast", 50.0)
	add_decor(ALTAR + Vector2(-150, -40), "coffin" if ResourceLoader.exists("res://sprites/Props/coffin.png") else "sarcophagus")
	add_tree(ALTAR + Vector2(170, -90), true)   # the fir, in the bride's place
	add_torch(ALTAR, 620.0, Color(1, 0.78, 0.5), 1.0)
	for p in [ALTAR + Vector2(-330, 150), ALTAR + Vector2(330, 150)]: add_brazier(p)
	var guests := [["baron", "The baron of Biertan", Vector2(-60, -20)], ["finpriest", "Father Imre", Vector2(40, -90)], ["lorena", "Lorena", Vector2(-230, 190)],
		["bvlad", "Vlad Laurențiu", Vector2(250, 200)], ["bmagda", "Magda", Vector2(320, 190)], ["butcher", "Meister Thomas", Vector2(-330, 60)],
		["captain", "The spiriduș captain", Vector2(-120, 210)], ["mbear", "The bear", Vector2(420, 40)]]
	if has("favour_solomonar"): guests.append(["solomonar", "The Solomonar", Vector2(-440, -60)])
	for it in guests: allies[it[0]] = add_prop("npc", it[0], it[1], ALTAR + it[2], "E   Talk")
	add_decor(ALTAR + Vector2(80, -30), "joimarita", 20.0)
	add_prop("task", "joimarita", "Joimărița", ALTAR + Vector2(80, 30), "E   Speak with Joimărița")
	follower = add_prop("npc", "azorel", "Azorel", spawn + Vector2(50, 0), "E   Azorel", Color("d8d0c0"))
	add_prop("task", "down", "The Scholars' Stair", Vector2(1200, 1740), "E   Go back down")
	spots["altar"] = ALTAR + Vector2(0, 60)
	if has("fin_done"): phase = 4

func pointer() -> Array:
	if phase == 0: return [spots["altar"], "The wedding"]
	return []

func line() -> String:
	match phase:
		0: return "The churchyard on the hill. Everybody is here. Even the weather."
		1, 2: return "The sexton has raised the graveyard. Keep them off the wedding! (The guests' courage: %d%%  ·  %d s)" % [ceili(courage), ceili(maxf(0.0, WAVE_TIME[phase] - wave_t))]
		3: return "The sexton. Soft hands, good boots, and nowhere left to run."
	return "The bells of Sighișoara."

func _process(dt: float) -> void:
	super(dt)
	if not is_instance_valid(G.player): return
	var pl: Player = G.player
	if is_instance_valid(follower) and phase in [0, 4]:
		var to := pl.pos + Vector2(50, 20) - follower.pos
		if to.length() > 60.0: follower.pos += to.limit_length(200.0 * dt)
	if phase == 0 and G.state == G.State.PLAY and not G.transitioning and pl.pos.distance_to(spots["altar"]) < 260.0:
		_arrive_t += dt
		if _arrive_t > 0.4: _cold_feet()
	if not phase in [1, 2, 3] or G.state != G.State.PLAY: return
	_allies(dt)
	if phase == 3: return
	wave_t += dt
	for e in foes:
		if is_instance_valid(e) and e.kind.begins_with("dead") and e.at_goal() and e.stun_t <= 0.0: courage -= (2.2 if e.kind == "dead_big" else 1.6) * dt
	if courage <= 0.0:
		courage = 100.0; wave_t = 0.0
		Hud.banner("THE GUESTS BREAK AND RUN", "Magda rounds them up again by the ear. Once more.")
		_clear()
		get_tree().create_timer(2.5, false).timeout.connect(func(): _wave(phase))
		return
	if wave_t >= WAVE_TIME[phase]:
		_clear()
		if phase == 1: _wave(2)
		else: _sexton()

# ------------------------------------------------------------------ the wedding that was planned, and the other one

func _cold_feet() -> void:
	phase = -1
	G.start_dialogue("The wedding of the dead", [
		"(The old graveyard on the hill, in the first sun. The coffin is open on its trestles. The fir stands in the bride's place with Magda's ribbons on it. Thirty spiriduși are holding their hats.)",
		"Father Imre: ...and so we lay to rest, and at the same time join in matrimony, which I grant you is unusual, the servant of God...",
		"(The baron stands by the coffin in his white shirt. He looks at the coffin. He looks at the fir tree. He looks, for rather longer, at the young woman with snowdrops in her hair who has been telling him all morning that his cuffs are wrong.)",
		"The baron: Father. One moment. (He clears his throat.) I find I have changed my mind.",
		"(Silence. A spiriduș drops his hat.)",
		"I do not wish to marry a tree. With respect to the tree. I waited two hundred years to stand in a church beside somebody, and I should like it to be somebody who argues back.",
		"(He turns to Joimărița, and goes down, stiffly, on one knee among the gravestones.) Madam. You have criticised my coat, my collar, my cuffs and my century. Would you consider doing so permanently?",
		"Joimărița: (She has gone the colour of a peony.) ...Hands.",
		"(He gives them to her. Nine fingers. She turns them over for a long time.)",
		"Joimărița: They have not worked in two hundred years. (A pause.) They will learn. Yes.",
		"Lorena: (to you, not quietly enough) I TOLD you.",
		"Father Imre: Is SHE baptised? (\"I am Maundy Thursday,\" says Joimărița.) ...I am going to need a great deal of wine.",
		"(And then, from the churchyard gate, a slow clap. One pair of hands. Soft ones.)",
	], func():
		G.start_dialogue("The sexton", [
			"(The sexton of Viscri and Biertan, with good boots and a ring of keys, and a sack over his shoulder that is moving.)",
			"(He does a voice, a dazed one.) 'Where am I? Why am I in my own cellar?' You believed that, hunter. Everybody believes a sexton.",
			"Thirty years. Thirty years I kept your door, my lord, and fed your valley to you a spoonful at a time, and built a very comfortable living on it. And you would throw it over for a girl with weeds in her hair.",
			"A master who is at rest is no use to me. A master who is HAPPY is worse.",
			"(He upends the sack over the nearest graves. Black earth. All of it; everything he has left.)",
			"Get up. All of you. There is a wedding. You were not invited.",
		], func():
			Audio.set_music("music_vlad", -6.0)
			Audio.sfx("shriek", -2.0, 0.6)
			_wave(1)))

func _clear() -> void:
	for e in foes:
		if is_instance_valid(e): e.queue_free()
	foes.clear()

func _edge_spot(i: int, n: int) -> Vector2:
	var a := i * TAU / n + rng.f() * 0.4
	return Vector2(clampf(ALTAR.x + cos(a) * 1050.0, 80, 2320), clampf(ALTAR.y + 120.0 + sin(a) * 760.0, 460, 1720))

func _wave(w: int) -> void:
	phase = w; wave_t = 0.0
	WorldBuilder.apply_darkness(self)
	var n: int = [7, 9][w - 1]
	for i in n:
		var e := spawn_enemy("dead_big" if (w == 2 and i % 3 == 0) else "dead", _edge_spot(i, n))
		e.goal = ALTAR + Vector2(0, 120)
		foes.append(e)
	for i in (2 if w == 1 else 4):
		var wf := spawn_enemy("wolf", _edge_spot(i * 2 + 1, 8))
		wf.state = "chase"; wf.aggro = 4000.0; wf.flee_low = true
		foes.append(wf)
	Hud.banner(["THE GRAVEYARD GETS UP", "MORE OF THEM, AND HIS WOLVES"][w - 1], ["They go for the wedding table. Knock them back; they cannot be killed.", "Everybody who came up the road with you is fighting. So fight."][w - 1])

func _sexton() -> void:
	phase = 3
	Hud.banner("THE SEXTON", "He has nothing left in the sack. He has a spade, and thirty years of spite.")
	sexton = spawn_enemy("sexton", Vector2(1200, 1560))
	sexton.hp = 420.0; sexton.max_hp = 420.0; sexton.dmg = 20.0; sexton.speed = 100.0
	sexton.state = "chase"; sexton.aggro = 9000.0
	if sexton.fig: sexton.fig.scale *= 1.3
	sexton.boss_title = "THE SEXTON OF BIERTAN"
	G.boss = sexton
	sexton.call_thralls.connect(func(_e):
		for i in 3:
			var e := spawn_enemy("dead", _edge_spot(i, 3))
			e.goal = ALTAR + Vector2(0, 120)
			foes.append(e))
	sexton.died.connect(func(_e): _judgement())

## Everybody who came up the road takes a turn.
func _allies(dt: float) -> void:
	ally_t -= dt
	if ally_t > 0.0: return
	ally_t = 2.6
	var acts := ["mbear", "lorena", "bmagda", "captain", "azorel"]
	if allies.has("solomonar"): acts.append("solomonar")
	ally_i = (ally_i + 1) % acts.size()
	var who: String = acts[ally_i]
	var p: Prop = follower if who == "azorel" else allies.get(who)
	if not is_instance_valid(p): return
	var live := Enemy.all.filter(func(e): return is_instance_valid(e) and e.hp > 0.0 and not e.fleeing and not e.fainted)
	if live.is_empty(): return
	live.sort_custom(func(a, b): return a.pos.distance_to(p.pos) < b.pos.distance_to(p.pos))
	var near: Enemy = live[0]
	match who:
		"mbear":
			near.hurt(18.0, (near.pos - p.pos).normalized())
			Fx.text(p.pos, "GRRAWR", SAY, 90.0)
		"azorel":
			var wolves := live.filter(func(e): return e.kind == "wolf")
			if not wolves.is_empty(): wolves[0].hurt(10.0, Vector2.RIGHT)
			Fx.text(p.pos, "(Azorel, limping, and going for a throat anyway)", SAY, 60.0)
		"lorena":
			for e in live:
				if e.pos.distance_to(ALTAR) < 420.0 and not e.kind.begins_with("dead"): e.hurt(7.0, (e.pos - ALTAR).normalized())
			Fx.ring(p.pos, Color(0.95, 0.95, 0.8, 0.8), 120.0, 0.4)
			Fx.text(p.pos, "GARLIC!", SAY, 80.0)
		"bmagda":
			for e in live:
				if e.kind.begins_with("dead") and e.pos.distance_to(ALTAR) < 380.0: e.hurt(1.0, (e.pos - ALTAR).normalized())
			Fx.ring(p.pos, Color(1, 0.8, 0.6, 0.8), 260.0, 0.5)
			Fx.text(p.pos, "OFF the table! HAIDA! OUT!", SAY, 80.0)
		"captain":
			var dead := live.filter(func(e): return e.kind.begins_with("dead"))
			if not dead.is_empty():
				var e: Enemy = dead[randi() % dead.size()]
				e.hurt(1.0, Vector2.from_angle(randf() * TAU))
				Fx.text(e.pos, "(tripped, by somebody very small)", SAY, 50.0)
		"solomonar":
			Fx.shake(0.15)
			for e in live:
				if randf() < 0.6:
					Fx.ring(e.pos, Color(0.9, 0.95, 1, 0.8), 50.0, 0.3)
					e.hurt(6.0 if not e.kind.begins_with("dead") else 1.0, Vector2.DOWN)
			Fx.text(p.pos, "(he opens the book. Hail, on the uninvited only)", Color(0.8, 0.88, 1), 90.0)

# ------------------------------------------------------------------ the sexton's hands

func _judgement() -> void:
	phase = 4
	G.boss = null
	_clear()
	WorldBuilder.apply_darkness(self)
	Audio.set_music("music_hub", -9.0)
	var at := sexton.pos if is_instance_valid(sexton) else ALTAR + Vector2(0, 400)
	G.start_dialogue("The sexton's hands", [
		"(He sits down hard among the stones with his keys in his lap. Round him the dead are standing about, a little embarrassed, like guests who have come to the wrong house.)",
		"(From under the ground, close: a small dog, barking. Three times. The dead look at their feet, and go back down into their own graves one after another, and pull the grass over.)",
		"(Joimărița walks down the path in her wedding ribbons with the pot of embers in her hand. She stops in front of him.)",
		"Joimărița: Hands.",
		"(He does not want to. He does it anyway. Everybody does.)",
		"(She turns them over. White. Smooth. Not a mark, not a callus, not a scar.)",
		"Not one day. In your whole life, not one honest day. You carried other people's graves about in bags and sold them their own fear, and you never so much as blistered.",
		"(She tilts the pot. He screams, once, more from surprise than anything.) That is for the ten fingers. Now. In the marriage prison at Biertan there is one bed, one plate, one spoon, and as of this morning a spinning wheel.",
		"You will spin. Hemp, the coarse kind. I will come on Maundy Thursday and look at what you have done, and at your hands. Every year. Until I like what I see.",
		"(Two spiriduși and a bear see him down the hill.)",
	], func():
		G.start_dialogue("The wedding", [
			"(So Father Imre marries them after all, in a graveyard, in Hungarian and Latin and a little Saxon the groom has to help him with.)",
			"(You take Muma Pădurii's oak branch off your belt, the one that was meant for his heart, and push it into the earth by the church wall. Your gift. It is all you have.)",
			"(At \"I will\", it puts out leaves. Small, soft, April green, on the fifteenth of November.)",
			"(They go down the hill together, the bridegroom of 1321 and the Thursday before Easter, arguing about his coat. Behind them all the way to the gate the snowdrops come up through the frost.)",
			"(Magda cries. Vlad gives her his handkerchief without looking, and she takes it without looking. The Solomonar, out of delicacy, makes it rain only on the far side of the wall.)",
			"(The bells start: the Clock Tower first, then the church on the hill, then away down the valley all the others, one by one, as far as Biertan.)",
			"Lorena: (She takes your arm.) Right. Home. And on the way you are going to tell me, slowly, from the beginning, about the trousers.",
		], func():
			G.side_add("fin_done")
			stake_decor = add_decor(Vector2(1000, 450), "oak_twig")
			G.player.coins += 100
			G.ending_t = 0.0
			G.state = G.State.ENDING))

func talk(id: String) -> bool:
	if phase in [1, 2, 3]: return true
	match id:
		"baron": G.start_dialogue("The baron of Biertan", ["(He keeps touching his collar.) Is it straight? She will say it is not straight."])
		"lorena": G.start_dialogue("Lorena", ["Stand there. No, there. Don't slouch, it's a wedding."])
		"bvlad", "bmagda": G.start_dialogue("Magda and Vlad", ["Magda: Stand up straight, you're a witness.", "Vlad: I am standing straight.", "Magda: Straighter."])
		"butcher": G.start_dialogue("Meister Thomas", ["They folded the napkins into hats. I keep telling you."])
		"captain": G.start_dialogue("The spiriduș captain", ["We do the eating at weddings. Tell the priest to hurry up."])
		"mbear": G.start_dialogue("The bear", ["(The bear from the snare, with a ribbon round its neck that it did not agree to. It is looking at the ham.)"])
		"solomonar": G.start_dialogue("The Solomonar", ["I brought the weather. Fine until the vows, I thought, and a little rain after, for luck."])
		"finpriest": G.start_dialogue("Father Imre", ["Paid after. I am always paid after."])
		"azorel": G.start_dialogue("Azorel", ["(He has been given a sausage by somebody very small. He is guarding it.)"])
		_: return false
	return true

func use(p: Prop) -> void:
	match p.id:
		"joimarita": G.start_dialogue("Joimărița", ["It is a waste of a good man, that box. (She is looking at the coffin as if it had been badly spun.)"] if phase == 0 else ["Thursday before Easter. Do not forget. I will come and look at your hands too."])
		"down":
			if phase in [1, 2, 3]: Hud.toast("Not in the middle of a wedding.")
			else: Loader.goto_level("sighisoara")
