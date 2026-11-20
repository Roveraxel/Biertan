## Apold (Trappold) in its valley at the end of October: the fortified church, the long farmyards, the brook.
## Nobody has kept Moșii in years, and the dead have come home to empty tables. Quest: Sâmedru's Fire: prepare
## the offerings, then hold the hungry dead off the table for three waves while Dumitru reads the names.
extends Village

const WAVE_TIME := [0.0, 30.0, 35.0, 40.0]

var table_at := Vector2.ZERO
var fire_at := Vector2.ZERO
var pub_door := Vector2.ZERO
var grave_at: Array[Vector2] = []
var wave := 0
var food := 100.0
var wave_t := 0.0
var banner_pause_t := 0.0
var restart_t := 0.0
var between := ""          # "pot" or "candles" while the hunter helps between waves
var dead: Array[Enemy] = []
var costache: Enemy
var costache_down := false
var pub_pending := false
var pub_t := 0.0

func build() -> void:
	title = "APOLD"
	subtitle = "Trappold · Sâmedru's Fire"
	quest = ApQuest.new()
	arrive_flag = "ap_arrive"
	standard("apold", 1440)
	churches_and_houses()
	add_farms()
	add_yard_walls()
	var pub := G.side_has("ap_dawn") and not G.side_has("ap_done")
	spawn = free_spot(Vector2(6800, 2200), 120.0)   # the road from Șapartoc comes down from the north
	graves_and_trees()
	_quest_things()
	add_street_dressing()
	if pub: spawn = pub_door + Vector2(0, 190)
	finish()

func _quest_things() -> void:
	var has := func(f: String) -> bool: return G.side_has(f)
	var c: Vector2 = m.boxes("churches")[0].c
	add_prop("npc", "dumitru", "Old Dumitru · Shepherd", free_spot(c + Vector2(0, 600), 50.0), "E   Speak with Dumitru", Color("5a4a3a"))
	add_torch(c + Vector2(0, 520), 240.0, Color(1, 0.6, 0.3), 0.6)
	var granny := free_spot(Vector2(4000, 6600), 50.0)
	add_prop("npc", "granny", "The grandmother", granny, "E   Speak with the grandmother", Color("3a3430"))
	add_decor(granny + Vector2(80, -20), "pot_steam", 20.0)
	var baker := free_spot(Vector2(5600, 8100), 50.0)
	add_prop("npc", "baker", "The baker's wife", baker, "E   Speak with the baker's wife", Color("6a5a4a"))
	add_decor(baker + Vector2(110, -20), "oven", 40.0)
	add_torch(baker + Vector2(110, -20), 200.0, Color(1, 0.55, 0.25), 0.6)
	var cellar := cellar_tower(c + Vector2(700, -500), 700.0, func(p): return not near_road(p, 90.0))   # the cellar opens in a little stone tower off the road
	add_prop("task", "cellar", "The cellar", cellar + Vector2(0, 14), "E   Go down into the cellar")
	var chairs := free_spot(Vector2(3600, 7300), 40.0)
	add_decor(chairs, "feast_table", 30.0); add_decor(chairs + Vector2(-120, 20), "chair"); add_decor(chairs + Vector2(120, 20), "chair", 0.0, true)
	add_prop("clue", "chairs", "Empty chairs", chairs + Vector2(0, 60), "E   Look at the table")
	var steps := free_spot(c + Vector2(260, 480), 30.0)
	add_decor(steps, "wet_steps")
	add_prop("clue", "footprints", "Footprints", steps + Vector2(0, 30), "E   Look at the footprints")
	var cems := m.lines("cemeteries")
	var cem := centre(cems[0]) if not cems.is_empty() else Vector2(11100, 3900)
	for i in 3:
		grave_at.append(free_spot(cem + Vector2(-260 + i * 260, 120), 30.0))
		add_decor(grave_at[i], "grave_mound", 18.0)
		add_decor(grave_at[i] + Vector2(0, 30), "candles2" if has.call("ap_grave%d" % i) else "stubs")
		if has.call("ap_grave%d" % i): add_torch(grave_at[i] + Vector2(0, 20), 140.0, Color(1, 0.75, 0.4), 0.5)
		add_prop("task", "grave%d" % i, "A grave", grave_at[i] + Vector2(0, 60), "E   Set two candles")
	add_prop("clue", "stubs", "Candle stubs", free_spot(cem + Vector2(0, -200), 30.0), "E   Look at the graves")
	fire_at = free_spot(Vector2(8800, 1500), 80.0)
	add_decor(fire_at, "bonfire" if has.call("ap_fire") and not has.call("ap_dawn") else "woodpile", 50.0)
	add_prop("clue", "woodpile", "The woodpile", fire_at + Vector2(0, 90), "E   Look at the woodpile")
	add_prop("task", "fire", "The Sâmedru fire", fire_at + Vector2(60, 90), "E   Light the Sâmedru fire")
	table_at = free_spot(cem + Vector2(-900, 500), 120.0)
	add_prop("task", "table", "The table", table_at, "")
	add_decor(table_at + Vector2(0, -10), "feast_table", 40.0)
	add_decor(table_at + Vector2(-110, 20), "chair"); add_decor(table_at + Vector2(110, 20), "chair", 0.0, true)
	add_prop("task", "pot", "The pot", table_at + Vector2(-260, 160), "E   Carry the pot to the table")
	add_prop("task", "candles", "The candles", grave_at[1] + Vector2(0, 120), "E   Light the candles")
	var pub_house := nearest_house(Vector2(4300, 7700))
	pub_door = free_spot(pub_house.c + Vector2(0, maxf(pub_house.size.x, pub_house.size.y) * 0.5 + 80.0), 40.0)
	add_prop("task", "pub", "The pub", pub_door, "")
	if has.call("ap_dawn") and not has.call("ap_done"): _pub_scene()
	add_prop("task", "road", "The road west", free_spot(Vector2(500, 9700), 40.0), "E   Take the road west")
	add_troita(centre_spot())

func candles_on(i: int) -> void:
	add_decor(grave_at[i] + Vector2(0, 30), "candles2")
	add_torch(grave_at[i] + Vector2(0, 20), 140.0, Color(1, 0.75, 0.4), 0.5)

func light_fire() -> void:
	G.side_add("ap_fire")
	add_decor(fire_at, "bonfire", 50.0)
	add_torch(fire_at + Vector2(0, -40), 700.0, Color(1, 0.55, 0.2), 1.4)
	Audio.sfx("fire", -4.0, 0.8)
	Hud.banner("SÂMEDRU'S FIRE", "The light runs down the hill. The dead in it slow, and squint.")

# ------------------------------------------------------------------ the night

func begin_night() -> void:
	G.dusk = 0.8
	WorldBuilder.apply_darkness(self)
	add_decor(table_at + Vector2(-70, 25), "coliva")
	add_decor(table_at + Vector2(70, 25), "colac")
	add_decor(table_at + Vector2(60, -20), "wine")
	add_torch(table_at, 260.0, Color(1, 0.7, 0.4), 0.8)
	Hud.banner("THE NIGHT OF THE DEAD", "Dumitru reads the names. Somewhere in the dark, the dead are coming for their supper.")
	_start_wave(1)

func night_line() -> String:
	if between == "pot": return "The dead fall back. Carry the pot of colivă to the table."
	if between == "candles": return "The dead fall back. Light the candles on the graves."
	if wave == 3 and is_instance_valid(costache) and not costache_down:
		return "Last wave: keep them off the graves, and stop that big one at the table. (Offerings left: %d%%)" % ceili(food)
	return "Wave %d/3: keep the dead off the offerings until the ritual step is done. (Offerings left: %d%%  ·  %d s)" % [wave, ceili(food), ceili(maxf(0.0, WAVE_TIME[wave] - wave_t))]

func _clear_dead() -> void:
	for e in dead:
		if is_instance_valid(e): e.queue_free()
	dead.clear()

func _start_wave(w: int) -> void:
	wave = w; wave_t = 0.0; food = 100.0; between = ""; banner_pause_t = 2.8
	_clear_dead()
	var n: int = [6, 8, 5][w - 1]
	for i in n:
		var g: Vector2 = grave_at[i % 3] if not grave_at.is_empty() else table_at + Vector2(800, -400)
		var e := spawn_enemy("dead_big" if w == 3 else "dead", free_spot(g + Vector2(rng.f_range(-180.0, 180.0), rng.f_range(-180.0, 180.0)), 30.0))
		e.goal = table_at
		if w == 1: e.speed = 165.0
		dead.append(e)
	if w == 3 and not is_instance_valid(costache) and not costache_down:
		var cg: Vector2 = grave_at[1] if grave_at.size() > 1 else table_at + Vector2(-900, 300)
		costache = spawn_enemy("costache", free_spot(cg + Vector2(0, -120), 30.0))
		costache.goal = table_at
		costache.died.connect(func(_e): _costache_down())
	Hud.banner(["THE FIRST WAVE", "THE SECOND WAVE", "THE LAST WAVE"][w - 1], ["They rise from the cemetery and head straight for the table.", "They grab what they can. Hit them and they drop it.", "Bigger ones from the graves, and something very big in a bedsheet."][w - 1])
	Audio.sfx("moroi", -6.0, 0.8)

func _process(dt: float) -> void:
	super(dt)
	if pub_pending and G.state == G.State.PLAY and not G.transitioning:
		pub_t += dt
		if pub_t > 0.8:
			pub_pending = false
			_pub_dialogue()
	if wave == 0 or between != "": return
	if G.state != G.State.PLAY or banner_pause_t > 0.0:
		if banner_pause_t > 0.0 and G.state == G.State.PLAY: banner_pause_t = maxf(0.0, banner_pause_t - dt)
		for e in dead:
			if is_instance_valid(e): e.slow_k = 0.0
		if is_instance_valid(costache): costache.slow_k = 0.0
		return
	if restart_t > 0.0:
		restart_t -= dt
		if restart_t <= 0.0: _start_wave(wave)
		return
	wave_t += dt
	var fire := G.side_has("ap_fire")
	for e in dead:
		if not is_instance_valid(e): continue
		e.slow_k = 0.55 if fire else 1.0   # the firelight reaches every yard in the valley
		if e.at_goal() and e.stun_t <= 0.0: food -= (1.8 if e.kind == "dead_big" else 2.4) * dt
	var big := is_instance_valid(costache) and not costache_down
	if big:
		costache.slow_k = 1.0
		if costache.at_goal(): food -= 5.0 * dt
	var table_prop := prop("table")
	if table_prop: table_prop.sub = "Table: %d%% left" % maxi(0, ceili(food))
	if food <= 0.0:
		Hud.banner("THE DEAD TAKE EVERYTHING", "The table is bare. Dumitru sighs and starts again.")
		_clear_dead()
		restart_t = 3.0; food = 100.0
		return
	var standing := 0
	for e in dead:
		if is_instance_valid(e) and e.hp > 0.0: standing += 1
	if wave_t < WAVE_TIME[wave] and standing > 0: return   # put every one of them back down and the wave is over
	if wave == 3 and big: return   # the big one is still eating
	for e in dead:
		if is_instance_valid(e):
			Fx.text(e.pos, "...fine.", Color(0.75, 0.8, 0.9), 50.0)
			get_tree().create_timer(0.4, false).timeout.connect(e.queue_free)
	dead.clear()
	if wave == 1:
		between = "pot"; Hud.toast("Carry the pot of colivă to the table.")
	elif wave == 2:
		between = "candles"; Hud.toast("Light the candles on the graves.")
	else: _dawn()

func help(id: String) -> void:
	if between != id: return
	if id == "pot":
		add_decor(table_at + Vector2(-40, 30), "pot_steam")
		_start_wave(2)
	else:
		for at in grave_at: add_torch(at + Vector2(0, 30), 160.0, Color(1, 0.8, 0.45), 0.7)
		_start_wave(3)

func _costache_down() -> void:
	costache_down = true
	var at := costache.pos
	get_tree().create_timer(0.1, false).timeout.connect(costache.queue_free)
	add_prop("npc", "costache", "Moș Costache", at + Vector2(0, 40), "E   Look at the 'ghost'", Color("e0e0e0"))
	G.start_dialogue("The big ghost", [
		"(The big ghost goes down hard and stays down. The bedsheet slides off.)",
		"Muddy boots. A clothes peg still on one corner of the sheet. A smell of țuică you could light a lamp with.",
		"Moș Costache, the village drunk. (He groans.) My head hurts... I've got a bump, a cucui... buy me a țuică and the pain will go away.",
		"(You buy him one. You don't drink any.)"])

func _dawn() -> void:
	wave = 0
	G.start_dialogue("Dawn", [
		"The last name is read. The dead stop. One by one they sit down at the table, and eat.",
		"\"Too sweet,\" says an old woman about the colivă. \"My mother made it better.\" \"The wine's not what it was,\" says a man in a Sunday coat.",
		"At first light they fade, still grumbling about the leftovers.",
		"Dumitru blows out the candles, except one, lit from the Sâmedru fire. He gives it to you.",
	], func():
		G.side_add("ap_dawn")
		G.dusk = 0.3
		Loader.goto_level("apold", pub_door + Vector2(0, 190)))

# ------------------------------------------------------------------ the pub

func _pub_scene() -> void:
	# he can stand at the door and look through the window, no further
	for r in [Rect2(-260, -260, 520, 40), Rect2(-260, 260, 520, 40), Rect2(-300, -260, 40, 560), Rect2(260, -260, 40, 560)]:
		add_block(Rect2(pub_door + r.position, r.size), "hidden", 0.0)
	add_prop("npc", "pubcostache", "Moș Costache", pub_door + Vector2(-90, 60), "", Color("e0d0c0"))
	for i in 3: add_prop("npc", "pubghost", "", pub_door + Vector2(50 + i * 55, 45), "", Color("c0d0e0"))
	add_decor(pub_door + Vector2(-50, 80), "tuica")
	add_decor(pub_door + Vector2(105, 20), "bench2")
	add_torch(pub_door + Vector2(0, 60), 300.0, Color(1, 0.65, 0.35), 0.8)
	pub_pending = true

func _pub_dialogue() -> void:
	G.start_dialogue("Through the pub window", [
		"Moș Costache, a bandage round his head and a țuică in his fist, is holding court.",
		"\"...two ghosts, I tell you, with these hands! And a moroi. No, three ghosts. FOUR.\"",
		"At a corner table three pale figures raise their eyebrows. One leans to the others and whispers that Costache ate the whole colivă by himself.",
		"Costache sees you through the glass and raises his glass to you.",
		"I guess with a bit of alcohol, everyone becomes a hero.",
	], func():
		G.side_add("ap_done"); G.side_add("token_samedru_candle")
		G.player.coins += 20
		Audio.sfx("coin", -4.0)
		Hud.toast("Quest complete: Sâmedru's Fire.  Token: a candle lit from Sâmedru's fire")
		for b in blocks.duplicate():
			if b.style == "hidden" and b.c.distance_to(pub_door) < 500.0: remove_block(b))
