## The game's state: where the hunter is, what he has done, dialogue, story cards, saving. Autoloaded as G.
extends Node

enum State { TITLE, PLAY, DIALOGUE, DEAD, ENDING, STORY, BESTIARY, MAP }

signal story_closed

## Recaps, played once on the road out of a village after its job is done: panels of drawing and caption.
const RECAP_AFTER := {"sighisoara": "sig_deal", "cris": "cs_done", "viscri": "vis_done", "crit": "cr_done", "saschiz": "sx_done", "sapartoc": "sp_done", "apold": "ap_done", "malancrav": "ml_done", "richisvillage": "rc_done"}

const STORIES := {
	"recap_viscri": {"title": "VISCRI", "panels": [{"art": "recap_viscri", "text": "In Viscri the dogs had gone silent and the sexton's boots were far too clean. The hunter got the cellar key, Matei got his supper, and the village learned that a quiet dog is never a good sign."}], "fact": ""},
	"recap_crit": {"title": "CRIȚ", "panels": [{"art": "recap_crit", "text": "Floarea soaked her trousseau on a Friday and had her fingers scorched for it. The hunter climbed the mountain with an apple and a poppy to beg for mercy, and Sfânta Vineri took pity on the girl. She looked at him like an uninvited goat."}], "fact": ""},
	"recap_saschiz": {"title": "SASCHIZ", "panels": [{"art": "recap_saschiz", "text": "The mob above Saschiz wanted blood, but the hunter found a lonely giant playing horses with three stolen children in his apron. He brought them down without drawing steel, and the mother pressed a stone from the fortress into his hand."}], "fact": ""},
	"recap_sapartoc": {"title": "ȘAPARTOC", "panels": [{"art": "recap_sapartoc", "text": "Three empty churches and one noisy ghost. The hunter put soup in the Catholic nave, fiddles in the Saxon tower, and poured enough plum wine down a sleeping priest to hold a mass. By evening, families were moving back in."}], "fact": ""},
	"recap_apold": {"title": "APOLD", "panels": [{"art": "recap_apold", "text": "On Sâmedru's night the dead came home for supper, grumbling about the colivă, and the hunter kept them from eating the tables. He stood by the bonfire until dawn, smelling of smoke and old tallow, and lit a candle from its flame."}], "fact": ""},
	"recap_malancrav": {"title": "MĂLÂNCRAV", "panels": [{"art": "recap_malancrav", "text": "He woke in a haystack without his trousers, swore he had only had three cups, and had to climb the church tower to fetch them from the weathervane. The children cheered. The valley still tells the rest."}], "fact": ""},
	"recap_richisvillage": {"title": "RICHIȘ", "panels": [{"art": "recap_richisvillage", "text": "Seven Iele danced on the frost. Moș Ilie played the doina on his pan flute until his lips bled, while the hunter stood in the circle taking blows meant for a phantom. Toader came back to his right mind, and the road to Biertan opened."}], "fact": ""},
	"recap_cris": {"night": true, "sway": true, 
		"title": "THE FEAST · CRIȘ",
		"panels": [
			{"art": "feast_1", "text": "Muma Pădurii's curse was lifted, and Criș burned the rye in the square and laid the tables. Somebody's uncle poured the țuică. Somebody else's uncle poured it again."},
			{"art": "feast_2", "text": "Behind the barn two lads from Mălâncrav were burning a bundle of something that was not hay. The smoke curled up into little dancers. The hunter laughed until he forgot what at."},
			{"art": "feast_3", "text": "Then the lanterns began to turn, and the moon, and the church tower, and the road. He set off for Mălâncrav with a cup \"for the road\". After that, nothing."},
		],
		"fact": "",
	},
	"supper_biertan": {"night": true, "title": "THE BARON'S TABLE", "panels": [
		{"art": "supper_1", "text": "Candles down the long table, under the walls of Biertan. Roast meat, warm bread, wine from his own vines. Everything you could want on a table, except salt."},
		{"art": "supper_2", "text": "He carves for you, he pours for you, he asks about every village on your road. His cup stays full all evening, and his plate stays clean."},
	], "fact": ""},
	"sexton_end": {"night": true, "title": "THE SEXTON'S HANDS", "panels": [
		{"art": "sexton_1", "text": "The keys fall into his lap. Under the floor a small dog barks three times, and the dead sink back under their slabs like guests who have come to the wrong house. Joimărița comes down the nave with the pot of embers, and holds out her hand for his."},
	], "fact": ""},
	"balaur_rise": {"night": true, "title": "THE SOLOMONAR", "panels": [
		{"art": "balaur_1", "text": "Seven years in the school under the mountain, and he rides out on the storm. He reads aloud from his book, and the cloud over the quarry turns like a millstone."},
		{"art": "balaur_2", "text": "Out of it comes the balaur, the hail-serpent the Solomonari ride, and the lightning runs down its back looking for the tallest thing in the gorge. Stand by the old stones."},
	], "fact": "The Solomonari of Romanian folklore were weather-wizards schooled in a hidden lake-school, said to ride balauri, dragons that bring hail."},
	"act_2": {"night": true, "title": "ACT II · BIERTAN", "panels": [
		{"art": "act_2", "text": "Biertan. Three rings of wall on one hill, a hall church on top like a ship, a covered stair up to it. A busy, friendly village, where nobody keeps a dog, and the baron himself comes down to meet you."},
	], "fact": ""},
	"act_3": {"night": true, "title": "ACT III · DOWN THE STAIR", "panels": [
		{"art": "act_3", "text": "He went down the stair under his own tomb. The way runs east under the hills, through a gorge where the weather has a master, the vineyards, the Wolf Forest, and the old ground of a small pale dog."},
	], "fact": ""},
	"act_4": {"night": true, "title": "ACT IV · THE OPEN GATE", "panels": [
		{"art": "act_4", "text": "Lorena's gate stands open. Her shawl is on the path and her lamp still burns. Azorel lies across the step with a scrap of very old, very good black cloth in his teeth."},
	], "fact": ""},
	"flash_cup": {"night": true, "sway": true, "title": "LAST NIGHT", "panels": [{"art": "flash_cup", "text": "It comes back in pieces. The feast in Criș. A table. You, on the table. A bench that was not built for this."}], "fact": ""},
	"flash_twig": {"night": true, "sway": true, "title": "LAST NIGHT", "panels": [{"art": "flash_twig", "text": "The forest edge, the moon, and an old woman made of bark. You had something very important to tell her."}], "fact": ""},
	"flash_stones": {"night": true, "sway": true, "title": "LAST NIGHT", "panels": [{"art": "flash_stones_1", "text": "The plum orchard. The best plums are at the top. So is the branch that breaks. And in the grass below, eyes."}], "fact": ""},
	"flash_stones2": {"night": true, "sway": true, "title": "LAST NIGHT", "panels": [{"art": "flash_stones_2", "text": "The tower. The bell. The whole valley listening. A king needs a flag, and you had one on you."}], "fact": ""},
	"recap_sighisoara": {
		"title": "SIGHIȘOARA",
		"panels": [
			{"art": "sighisoara_1", "text": "The guild's bacon was going missing from the Butchers' Tower, a slab a night, and Meister Thomas wanted a man who could catch thieves nobody had seen."},
			{"art": "sighisoara_2", "text": "Flour footprints with long toes led under the tower, to the spiriduși: little house spirits gone hungry since the town stopped leaving them a bowl. One of them took the hunter's hat."},
			{"art": "sighisoara_3", "text": "Now the guild feeds them, and they sweep and mend at night. The hat came back. At dawn Vlad Laurențiu's cart left for Viscri, Magda arguing on the bench and Azorel guarding the salt."},
		],
		"fact": "",
	},
	"prologue": {
		"title": "ACT I · THE STÂNĂ",
		"lore": "A summer on the high pastures above Sibiu. The hunter put his blade away years ago; now he minds other people's cows, with Azorel, a Carpathian shepherd dog who is quite sure he is the one in charge. Tomorrow the animals go down to the villages for the winter.",
		"fact": "Every autumn Romanian shepherds and herders bring their animals down from the mountain pastures to the valleys. The yearly walk is called transhumanță, and the summer camp with its fold and hut is the stână."
	},
	"descent": {
		"title": "DOWN TO THE VALLEY",
		"lore": "At first light he handed the cows back to their owners, took his wage in coins and cheese, and went down the old road with Azorel at his heel: through Sibiu, past a troiță at every crossroads, north to Sighișoara, where a man who knows his way with a blade can find winter work.",
		"fact": "The road from Sibiu to Sighișoara crosses Terra Saxonum, the Saxon land of southern Transylvania, where every village stands round a fortified church."
	},
	"saschiz": {
		"title": "SASCHIZ",
		"lore": "The giant set the three children down in the church square, one by one, as gently as eggs. By morning the children of Saschiz were running again over the green and golden hills above the village, chasing lambs between the haystacks, and nobody called them home before dark.",
		"fact": "Saxon settlers raised Saschiz's fortified church in the 15th century. Its tower echoes the clock tower of Sighișoara, and the village is one of Transylvania's UNESCO-listed villages with fortified churches."
	},
	"richis": {
		"title": "RICHIȘ",
		"lore": "Ioan, Mitzi and Grete came home through the beech woods at dawn with moss in their hair. That summer they played in the wildflower meadows on the slopes, and the Green Men carved in the church seemed, the old women swore, to be smiling.",
		"fact": "Richiș's Gothic hall church is famous for the Green Men carved in its choir: stone faces wreathed in oak leaves, left by Saxon masons centuries ago."
	},
	"mosna": {
		"title": "MOȘNA",
		"lore": "Carts rolled down the Biertan road again. In the vineyards above Moșna the children picked the last grapes and slid down the hay meadows, and on Sunday every family cut a slice of ham from the tower.",
		"fact": "Moșna's great late-Gothic hall church stands inside a ring of walls and towers. Like many Saxon villages, it kept each family's bacon safe in a fortified tower."
	},
	"biertan": {
		"title": "BIERTAN",
		"lore": "The great bell rang over the valley, and the dead lay down. The children of Biertan climbed all three walls to watch the sun come up over the hills: green and gold and purple with heather, as far as Saschiz.",
		"fact": "Biertan was the seat of the Lutheran bishops of Transylvania from 1572 to 1867. Its church, guarded by three rings of walls, keeps a sacristy door with nineteen locks and the famous 'marriage prison'."
	},
}

const ROAD := {
	"stana": "stana", "sighisoara": "sighisoara", "cellar": "sighisoara", "viscri": "viscri", "crypt": "viscri",
	"crit": "crit", "critforest": "crit", "saschiz": "saschiz", "uriasi": "saschiz", "sapartoc": "sapartoc",
	"apold": "apold", "cris": "cris", "crisforest": "cris", "malancrav": "malancrav", "malcrypt": "malancrav",
	"richisvillage": "richisvillage", "richisforest": "richisvillage", "ieleridge": "richisvillage",
	"biertanfort": "biertanfort", "sacristy": "biertanfort", "draculhouse": "sighisoara",
}
const NAMES := {
	"stana": "the stână", "sighisoara": "Sighișoara", "viscri": "Viscri", "crit": "Criț", "saschiz": "Saschiz",
	"sapartoc": "Șapartoc", "apold": "Apold", "cris": "Criș", "malancrav": "Mălâncrav", "richisvillage": "Richiș",
	"biertanfort": "Biertan", "biertan": "Biertan", "mosna": "Moșna", "richis": "Richiș", "hub": "Saschiz",
}
const SAVE_PATH := "user://biertan_save.json"
const COMPLETE_PATH := "user://biertan_completed.flag"

var state: State = State.TITLE
var current := ""
var player: Player
var level: Level
var boss = null
var transitioning := false
var t := 0.0

# ---- what he has done ----
var quest := 0        # the old chapters: Vârcolac, Muma, Balaur, Vlad
var quest2 := 0
var quest3 := 0
var quest4 := 0
var smith_level := 0
var met_ileana := false
var visited_richis := false
var met_vasile := false
var rozalia_thanked := false
var visited_mosna := false
var visited_biertan := false
var sofia_gift := false
var ewe_quest := 0
var side := {}        # a set of everything else: clues read, jobs done, places seen
var midnight_done := false
var dusk := 0.3
var saved_road := ""
var save_t := 0.0
var ending_t := 0.0
var story_id := ""
var story_t := 0.0
var story_panel := 0
var last_story := ""
var test_mode := false
var cam_look: Node3D = null   # when set, the camera watches this instead of the hunter (a scene he spies on)
var instant := false     # automated runs: skip fades, cards and pauses

# ---- dialogue ----
var dlg_speaker := ""
var dlg_lines: Array = []
var dlg_idx := 0
var dlg_after := Callable()
var dlg_choices: Array = []
var dlg_sel := 0
var dlg_pick := Callable()
var dlg_frame := 0
var input_block := 0.0   # brief lockout after a dialogue closes so the same key press doesn't re-open it

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(dt: float) -> void:
	t += dt
	if state == State.PLAY:
		save_t += dt
		if save_t > 20.0 and is_instance_valid(player) and player.hp > 0.0 and road_village() != "": save_game()
		if current in ["forest", "hills", "vineyard"]:
			dusk = minf(1.0, dusk + dt / 240.0)
			if dusk >= 1.0 and not midnight_done: _strike_midnight()
		elif current in ["hub", "richis", "mosna"]:
			dusk = move_toward(dusk, 0.45, dt * 0.4)
	if is_instance_valid(player): player.frozen = state != State.PLAY
	input_block = maxf(0.0, input_block - dt)
	if state == State.STORY: story_t += dt
	if state == State.ENDING: ending_t += dt

# ------------------------------------------------------------------ helpers

func side_has(key: String) -> bool: return side.has(key)
func side_add(key: String) -> void: side[key] = true

func _count(keys: Array) -> int:
	var n := 0
	for k in keys:
		if side.has(k): n += 1
	return n

func ewes_found() -> int: return _count(["ewe1", "ewe2", "ewe3"])
func treasures_found() -> int: return _count(["tr1", "tr2", "tr3"])

## How hard the old chapters hit: x multiplies creature health, y their damage.
func difficulty() -> Vector2:
	match current:
		"forest", "arena": return Vector2(1.0, 0.85)
		"hills", "caves", "hollow": return Vector2(1.4, 1.25)
		"vineyard", "gorge": return Vector2(1.7, 1.45)
		"walls", "church": return Vector2(2.0, 1.6)
	return Vector2.ONE

## The village of the road this place belongs to ("" off the road).
func road_village() -> String:
	return ROAD.get(current, "")

## Where the hunter wakes after a fall.
func home() -> String:
	if road_village() != "": return road_village()
	if saved_road != "": return saved_road
	if visited_biertan: return "biertan"
	if visited_mosna: return "mosna"
	if visited_richis: return "richis"
	return "hub"

func home_name() -> String:
	return NAMES.get(home(), "Saschiz")

# ------------------------------------------------------------------ dialogue

func choosing_now() -> bool:
	return state == State.DIALOGUE and not dlg_choices.is_empty() and dlg_idx == dlg_lines.size() - 1

func start_dialogue(who: String, lines: Array, after := Callable()) -> void:
	dlg_choices = []
	dlg_pick = Callable()
	dlg_speaker = who
	dlg_lines = lines
	dlg_idx = 0
	dlg_after = after
	dlg_frame = Engine.get_process_frames()
	state = State.DIALOGUE
	Audio.sfx("blip", -6.0)

## A dialogue that ends on a choice; `pick` gets the index chosen.
func start_choice(who: String, lines: Array, choices: Array, pick: Callable) -> void:
	start_dialogue(who, lines)
	dlg_choices = choices
	dlg_sel = 0
	dlg_pick = pick

func advance_dialogue() -> void:
	dlg_idx += 1
	Audio.sfx("blip", -8.0, 0.9)
	if dlg_idx < dlg_lines.size(): return
	state = State.PLAY
	input_block = 0.25
	var after := dlg_after; var pick := dlg_pick; var sel := dlg_sel
	dlg_after = Callable(); dlg_pick = Callable(); dlg_choices = []
	if after.is_valid(): after.call()
	if pick.is_valid(): pick.call(sel)

## Say something and wait until it has been read (for scripted scenes).
var _hm_n := 0

func say(who: String, lines: Array) -> void:
	if who == "You":
		_hm_n += 1
		if _hm_n % 3 == 0: Audio.sfx("hunter_hm", -3.0)   # the hunter's thoughts: now and then he hums
	start_dialogue(who, lines)
	while state == State.DIALOGUE: await get_tree().process_frame

func wait(seconds: float) -> void:
	if instant: return
	await get_tree().create_timer(seconds, false).timeout

# ------------------------------------------------------------------ story cards

## Show a story card and wait until it is closed. The screen is left black: the caller opens the next scene.
func show_story(card: String) -> void:
	last_story = card
	if instant: return
	await Hud.fade_to(1.0, 0.8)
	story_id = card
	story_t = 0.0
	story_panel = 0
	# the folk interlude under every story card (two takes, chosen by the card), then back to the place's tune
	var before: String = Audio.track; var before_db: float = Audio.track_db
	Audio.set_music("music_story" if card.hash() % 2 == 0 else "music_story2", -7.0)
	state = State.STORY
	Audio.sfx("bell", -6.0, 1.0)
	Narration.speak(card, 0)
	await Hud.fade_to(0.0, 0.6)
	if test_mode:
		await wait(2.0)
		close_story()
	else:
		await story_closed
	await Hud.fade_to(1.0, 0.4)
	if before != "": Audio.set_music(before, before_db)
	state = State.PLAY

func close_story() -> void:
	# a recap turns its pages first; the last one closes it
	var panels: Array = STORIES.get(story_id, {}).get("panels", [])
	if story_panel < panels.size() - 1:
		story_panel += 1
		story_t = 0.35
		Audio.sfx("blip", -10.0, 0.8)
		Narration.speak(story_id, story_panel)
		return
	Audio.voice(null)
	story_t = -999.0
	story_closed.emit()

func leave_ending() -> void:
	mark_completed()
	ending_t = -999.0
	to_title()

func mark_completed() -> void:
	var f := FileAccess.open(COMPLETE_PATH, FileAccess.WRITE)
	if f: f.store_string("1")

func is_completed() -> bool:
	return FileAccess.file_exists(COMPLETE_PATH) or side_has("bt_home") or side_has("fin_done")

const CHAPTERS := [
	{"name": "Prologue · The Stână", "level": "stana", "flags": [], "hp": 100.0, "dmg": 12.0, "coins": 20, "salt": false},
	{"name": "Act I · Sighișoara", "level": "sighisoara", "flags": [], "hp": 100.0, "dmg": 12.0, "coins": 30, "salt": false},
	{"name": "Act I · Viscri", "level": "viscri", "flags": ["sig_deal"], "hp": 105.0, "dmg": 13.0, "coins": 45, "salt": false},
	{"name": "Act I · Criț", "level": "crit", "flags": ["sig_deal", "vis_done"], "hp": 110.0, "dmg": 14.0, "coins": 65, "salt": false},
	{"name": "Act I · Saschiz", "level": "saschiz", "flags": ["sig_deal", "vis_done", "cr_done"], "hp": 115.0, "dmg": 15.0, "coins": 85, "salt": false},
	{"name": "Act I · Șapartoc", "level": "sapartoc", "flags": ["sig_deal", "vis_done", "cr_done", "sx_done"], "hp": 120.0, "dmg": 16.0, "coins": 100, "salt": false},
	{"name": "Act I · Apold", "level": "apold", "flags": ["sig_deal", "vis_done", "cr_done", "sx_done", "sp_done"], "hp": 120.0, "dmg": 17.0, "coins": 115, "salt": true},
	{"name": "Act I · Criș & Mălâncrav", "level": "cris", "flags": ["sig_deal", "vis_done", "cr_done", "sx_done", "sp_done", "ap_done"], "hp": 125.0, "dmg": 18.0, "coins": 130, "salt": true},
	{"name": "Act I · Richiș", "level": "richisvillage", "flags": ["sig_deal", "vis_done", "cr_done", "sx_done", "sp_done", "ap_done", "cs_done", "ml_done"], "hp": 130.0, "dmg": 19.0, "coins": 145, "salt": true},
	{"name": "Act II · Biertan", "level": "biertanfort", "flags": ["sig_deal", "vis_done", "cr_done", "sx_done", "sp_done", "ap_done", "cs_done", "ml_done", "rc_done"], "hp": 135.0, "dmg": 20.0, "coins": 160, "salt": true},
	{"name": "Act III · The Gorge", "level": "gorge", "flags": ["sig_deal", "vis_done", "cr_done", "sx_done", "sp_done", "ap_done", "cs_done", "ml_done", "rc_done", "bt_fled"], "hp": 145.0, "dmg": 22.0, "coins": 180, "salt": true},
	{"name": "Act IV · The Open Gate", "level": "viscri", "flags": ["sig_deal", "vis_done", "cr_done", "sx_done", "sp_done", "ap_done", "cs_done", "ml_done", "rc_done", "bt_fled", "bt_done"], "hp": 150.0, "dmg": 25.0, "coins": 200, "salt": true},
]

func start_chapter(idx: int) -> void:
	if transitioning or idx < 0 or idx >= CHAPTERS.size(): return
	var ch: Dictionary = CHAPTERS[idx]
	player.reset_stats()
	quest = 0; quest2 = 0; quest3 = 0; quest4 = 0
	smith_level = 0; ewe_quest = 0
	met_ileana = false; visited_richis = false; met_vasile = false
	rozalia_thanked = false; visited_mosna = false; visited_biertan = false; sofia_gift = false
	side.clear()
	for f in ch.flags: side[f] = true
	player.max_hp = ch.hp; player.hp = ch.hp; player.dmg = ch.dmg
	player.coins = ch.coins; player.potions = 2
	player.salt_unlocked = ch.salt; player.salt = 6 if ch.salt else 0
	saved_road = ch.level if ch.level != "gorge" else "biertanfort"
	Loader.goto_level(ch.level)

func to_title() -> void:
	await Hud.fade_to(1.0, 0.6)
	Loader.unload()
	state = State.TITLE
	Audio.set_music("music_hub", -9.0)
	await Hud.fade_to(0.0, 0.6)

func _strike_midnight() -> void:
	midnight_done = true
	Hud.banner("MIDNIGHT · CEASUL RĂU", "The evil hour. Blue flames burn where treasure lies buried." if current == "forest" else "The evil hour. The dead are at their strongest.")
	for i in 12:
		Audio.sfx("bell", -10.0, 0.62)
		await wait(0.45)
		if current == "" or state == State.TITLE: return

# ------------------------------------------------------------------ falling and rising

func on_player_died() -> void:
	state = State.DEAD
	player.frozen = true
	save_game()   # keep everything learned up to the fall
	Audio.sfx("boss_roar", -10.0, 1.5)

func respawn() -> void:
	player.hp = player.max_hp
	player.frozen = false
	state = State.PLAY
	dusk = 0.3
	Loader.goto_level(home())

# ------------------------------------------------------------------ saving

func save_game() -> void:
	if not is_instance_valid(player): return
	var p := player
	saved_road = road_village() if road_village() != "" else saved_road
	var d := {
		"v": 2, "quest": quest, "quest2": quest2, "quest3": quest3, "quest4": quest4, "smith": smith_level,
		"ileana": met_ileana, "richis": visited_richis, "vasile": met_vasile, "rozalia": rozalia_thanked,
		"mosna": visited_mosna, "biertan": visited_biertan, "sofia": sofia_gift, "ewe_q": ewe_quest,
		"side": side.keys(), "max_hp": p.max_hp, "dmg": p.dmg, "potions": p.potions, "coins": p.coins,
		"charm_dodge": p.charm_dodge, "red_thread": p.red_thread, "salt": p.salt, "salt_unlocked": p.salt_unlocked,
		"wormwood": p.wormwood, "oak": p.oak_heart, "garlic": p.garlic, "torch": p.torch, "road": saved_road,
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f: f.store_string(JSON.stringify(d))
	save_t = 0.0

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func continue_game() -> void:
	if transitioning: return
	var d = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH)) if has_save() else null
	if not (d is Dictionary):
		start_game()
		return
	player.reset_stats()
	quest = int(d.get("quest", 0)); quest2 = int(d.get("quest2", 0)); quest3 = int(d.get("quest3", 0)); quest4 = int(d.get("quest4", 0))
	smith_level = int(d.get("smith", 0)); ewe_quest = int(d.get("ewe_q", 0))
	met_ileana = d.get("ileana", false); visited_richis = d.get("richis", false); met_vasile = d.get("vasile", false)
	rozalia_thanked = d.get("rozalia", false); visited_mosna = d.get("mosna", false)
	visited_biertan = d.get("biertan", false); sofia_gift = d.get("sofia", false)
	side.clear()
	for k in d.get("side", []): side[k] = true
	var p := player
	p.max_hp = d.get("max_hp", 100.0) if d.get("max_hp", 0.0) > 0.0 else 100.0
	p.hp = p.max_hp
	p.dmg = d.get("dmg", 12.0) if d.get("dmg", 0.0) > 0.0 else 12.0
	p.potions = int(d.get("potions", 1)) if d.get("potions", 0) > 0 else 1
	p.coins = int(d.get("coins", 20)) if d.get("coins", 0) > 0 else 20
	p.charm_dodge = d.get("charm_dodge", false); p.red_thread = d.get("red_thread", false)
	p.salt = int(d.get("salt", 0)); p.salt_unlocked = d.get("salt_unlocked", false)
	p.wormwood = d.get("wormwood", false); p.oak_heart = d.get("oak", false)
	p.garlic = d.get("garlic", false); p.torch = d.get("torch", false)
	saved_road = d.get("road", "") if d.get("road") != null else ""
	dusk = 0.45
	state = State.PLAY
	Loader.goto_level(saved_road if saved_road != "" else home())

func start_game() -> void:
	player.reset_stats()
	quest = 0; quest2 = 0; quest3 = 0; quest4 = 0; ewe_quest = 0; smith_level = 0
	met_ileana = false; met_vasile = false; rozalia_thanked = false; sofia_gift = false
	visited_richis = false; visited_mosna = false; visited_biertan = false
	side.clear()
	saved_road = ""
	dusk = 0.3
	state = State.PLAY
	Loader.goto_level("stana")   # a prologue on the high pasture, then the road starts in Sighișoara
