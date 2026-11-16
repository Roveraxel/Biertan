## Mălâncrav (Malmkrog) the morning after the Criș feast: the hunter wakes in a haystack without his trousers
## and pieces last night together from witnesses and three playable memories. Then the crypt under the church,
## and at dusk Muma Pădurii at the forest edge, with moroi among her animals.
extends Village

var hay_at := Vector2.ZERO
var edge_at := Vector2.ZERO
var dog_at := Vector2.ZERO
var flag: Decor
var kids: Array[Prop] = []
var granny: Prop
var laugh_t := 0.0
var scold_t := 0.0
var bark_t := 0.0
# the flashbacks
var in_flashback := false
var flash_id := ""
var flash_from := Vector2.ZERO
var saved_dusk := 0.0
var flash_props: Array[Prop] = []
var flash_foes: Array[Enemy] = []
# dusk
var dusk := false
var bear_ally: Prop
var moroi: Array[Enemy] = []
var bear_t := 0.0

func build() -> void:
	title = "MĂLÂNCRAV"
	subtitle = "Malmkrog · The Morning After"
	quest = MlQuest.new()
	arrive_flag = "ml_arrive"
	standard("malancrav", 1460)
	churches_and_houses()
	hay_at = free_spot(Vector2(8150, 3500), 120.0)    # Petru's yard, by the road in from Criș
	add_decor(hay_at, "haystack", 40.0)
	add_farms()
	spawn = free_spot(hay_at + Vector2(0, 140), 40.0)
	graves_and_trees()
	_quest_things()
	finish()

func _quest_things() -> void:
	var has := func(f: String) -> bool: return G.side_has(f)
	var c: Vector2 = m.boxes("churches")[0].c
	add_prop("npc", "petru", "Petru · Farmer", free_spot(hay_at + Vector2(220, 60), 40.0), "E   Speak with Petru", Color("6a5a3a"))
	add_prop("npc", "msexton", "The sexton", free_spot(c + Vector2(300, 420), 40.0), "E   Speak with the sexton", Color("3a3430"))
	var orch := free_spot(Vector2(11800, 6200), 50.0)
	add_prop("npc", "orchard", "The orchard keeper", orch, "E   Speak with the orchard keeper", Color("5a4a2a"))
	for i in 6: add_decor(free_spot(orch + Vector2(-500 + (i % 3) * 420, -380 if i < 3 else 260), 40.0), "plum_tree", 26.0, i % 2 == 0)
	add_prop("npc", "mbaker", "The baker", free_spot(Vector2(9300, 8100), 40.0), "E   Speak with the baker", Color("6a5a4a"))
	add_prop("npc", "mchild", "A child", free_spot(Vector2(6100, 5900), 40.0), "E   Speak with the child")
	var k := free_spot(Vector2(8700, 5600), 40.0)
	kids.append(add_prop("npc", "kidsa", "Children", k, "E   ..."))
	kids.append(add_prop("npc", "kidsb", "Children", k + Vector2(70, 30), "E   ..."))
	granny = add_prop("npc", "mgranny", "A grandmother", free_spot(Vector2(9100, 6700), 40.0), "E   ...")
	dog_at = free_spot(Vector2(8000, 6100), 30.0)
	add_decor(dog_at, "dog_bark")
	# the three things from last night
	if not has.call("ml_f_cup"):
		var cp := free_spot(Vector2(8550, 6500), 30.0)
		add_decor(cp, "empty_cup"); add_prop("task", "cup", "An empty cup", cp + Vector2(0, 40), "E   Look at the cup")
	if not has.call("ml_f_twig"):
		var tw := free_spot(Vector2(1500, 5600), 30.0)
		add_decor(tw, "wilted_twig"); add_prop("task", "twig", "A wilted twig", tw + Vector2(0, 40), "E   Pick up the twig")
	if not has.call("ml_f_stones"):
		var ps := free_spot(orch + Vector2(-180, 120), 30.0)
		add_decor(ps, "plum_stones"); add_prop("task", "stones", "Plum stones", ps + Vector2(0, 40), "E   Look at the plum stones")
	# the tower, the weathervane, the crypt
	var tower := free_spot(c + Vector2(-560, 260), 40.0)
	add_prop("task", "tower", "The church tower", tower, "E   Climb the tower")
	if not has.call("ml_pants"): flag = add_decor(tower + Vector2(-60, -40), "trousers_flag")
	var door := free_spot(c + Vector2(200, 380), 40.0)
	MlQuest.crypt_door = door
	add_decor(door, "crypt_stairs")
	add_prop("task", "crypt", "The crypt stairs", door + Vector2(0, 40), "E   Go down into the crypt")
	# the edge of the village, where the forest begins
	edge_at = free_spot(Vector2(2100, 5300), 80.0)
	if has.call("ml_crypt") and not has.call("ml_stake"): _dusk()
	add_prop("task", "road", "The road west", free_spot(Vector2(400, 5150), 40.0), "E   Take the road to Richiș")
	add_troita(centre_spot())

# ------------------------------------------------------------------ the morning after

func _process(dt: float) -> void:
	super(dt)
	if not is_instance_valid(G.player): return
	var bare := G.side_has("ml_pantsless") and not G.side_has("ml_pants") and not in_flashback
	G.player.no_trousers = bare
	if in_flashback and G.player.drunk_t <= 0.0: G.player.drunk_t = 2.0
	if dusk: _dusk_step(dt)
	if not bare or G.state != G.State.PLAY: return
	var pl: Vector2 = G.player.pos
	laugh_t -= dt; scold_t -= dt; bark_t -= dt
	for kd in kids:
		if is_instance_valid(kd) and laugh_t <= 0.0 and pl.distance_to(kd.pos) < 420.0:
			laugh_t = 2.2
			Fx.text(kd.pos, "HAHAHA!" if randf() < 0.5 else "Look at his legs!", Fx.AMBER, 70.0)
	if is_instance_valid(granny) and scold_t <= 0.0 and pl.distance_to(granny.pos) < 420.0:
		scold_t = 3.0
		Fx.text(granny.pos, "Shame! SHAME!", Color(1, 0.7, 0.6), 70.0)
	if bark_t <= 0.0 and pl.distance_to(dog_at) < 380.0:
		bark_t = 1.6
		Fx.text(dog_at, "WOOF! WOOF!", Fx.AMBER, 50.0)
		Audio.sfx_at("bark", dog_at, -8.0)

# ------------------------------------------------------------------ the flashbacks

func flash_line() -> String:
	match flash_id:
		"cup": return "Last night, at the Criș feast. (Everything is spinning.)"
		"twig": return "Last night, at the forest edge. (You are very, very drunk.)"
	return "Last night, in the plum orchard. (The wolves are real.)"

func flashback(id: String) -> void:
	in_flashback = true; flash_id = id
	flash_from = G.player.pos
	if G.STORIES.has("flash_" + id):   # the memory comes back as a picture first, then he is in it
		await G.show_story("flash_" + id)
		Hud.fade_to(0.0, 0.6)
	saved_dusk = G.dusk; G.dusk = 0.9
	G.player.drunk_t = 2.0
	Audio.sfx("blip", -4.0, 0.5)
	var g: Vector2 = G.player.pos
	match id:
		"cup":
			Hud.banner("LAST NIGHT · CRIȘ", "The feast. Your cup is never empty for long.")
			G.start_choice("Last night", [
				"(Lanterns. Fiddles. Somebody's uncle is pouring. You are standing on the table, and you have opinions.)",
				"What do you do?",
			], ["Dance. Magnificently.", "Challenge the entire village to arm-wrestling", "Sing the anthem backwards"], func(pick: int):
				var said := ["(You dance. A bench breaks. A man named Ion takes it personally.)", "(Nobody accepts. You take this as an insult, and so does Ion.)", "(It is not the anthem. Ion's mother is offended. Ion is offended.)"]
				G.start_dialogue("Last night", [said[pick], "(Fists. Everybody's fists. Yours keep missing.)"], func():
					Hud.banner("THE BRAWL", "Your swings go everywhere except where you aim. Nobody gets hurt. Much.")
					for i in 4:
						var a := i * PI / 2.0 + 0.4
						var e := spawn_enemy("brawler", free_spot(g + Vector2(cos(a), sin(a)) * 320.0, 30.0))
						flash_foes.append(e)
						e.died.connect(func(_e): _foe_down())))
		"twig":
			Hud.banner("LAST NIGHT · THE FOREST EDGE", "An old woman under the trees. You have something important to tell her.")
			flash_props.append(add_prop("npc", "muma", "Muma Pădurii", free_spot(g + Vector2(0, -180), 30.0), ""))
			flash_props.append(add_prop("npc", "mbear", "The bear", free_spot(g + Vector2(260, -60), 40.0), ""))
			G.start_choice("Last night", [
				"(The forest edge. The old woman from the oak is standing in the moonlight. The bear from the snare is behind you, eating your bread.)",
				"(You have had a great deal to drink, and you have never been more sure of anything.)",
			], ["\"You are the most beautiful woman in Transylvania.\"", "\"I swear on my hat to guard your animals.\"", "\"Take my fluier. As a pledge. Of love. Or something.\""], func(pick: int):
				var said := [
					"(Muma Pădurii goes a deep green. Nobody has said that to her in four hundred years.)",
					"(She looks at your hat. It is a good hat. She nods slowly.)",
					"(She takes the flute as if it might bite her.)"]
				G.start_dialogue("Last night", [
					said[pick],
					"(You say all three things anyway, and then you put your fluier into her hands and swear, very loudly, to protect her animals in every forest you walk through.)",
					"Muma Pădurii: \"Sober up, hunter. Then we'll see if you meant it.\"",
					"(She goes. The bear stays. The bear has decided you are its friend now.)",
				], func():
					G.side_add("ml_fluier")
					_end_flash()))
		_:
			Hud.banner("LAST NIGHT · THE PLUM ORCHARD", "The top tree has the best plums. You fall out of it. Then the wolves come.")
			G.start_dialogue("Last night", [
				"(Plums. So many plums. You eat them standing in the tree, spitting the stones at the moon.)",
				"(The branch goes. You go with it. Eyes in the dark.)",
				"(You grab a branch and a barrel lid. You have never felt so ready, or so unable to stand.)",
			], func():
				for i in 3:
					var a := i * 2.1
					var e := spawn_enemy("wolf", free_spot(g + Vector2(cos(a), sin(a)) * 380.0, 30.0))
					e.flee_low = true; e.aggro = 3000.0; e.state = "chase"
					flash_foes.append(e)
					e.fled.connect(func(_e): _foe_down()))

func _foe_down() -> void:
	for e in flash_foes:
		if is_instance_valid(e) and not e.fleeing and not e.fainted: return
	if flash_id == "cup":
		G.start_dialogue("Last night", [
			"(Ion is asleep under the table. So is his cousin. You are declared the winner by somebody's grandmother.)",
			"(You remember taking a cup with you \"for the road\". You remember the road. You do not remember the cup going empty.)",
		], _end_flash)
	elif flash_id == "stones":
		await G.show_story("flash_stones2")
		Hud.fade_to(0.0, 0.6)
		G.start_dialogue("Last night", [
			"(The wolves run. You chase them, then you forget why, then you see the church.)",
			"(Up the tower. The bell. You ring it until your arms give out. Far away, so far you might have dreamt it, another bell answers.)",
			"\"I AM THE KING OF MĂLÂNCRAV!\"",
			"(A king needs a flag. You look down at what you have to hand. Well.)",
		], _end_flash)

func _end_flash() -> void:
	if not in_flashback: return
	for p in flash_props:
		if is_instance_valid(p): remove_prop(p)
	for e in flash_foes:
		if is_instance_valid(e): e.queue_free()
	for e in Enemy.fainted_ones.duplicate():
		if is_instance_valid(e) and e.kind == "brawler": e.queue_free()
	flash_props.clear(); flash_foes.clear()
	G.player.drunk_t = 0.0
	G.dusk = saved_dusk
	G.player.pos = flash_from
	G.side_add("ml_f_" + flash_id)
	for p in props.duplicate():
		if is_instance_valid(p) and p.id == flash_id: remove_prop(p)
	in_flashback = false
	Hud.toast("Remembered %d/%d" % [MlQuest.remembered(), MlQuest.FLASH.size()])

# ------------------------------------------------------------------ the trousers

func climb_tower() -> void:
	G.start_dialogue("The church tower", [
		"(A short, sober climb. Every step of it, the whole village watches from below.)",
		"(The weathervane. Your trousers, snapping in the wind like the banner of a small, foolish kingdom. There is a hole in the seat.)",
		"(You put them on, up there, in front of everybody. The children cheer.)",
		"The sexton, from the bottom of the ladder: \"When you rang my bell last night, hunter... Biertan's bell answered. All the way from Biertan. I heard it.\"",
		"(Under your feet, under the church, something shifts.)",
	], func():
		G.side_add("ml_pants")
		G.player.no_trousers = false
		if is_instance_valid(flag): remove_decor(flag)
		Audio.sfx("bell", -6.0, 0.8)
		Hud.banner("THE BELL ANSWERS", "Something under the church has woken up."))

# ------------------------------------------------------------------ dusk, the moroi and Muma Pădurii

func _dusk() -> void:
	G.dusk = 0.8
	add_prop("npc", "muma", "Muma Pădurii", edge_at + Vector2(-120, -80), "E   Speak with Muma Pădurii", Color("4a5a3a"))
	for i in 4: add_decor(free_spot(edge_at + Vector2(-300 + i * 180, 160 + (i % 2) * 70), 20.0), "sheep_lie", 0.0, i % 2 == 1)
	bear_ally = add_prop("npc", "mbear", "The bear", free_spot(edge_at + Vector2(200, -40), 40.0), "E   Look at the bear")
	if G.side_has("ml_moroi"): return
	dusk = true
	for o in [Vector2(-700, -500), Vector2(-800, 300), Vector2(600, -600), Vector2(700, 500)]:
		var e := spawn_enemy("moroi", free_spot(edge_at + o, 30.0))
		e.state = "chase"; e.aggro = 3000.0
		moroi.append(e)
		e.died.connect(func(_e): _moroi_down())

func on_enter() -> void:
	if G.side_has("ml_crypt") and not G.side_has("ml_stake"): G.dusk = 0.8   # the loader resets the hour on arrival

func _dusk_step(dt: float) -> void:
	if not is_instance_valid(bear_ally): return
	bear_t -= dt
	var best: Enemy = null; var bd := INF
	var bp := bear_ally.pos
	for e in moroi:
		if is_instance_valid(e) and e.hp > 0.0 and bp.distance_to(e.pos) < bd:
			bd = bp.distance_to(e.pos); best = e
	if best == null: return
	if bd > 110.0: bear_ally.pos = bp.move_toward(best.pos, 150.0 * dt)
	elif bear_t <= 0.0:
		bear_t = 1.1
		best.hurt(16.0, (best.pos - bp).normalized())
		Fx.text(bp, "GRRRAWR", Fx.AMBER, 90.0)
		Audio.sfx_at("boss_roar", bp, -10.0, 1.2)

func _moroi_down() -> void:
	for e in moroi:
		if is_instance_valid(e) and e.hp > 0.0: return
	if not dusk: return
	dusk = false
	G.side_add("ml_moroi")
	Hud.banner("THE ANIMALS ARE SAFE", "The bear sits down among the sheep, enormously pleased with itself.")

func muma_talk() -> void:
	if not G.side_has("ml_moroi"):
		G.start_dialogue("Muma Pădurii", ["Words are cheap, hunter. My animals are dying. Show me."])
		return
	if G.side_has("ml_stake"):
		G.start_dialogue("Muma Pădurii", ["Go. Biertan is waiting, and so is what sleeps there."])
		return
	G.start_dialogue("Muma Pădurii", [
		"(She is holding your fluier. She turns it over in her bark-brown fingers.)",
		"Drunk men swear a great many things. Most of them forget by noon. You came back, and you fought for them sober.",
		"(She gives you the fluier.) Then the oath holds. My animals are under your protection in every forest you walk, and you are under mine.",
		"(She lays a fallen oak branch across your hands, one end sharp as a spike.) A tree that gave itself. Keep it for whoever sleeps where he should not.",
		"(You hang it on your belt. It is heavier than it looks.)",
	], func():
		G.side_add("ml_stake")
		Hud.toast("The fluier, returned.  Muma's oak branch hangs on your belt."))
