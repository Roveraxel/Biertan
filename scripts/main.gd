extends Node2D
## Game controller: title, levels, dialogue, quest state.

var state := "title"  # title, play, dialogue, dead
var level: Level
var current := ""
var player: Player
var cam: Camera2D
var mod: CanvasModulate
var hud: Hud
var touch: TouchUI
var touch_test := false
var ui: CanvasLayer
var fade: ColorRect
var boss: Node = null
var hover: Node = null
var transitioning := false
var t := 0.0
var quest := 0  # 0 none, 1 accepted, 2 boss slain, 3 complete
var smith_level := 0
var met_ileana := false
var quest2 := 0  # 0 none, 1 accepted, 2 Muma slain, 3 complete
var visited_richis := false
var met_vasile := false
var rozalia_thanked := false
var quest3 := 0  # 0 none, 1 accepted, 2 Balaur slain, 3 complete
var visited_mosna := false
const SAVE_PATH := "user://biertan_save.json"
var dlg_speaker := ""
var dlg_lines: Array = []
var dlg_idx := 0
var dlg_after: Callable = Callable()
var test_mode := false
var shots_dir := ""


func _ready() -> void:
	setup_input()
	G.audio = Audio.new()
	add_child(G.audio)
	ui = CanvasLayer.new()
	ui.layer = 10
	add_child(ui)
	hud = Hud.new()
	hud.main = self
	ui.add_child(hud)
	G.touch_mode = OS.has_feature("web_android") or OS.has_feature("web_ios")
	touch = TouchUI.new()
	touch.main = self
	ui.add_child(touch)
	var fl := CanvasLayer.new()
	fl.layer = 20
	add_child(fl)
	fade = ColorRect.new()
	fade.color = Color(0, 0, 0, 1)
	fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fl.add_child(fade)
	mod = CanvasModulate.new()
	add_child(mod)
	player = Player.new()
	player.main = self
	player.died.connect(on_player_died)
	cam = Camera2D.new()
	cam.zoom = Vector2(1.3, 1.3)
	cam.position_smoothing_enabled = true
	cam.position_smoothing_speed = 7.0
	player.add_child(cam)
	for a in OS.get_cmdline_user_args():
		if a == "--touchtest":
			test_mode = true
			touch_test = true
			G.touch_mode = true
		elif a == "--autotest":
			test_mode = true
		elif a.begins_with("--shots="):
			shots_dir = a.substr(8)
	G.audio.set_music("music_hub", -9.0)
	fade.color.a = 1.0
	var tw := create_tween()
	tw.tween_property(fade, "color:a", 0.0, 0.8)
	if test_mode:
		if touch_test:
			run_touch_test()
		else:
			run_test()


func setup_input() -> void:
	var map := {
		"move_up": [KEY_W, KEY_UP], "move_down": [KEY_S, KEY_DOWN],
		"move_left": [KEY_A, KEY_LEFT], "move_right": [KEY_D, KEY_RIGHT],
		"dodge": [KEY_SPACE, KEY_SHIFT], "interact": [KEY_E, KEY_ENTER],
		"potion": [KEY_Q], "attack": [KEY_J], "salt": [KEY_R],
	}
	for a in map:
		if not InputMap.has_action(a):
			InputMap.add_action(a)
		for k in map[a]:
			var e := InputEventKey.new()
			e.physical_keycode = k
			InputMap.action_add_event(a, e)
	var m := InputEventMouseButton.new()
	m.button_index = MOUSE_BUTTON_LEFT
	InputMap.action_add_event("attack", m)


# ---------------------------------------------------------------- flow

func start_game() -> void:
	if transitioning:
		return
	player.reset_stats()
	quest = 0
	smith_level = 0
	met_ileana = false
	quest2 = 0
	visited_richis = false
	met_vasile = false
	rozalia_thanked = false
	quest3 = 0
	visited_mosna = false
	G.dusk = 0.3
	state = "play"
	await goto("hub")
	banner("BIERTAN", "The bells have fallen silent. Reach Biertan.")


func goto(name: String, at := Vector2(-1, -1)) -> void:
	if transitioning:
		return
	transitioning = true
	var was_play := state == "play"
	await fade_to(1.0, 0.35)
	if level != null:
		if player.get_parent() != null:
			player.get_parent().remove_child(player)
		level.queue_free()
		level = null
	boss = null
	match name:
		"hub":
			level = HubLevel.new()
		"forest":
			level = ForestLevel.new()
		"arena":
			level = ArenaLevel.new()
		"richis":
			level = RichisLevel.new()
		"hills":
			level = HillsLevel.new()
		"caves":
			level = CavesLevel.new()
		"hollow":
			level = HollowLevel.new()
		"mosna":
			level = MosnaLevel.new()
		"vineyard":
			level = VineyardLevel.new()
		"gorge":
			level = GorgeLevel.new()
	current = name
	level.main = self
	add_child(level)
	level.build()
	level.add_child(player)
	player.global_position = at if at.x >= 0.0 else level.spawn
	player.velocity = Vector2.ZERO
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = int(level.size.x)
	cam.limit_bottom = int(level.size.y)
	cam.zoom = Vector2(0.95, 0.95) if name == "gorge" else Vector2(1.3, 1.3)
	cam.offset = Vector2(0, -150) if name == "gorge" else Vector2.ZERO
	cam.reset_smoothing()
	if name == "hub":
		G.audio.set_music("music_hub", -9.0)
		G.audio.set_ambient("amb_fire", -16.0)
	elif name == "forest":
		G.audio.set_music("music_forest", -9.0)
		G.audio.set_ambient("amb_wind", -10.0)
	elif name == "arena":
		G.audio.set_music("music_boss", -8.0)
		G.audio.set_ambient("amb_wind", -14.0)
	elif name == "richis":
		G.audio.set_music("music_hub", -9.0)
		G.audio.set_ambient("amb_fire", -16.0)
	elif name == "hills":
		G.audio.set_music("music_hills", -9.0)
		G.audio.set_ambient("amb_wind", -12.0)
	elif name == "caves":
		G.audio.set_music("music_cave", -8.0)
		G.audio.set_ambient("amb_cave", -8.0)
	elif name == "hollow":
		G.audio.set_music("music_muma", -8.0)
		G.audio.set_ambient("amb_wind", -16.0)
	elif name == "mosna":
		G.audio.set_music("music_hub", -10.0)
		G.audio.set_ambient("amb_fire", -16.0)
	elif name == "vineyard":
		G.audio.set_music("music_vineyard", -9.0)
		G.audio.set_ambient("amb_wind", -11.0)
	elif name == "gorge":
		G.audio.set_music("music_balaur", -8.0)
		G.audio.set_ambient("amb_cave", -12.0)
	if name == "richis":
		visited_richis = true
	if name == "mosna":
		visited_mosna = true
	if name == "hub" or name == "richis" or name == "mosna":
		G.dusk = 0.45
		save_game.call_deferred()
	elif name == "hills" and G.dusk < 0.2:
		G.dusk = 0.2
	elif name == "vineyard" and G.dusk < 0.45:
		G.dusk = 0.45
	elif name == "forest" and G.dusk < 0.15:
		G.dusk = 0.15
	if was_play or state == "play":
		state = "play"
	await fade_to(0.0, 0.35)
	transitioning = false
	banner(level.title, level.subtitle)


func fade_to(a: float, d: float) -> void:
	var tw := create_tween()
	tw.tween_property(fade, "color:a", a, d)
	await tw.finished


func try_leave_hub() -> void:
	if state != "play" or transitioning:
		return
	if quest == 0:
		toast("Speak with Frau Anna before you leave.")
		player.velocity = Vector2(-300, 0)
	elif quest >= 3:
		goto("richis", Vector2(300, 600))
	else:
		goto("forest")


func leave_forest_west() -> void:
	if state == "play" and not transitioning:
		goto("hub", Vector2(1540, 600))


func leave_richis_west() -> void:
	if state == "play" and not transitioning:
		goto("hub", Vector2(1540, 600))


func leave_richis_east() -> void:
	if state != "play" or transitioning:
		return
	if quest2 == 0:
		toast("Speak with the pastor before you leave.")
		player.velocity = Vector2(-300, 0)
	elif quest2 >= 3:
		goto("mosna", Vector2(300, 620))
	else:
		goto("hills")


func leave_mosna_west() -> void:
	if state == "play" and not transitioning:
		goto("richis", Vector2(1540, 600))


func leave_mosna_east() -> void:
	if state != "play" or transitioning:
		return
	if quest3 == 0:
		toast("Speak with Meister Konrad before you leave.")
		player.velocity = Vector2(-300, 0)
	elif quest3 >= 3:
		toast("Biertan lies ahead. (The final level is in development)")
		player.velocity = Vector2(-300, 0)
	else:
		goto("vineyard")


func leave_vineyard_west() -> void:
	if state == "play" and not transitioning:
		goto("mosna", Vector2(1640, 620))


func enter_gorge() -> void:
	if state == "play" and not transitioning:
		if quest3 >= 2:
			toast("The quarry is quiet now. The road to Biertan is open.")
			player.velocity = Vector2(-300, 0)
		else:
			goto("gorge")


func leave_hills_west() -> void:
	if state == "play" and not transitioning:
		goto("richis", Vector2(1540, 600))


func enter_caves() -> void:
	if state == "play" and not transitioning:
		goto("caves")


func leave_caves_west() -> void:
	if state == "play" and not transitioning:
		goto("hills", Vector2(2880, 810))


func enter_hollow() -> void:
	if state == "play" and not transitioning:
		goto("hollow")


func home() -> String:
	if visited_mosna:
		return "mosna"
	return "richis" if visited_richis else "hub"


func home_name() -> String:
	return {"mosna": "Moșna", "richis": "Richiș", "hub": "Saschiz"}[home()]


func enter_arena() -> void:
	if state == "play" and not transitioning:
		goto("arena")


func on_player_died() -> void:
	state = "dead"
	player.frozen = true
	G.sfx("boss_roar", -10.0, 1.5)


func respawn() -> void:
	player.hp = player.max_hp
	player.frozen = false
	state = "play"
	G.dusk = 0.3
	goto(home())


func on_boss_dead() -> void:
	banner("THE VARCOLAC FALLS", "The sun and moon are returned to the sky.")
	await get_tree().create_timer(3.0).timeout
	player.charm_dodge = true
	quest = 2
	toast("Received: Wolf-Fang Charm  (+10% dodge)")
	toast("Received: The Silver Thread  (quest item)")
	await get_tree().create_timer(2.5).timeout
	goto("hub", Vector2(900, 880))


func on_muma_dead() -> void:
	banner("MUMA PĂDURII IS FELLED", "The wood grows quiet. Far off, children wake.")
	await get_tree().create_timer(3.0).timeout
	player.oak_heart = true
	player.max_hp += 15.0
	player.hp = player.max_hp
	quest2 = 2
	toast("Received: Heart of Oak  (+15 max health)")
	toast("Found in her hollow: the clapper of a great bell")
	await get_tree().create_timer(2.5).timeout
	goto("richis", Vector2(900, 760))


func on_balaur_dead() -> void:
	banner("THE BALAUR IS SLAIN", "Three necks seared. The road to Biertan lies open.")
	await get_tree().create_timer(3.0).timeout
	quest3 = 2
	player.dmg += 4.0
	player.coins += 40
	toast("Received: Balaur Scale  (+4 damage)")
	toast("+40 coins from the serpent's hoard")
	await get_tree().create_timer(2.5).timeout
	goto("mosna", Vector2(950, 860))


# ---------------------------------------------------------------- save

func save_game() -> void:
	var p := player
	var d := {
		"v": 1, "quest": quest, "quest2": quest2, "smith": smith_level, "ileana": met_ileana,
		"richis": visited_richis, "vasile": met_vasile, "rozalia": rozalia_thanked, "quest3": quest3, "mosna": visited_mosna,
		"garlic": p.garlic, "torch": p.torch,
		"max_hp": p.max_hp, "dmg": p.dmg, "potions": p.potions, "coins": p.coins,
		"charm_dodge": p.charm_dodge, "red_thread": p.red_thread, "salt": p.salt,
		"salt_unlocked": p.salt_unlocked, "wormwood": p.wormwood, "oak": p.oak_heart,
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(d))


static func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func continue_game() -> void:
	if transitioning:
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		start_game()
		return
	var d = JSON.parse_string(f.get_as_text())
	if typeof(d) != TYPE_DICTIONARY:
		start_game()
		return
	player.reset_stats()
	quest = int(d.get("quest", 0))
	quest2 = int(d.get("quest2", 0))
	smith_level = int(d.get("smith", 0))
	met_ileana = bool(d.get("ileana", false))
	visited_richis = bool(d.get("richis", false))
	met_vasile = bool(d.get("vasile", false))
	rozalia_thanked = bool(d.get("rozalia", false))
	quest3 = int(d.get("quest3", 0))
	visited_mosna = bool(d.get("mosna", false))
	var p := player
	p.max_hp = float(d.get("max_hp", 100.0))
	p.hp = p.max_hp
	p.dmg = float(d.get("dmg", 12.0))
	p.potions = int(d.get("potions", 1))
	p.coins = int(d.get("coins", 20))
	p.charm_dodge = bool(d.get("charm_dodge", false))
	p.red_thread = bool(d.get("red_thread", false))
	p.salt = int(d.get("salt", 0))
	p.salt_unlocked = bool(d.get("salt_unlocked", false))
	p.wormwood = bool(d.get("wormwood", false))
	p.oak_heart = bool(d.get("oak", false))
	p.garlic = bool(d.get("garlic", false))
	p.torch = bool(d.get("torch", false))
	G.dusk = 0.45
	state = "play"
	await goto(home())


# ---------------------------------------------------------------- frame

func _process(delta: float) -> void:
	t += delta
	if level != null and state != "title":
		mod.color = mod.color.lerp(level.ambient(), clampf(delta * 2.5, 0.0, 1.0))
	else:
		mod.color = Color.WHITE
	if state == "play":
		if current == "forest" or current == "hills" or current == "vineyard":
			G.dusk = minf(1.0, G.dusk + delta / 240.0)
		elif current == "hub" or current == "richis" or current == "mosna":
			G.dusk = move_toward(G.dusk, 0.45, delta * 0.4)
	player.frozen = (state == "dialogue" or state == "dead")


func _physics_process(_delta: float) -> void:
	hover = null
	if state == "play" and level != null and player.is_inside_tree():
		var best := 80.0
		for n in get_tree().get_nodes_in_group("interactable"):
			if n.can_interact():
				var d: float = n.global_position.distance_to(player.global_position)
				if d < best:
					best = d
					hover = n


func _input(event: InputEvent) -> void:
	if (event is InputEventMouseMotion or event is InputEventMouseButton) and not touch_test:
		G.touch_mode = false


func _unhandled_input(event: InputEvent) -> void:
	if state == "title":
		hud.title_input(event)
		return
	var tap: bool = event is InputEventScreenTouch and event.pressed
	var pressed: bool = tap or event.is_action_pressed("interact") or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT)
	if not pressed:
		return
	if state == "dialogue":
		advance_dialogue()
	elif state == "dead":
		if tap or event.is_action_pressed("interact"):
			respawn()
	elif state == "play" and event.is_action_pressed("interact") and hover != null:
		hover.interact()


# ---------------------------------------------------------------- UI helpers

func toast(s: String) -> void:
	hud.toasts.append([s, 5.0])
	if hud.toasts.size() > 4:
		hud.toasts.pop_front()


func banner(s: String, sub := "") -> void:
	hud.banner_text = s
	hud.banner_sub = sub
	hud.banner_t = 3.6


func voice(s: String) -> void:
	hud.toasts.append([s, 7.0])


func marker_for(id: String) -> bool:
	return (id == "anna" and (quest == 0 or quest == 2)) or (id == "ileana" and not met_ileana) \
		or (id == "pastor" and (quest2 == 0 or quest2 == 2)) or (id == "vasile" and not met_vasile and quest2 >= 1) \
		or (id == "konrad" and (quest3 == 0 or quest3 == 2))


# ---------------------------------------------------------------- dialogue

func start_dialogue(who: String, lines: Array, after := Callable()) -> void:
	dlg_speaker = who
	dlg_lines = lines
	dlg_idx = 0
	dlg_after = after
	state = "dialogue"
	G.sfx("blip", -6.0)


func advance_dialogue() -> void:
	dlg_idx += 1
	G.sfx("blip", -8.0, 0.9)
	if dlg_idx >= dlg_lines.size():
		state = "play"
		var a := dlg_after
		dlg_after = Callable()
		if a.is_valid():
			a.call()


func prop_used(p: Prop) -> void:
	match p.kind:
		"npc":
			talk(p.id)
		"sack":
			p.used = true
			player.coins += 15
			G.sfx("coin", -4.0)
			toast("A shepherd's coin sack.  +15 coins")
		"fleece":
			start_dialogue("Torn fleece", ["The wool is shredded. Three nights of throats opened, and not a drop of blood on the grass.", "Wolf prints circle the hut, but they stop where the moonlight ends. Something walks beside them."])
		"crystal":
			p.regrow = 20.0
			player.salt += 2
			player.salt_unlocked = true
			G.sfx("crystal", -4.0, randf_range(0.9, 1.1))
			G.fx_ring(p.get_parent(), p.global_position, Color(0.9, 0.95, 1.0, 0.8), 50)
			toast("You chip off raw salt.  +2 salt  (R to throw)")
		"cross":
			p.used = true
			player.hp = player.max_hp
			G.sfx("potion", -4.0, 0.8)
			G.fx_ring(p.get_parent(), player.global_position, Color(1.0, 0.85, 0.5, 0.8), 60)
			start_dialogue("Wayside cross", ["A troiță of carved oak, painted with suns and a little roof against the rain. Someone has left bread at its foot.", "You stand a moment. The wind drops. Your wounds close."])
		"greenman":
			start_dialogue("The Green Man", ["A stone face wreathed in oak leaves, carved by Saxon masons three hundred years ago.", "Some say it guards the church from the wood. Some say the wood is watching through it."])
		"bones":
			p.used = true
			player.coins += 25
			player.potions += 1
			G.sfx("coin", -4.0)
			toast("A miner's purse and a stoppered flask.  +25 coins, +1 tincture")
		"sign":
			if p.id == "cave_sign":
				start_dialogue("Miners' post", ["THE SALT CAVES. Imperial salt workings, closed by order.", "Below, someone has carved: 'Thirty men went down. Thirty came up. Count them again.'"])
				return
			if p.id == "yard_sign":
				start_dialogue("Churchyard gate", ["'HIER RUHEN DIE TOTEN VON MESCHEN.' Here rest the dead of Moșna.", "Someone has scratched beneath it in Romanian: 'Not all of them.' The earth of every second grave is turned."])
				return
			if p.id == "quarry_sign":
				start_dialogue("Waymark", ["BIRTHÄLM, 2 hours. The Biertan road runs past the old quarry.", "Fresh claw marks run down the stone, wider than a cart."])
				return
			if p.id == "lake_sign":
				start_dialogue("Scratched into the salt", ["'She sings from the far side of the lake. The children follow the singing. Do not follow the singing.'"])
				return
			start_dialogue("Carved post", ["Beyond this post, the Moon Clearing. Old shepherds say the Varcolac sleeps there between eclipses.", "Light the braziers if the sky goes dark. Beasts that swallow the moon fear a hearth."])


func talk(id: String) -> void:
	match id:
		"konrad":
			if quest3 == 0:
				start_dialogue("Meister Konrad", [
					"Let me see that. A bell clapper... my father's mark is on it. He cast it for the great bell of Biertan.",
					"No cart has come from Biertan in a month. The road runs past the old quarry, and something has coiled itself in the flooded pit. Three heads, the carters say. A balaur.",
					"Old Saxon law: you do not cut a balaur's head, you cut and burn it. Cut only, and it grows back by evening.",
					"Take this torch from my furnace. It does not go out. Sear every neck you cut.",
				], func():
					quest3 = 1
					player.torch = true
					player.potions += 1
					banner("QUEST: THE ROAD TO BIERTAN", "Slay the Balaur in the drowned quarry.")
					toast("Received: Founder's Torch  (sears stumps)"))
			elif quest3 == 1:
				start_dialogue("Meister Konrad", ["Cut, then burn. Do not forget it.", "If your blade is dull, I can whet it. Twenty-five coins."], sharpen)
			elif quest3 == 2:
				start_dialogue("Meister Konrad", [
					"You hear that? The carters are already hitching their horses.",
					"Biertan lies two hours down the road. Whatever silenced its bells is waiting for you there.",
					"I will fit the clapper to a hanger. When you reach the great bell, ring it. The dead of Biertan should hear it.",
				], func():
					quest3 = 3
					player.coins += 50
					player.hp = player.max_hp
					G.sfx("bell", -2.0)
					banner("LEVEL 3 COMPLETE", "+50 coins.  The road to Biertan is open.")
					save_game())
			else:
				start_dialogue("Meister Konrad", ["Ring the great bell of Biertan, Wanderer. Twenty-five coins for a whetting, if you want it."], sharpen)
		"hannes":
			start_dialogue("Hannes", ["Every family of Moșna keeps its ham in the tower, and on Sundays we cut a slice. That is how a village survives a siege.", "Smoked ham and plum brandy, ten coins. Heals like a tincture, tastes better."], buy_potion)
		"veta":
			if not player.garlic:
				start_dialogue("Veta", ["My husband sang in the church for forty years. They buried him in the yard below the vineyards, and last week he came to the window.", "A strigoi drinks what it bites. Wear garlic and its teeth slide off. Forty coins for the wreath."], buy_garlic)
			else:
				start_dialogue("Veta", ["If you see a cantor with a grey beard among them... lay him down gently."])
		"pastor":
			if quest2 == 0:
				start_dialogue("Pfarrer Lukas", [
					"You carry the fang of a varcolac. Then God has sent you, or something older has.",
					"Seven nights ago our children began to walk out of their beds, singing. Three are gone: little Ioan, Mitzi and Grete.",
					"The Iele dance in the Hollow Hills and lead the young away. The women say the singing ends at the Salt Caves, and past them lies the Hollow, where Muma Pădurii keeps her house.",
					"The Forest Mother takes children to keep the wood young. Bring them home. Vasile knows the caves, and salt is what the old dead cannot cross.",
				], func():
					quest2 = 1
					player.potions += 1
					banner("QUEST: THE SINGING CHILDREN", "Find the children beyond the Salt Caves.")
					toast("The pastor gives you a garlic tincture."))
			elif quest2 == 1:
				start_dialogue("Pfarrer Lukas", ["The east gate leads to the Hollow Hills. Whatever you hear out there, do not dance."])
			elif quest2 == 2:
				start_dialogue("Pfarrer Lukas", [
					"They walked in at dawn, all three, with moss in their hair and no memory of the night. The bells rang for them.",
					"And this... a bell clapper, cast in Biertan. Muma Pădurii was keeping it in her hollow.",
					"Someone silenced the bells of Biertan on purpose, and paid the old powers to keep them quiet. Go on to Moșna. Take the clapper home.",
				], func():
					quest2 = 3
					player.coins += 60
					player.hp = player.max_hp
					banner("LEVEL 2 COMPLETE", "+60 coins.  Moșna awaits.")
					save_game())
			else:
				start_dialogue("Pfarrer Lukas", ["Moșna is the next fortress on the road to Biertan. The clapper must go home."])
		"vasile":
			if not met_vasile:
				start_dialogue("Vasile", [
					"Going down into the salt? Then you will want this pouch.",
					"Throw salt at your feet and it makes a circle the dead cannot cross. Anything unclean inside it burns. Iele hate it too.",
					"Thirty years I cut salt down there. Miners buried in salt do not rot, and some of them got up again. Moroi, the old women call them.",
				], func():
					met_vasile = true
					player.salt_unlocked = true
					player.salt += 4
					toast("Salt pouch.  +4 salt  (%s to throw)" % ("SALT" if G.touch_mode else "R")))
			else:
				start_dialogue("Vasile", ["The caves are full of salt-stone. Chip a piece where it glows.", "Or three pinches for ten coins, if you'd rather not bend."], buy_salt)
		"katharina":
			if not player.wormwood:
				start_dialogue("Katharina", ["Wormwood and garlic, my dear. The Iele cannot bear the smell of pelin.", "Wear a sprig and their song will not hold your legs. Forty coins."], buy_wormwood)
			else:
				start_dialogue("Katharina", ["Garlic tincture, ten coins. The road east is long."], buy_potion)
		"rozalia":
			if quest2 < 2:
				start_dialogue("Rozalia", ["My Ioan walked out singing. His eyes were open but he did not see me.", "Please. Bring him home."])
			elif not rozalia_thanked:
				start_dialogue("Rozalia", ["He is home. He remembers only a green woman and honey cake.", "Take these. I made them for him, but he has his mother now."], func():
					rozalia_thanked = true
					player.potions += 2
					toast("Rozalia gives you two tinctures."))
			else:
				start_dialogue("Rozalia", ["God keep you on the road, Wanderer."])
		"anna":
			if quest == 0:
				start_dialogue("Frau Anna Roth", [
					"Three nights now the sheep come back with their throats open and not a drop of blood spilled.",
					"The elders say a varcolac walks the Wolf Forest. Bring me proof, and the inn is yours for a month.",
					"Hans can sharpen your blade. Old Ileana at the gate knows charms. Then take the east gate, and keep to the path.",
				], func():
					quest = 1
					player.potions += 1
					banner("QUEST: WHERE THE SHEEP WENT", "Slay the beast of the Wolf Forest.")
					toast("Anna gives you a garlic tincture.  (Q to drink)"))
			elif quest == 1:
				start_dialogue("Frau Anna Roth", ["Garlic tincture, ten coins. Drink it when you bleed.", "The east gate leads to the forest. Come back with the beast's proof."], buy_potion)
			elif quest == 2:
				start_dialogue("Frau Anna Roth", [
					"The Silver Thread... and the fang of a varcolac. By the saints, you did it.",
					"From this night you are Guest of the Hearth. The inn is yours, Wanderer.",
				], func():
					quest = 3
					player.coins += 50
					banner("GUEST OF THE HEARTH", "+50 coins.  Level 2: Richiș awaits.")
					player.hp = player.max_hp)
			else:
				start_dialogue("Frau Anna Roth", ["Richiș lies east through the gate, along the old salt road. The pastor there will want to hear what you carry.", "Garlic tincture, ten coins?"], buy_potion)
		"hans":
			if smith_level >= 3:
				start_dialogue("Master Hans", ["I can do no more for that blade. It is as keen as Saxon steel gets."])
			else:
				start_dialogue("Master Hans", ["A sharper edge keeps you breathing. Twenty-five coins for a whetting.", "Iron is what the dead fear. Fire is what the beasts fear."], sharpen)
		"ileana":
			if quest >= 2:
				start_dialogue("Old Ileana", ["A varcolac does not wander this far west by chance, child.", "Something drives the old beasts toward us. The bells of Biertan have stopped. When bells stop, the dead listen."])
			elif not met_ileana:
				start_dialogue("Old Ileana", [
					"Salt on the threshold, iron in the hand, a red thread at the wrist. The dead keep rules; learn them.",
					"Hold out your arm. There. May it keep your blood where it belongs.",
				], func():
					met_ileana = true
					player.red_thread = true
					player.max_hp += 10
					player.hp = player.max_hp
					toast("Red thread charm.  (+10 max health)"))
			else:
				start_dialogue("Old Ileana", ["A voice that knows your name is never a friend's, child. Do not answer it.", "Light is your armour in the dark. The dusk makes them bold."])
		"gheorghe":
			if quest >= 2:
				start_dialogue("Gheorghe", ["They say the beast is slain? Then my ewes can rest in peace. Thank you, stranger."])
			else:
				start_dialogue("Gheorghe", ["Forty ewes, gone in one night. I heard something howling at the sky.", "The moon was swallowed whole. I swear it on my mother's grave."])


func buy_potion() -> void:
	if player.coins >= 10:
		player.coins -= 10
		player.potions += 1
		toast("Garlic tincture bought.  -10 coins")
	else:
		toast("You need ten coins.")


func buy_salt() -> void:
	if player.coins >= 10:
		player.coins -= 10
		player.salt += 3
		toast("Three pinches of salt.  -10 coins")
	else:
		toast("You need ten coins.")


func buy_garlic() -> void:
	if player.coins >= 40:
		player.coins -= 40
		player.garlic = true
		toast("Garlic wreath.  Strigoi bite half as hard and cannot drink.")
	else:
		toast("You need forty coins.")


func buy_wormwood() -> void:
	if player.coins >= 40:
		player.coins -= 40
		player.wormwood = true
		toast("Wormwood sprig.  The Iele's song no longer slows you.")
	else:
		toast("You need forty coins.")


func sharpen() -> void:
	if player.coins >= 25:
		player.coins -= 25
		smith_level += 1
		player.dmg += 4.0
		toast("Blade whetted.  (+4 damage)")
	else:
		toast("You need twenty-five coins.")


# ---------------------------------------------------------------- automated test

func run_test() -> void:
	var fails: Array = []
	var chk := func(cond: bool, msg: String) -> void:
		print(("  ok   " if cond else "  FAIL ") + msg)
		if not cond:
			fails.append(msg)
	await get_tree().create_timer(1.0).timeout
	await snap("00_title")
	start_game()
	await get_tree().create_timer(1.5).timeout
	chk.call(current == "hub" and level != null, "hub loaded")
	await snap("01_hub")
	player.god = true
	talk("anna")
	while state == "dialogue":
		advance_dialogue()
	chk.call(quest == 1, "quest accepted from Anna")
	talk("ileana")
	while state == "dialogue":
		advance_dialogue()
	chk.call(player.red_thread and player.max_hp == 110.0, "Ileana red thread charm")
	await goto("forest")
	await get_tree().create_timer(0.8).timeout
	chk.call(current == "forest", "forest loaded")
	var total := get_tree().get_nodes_in_group("enemies").size()
	chk.call(total >= 14, "forest has enemies (%d)" % total)
	chk.call((level as ForestLevel).spawn_lurker(), "red-eyed lurker spawns in the forest")
	await get_tree().create_timer(1.2).timeout
	chk.call(get_tree().get_nodes_in_group("lurkers").size() >= 1, "lurker is watching")
	await snap("02_forest_start")
	var killed := 0
	for i in 400:
		var es := get_tree().get_nodes_in_group("enemies")
		if es.is_empty():
			break
		var e: Node2D = es[0]
		player.global_position = e.global_position + Vector2(-50, 0)
		player.facing = Vector2.RIGHT
		player.attack_cd = 0.0
		if e is Enemy and e.state == "dormant":
			e.state = "chase"
		player.swing()
		if i == 6:
			await snap("03_forest_combat")
		await get_tree().physics_frame
		await get_tree().physics_frame
		player.hp = player.max_hp
	chk.call(get_tree().get_nodes_in_group("enemies").is_empty(), "all forest enemies killable")
	chk.call(player.coins > 20, "coins dropped (%d)" % player.coins)
	G.dusk = 0.95
	await get_tree().create_timer(0.5).timeout
	await snap("04_forest_dusk")
	await goto("arena")
	await get_tree().create_timer(0.6).timeout
	chk.call(boss != null and is_instance_valid(boss), "boss spawned")
	player.global_position = Vector2(700, 660)
	cam.reset_smoothing()
	await get_tree().create_timer(0.4).timeout
	await snap("05_arena_intro")
	await get_tree().create_timer(3.0).timeout
	var b: Boss = boss
	b.phase_changed.connect(func(p): print("  phase -> ", p))
	b.global_position = Vector2(700, 600)
	player.global_position = Vector2(700, 800)
	b.hurt(20.0, Vector2.UP)
	chk.call(b.hp == 340.0, "boss takes damage in phase 1")
	b.hp = 235.0
	b.hurt(1.0, Vector2.UP)
	chk.call(b.phase == 2, "phase 2 reached")
	await get_tree().create_timer(1.5).timeout
	await snap("06_arena_phase2")
	var before := b.hp
	b.hurt(10.0, Vector2.UP)
	chk.call(b.hp == before, "boss shielded by darkness in phase 2")
	var br: Brazier = get_tree().get_nodes_in_group("braziers")[0]
	br.interact()
	b.global_position = br.global_position + Vector2(40, 0)
	b.hurt(10.0, Vector2.UP)
	chk.call(b.hp == before - 10.0, "boss vulnerable near lit brazier")
	b.hp = 100.0
	b.hurt(1.0, Vector2.UP)
	chk.call(b.phase == 3, "phase 3 reached")
	await get_tree().create_timer(1.0).timeout
	await snap("07_arena_phase3")
	b.hp = 5.0
	b.hurt(20.0, Vector2.UP)
	await get_tree().create_timer(0.3).timeout
	chk.call(boss == null or not is_instance_valid(boss), "boss slain")
	await get_tree().create_timer(8.5).timeout
	chk.call(quest == 2 and player.charm_dodge, "charm awarded, quest 2")
	chk.call(current == "hub", "returned to Saschiz")
	talk("anna")
	while state == "dialogue":
		advance_dialogue()
	chk.call(quest == 3, "quest completed with Anna")
	await snap("08_hub_end")
	# ------------------------------------------------ Level 2
	try_leave_hub()
	await get_tree().create_timer(1.2).timeout
	chk.call(current == "richis", "travelled to Richiș")
	await snap("09_richis")
	leave_richis_east()
	await get_tree().create_timer(0.3).timeout
	chk.call(current == "richis", "east gate waits for the pastor")
	talk("pastor")
	while state == "dialogue":
		advance_dialogue()
	chk.call(quest2 == 1, "pastor's quest accepted")
	talk("vasile")
	while state == "dialogue":
		advance_dialogue()
	chk.call(player.salt_unlocked and player.salt == 4, "Vasile's salt pouch")
	player.coins = 100
	talk("katharina")
	while state == "dialogue":
		advance_dialogue()
	chk.call(player.wormwood and player.coins == 60, "wormwood bought")
	player.wormwood = false
	leave_richis_east()
	await get_tree().create_timer(1.2).timeout
	chk.call(current == "hills", "Hollow Hills loaded")
	var ie := 0
	for e in get_tree().get_nodes_in_group("enemies"):
		if e.kind == "iele":
			ie += 1
	chk.call(ie >= 10, "Iele dance in the rings (%d)" % ie)
	player.global_position = Vector2(900, 700)
	cam.reset_smoothing()
	await get_tree().create_timer(1.2).timeout
	chk.call(player.slow_t > 0.0, "Iele song slows the hunter")
	await snap("10_hills_iele")
	player.salt_cd = 0.0
	player.throw_salt()
	chk.call(player.salt == 3 and get_tree().get_nodes_in_group("salt_rings").size() == 1, "salt ring thrown")
	var iel: Enemy = null
	for e in get_tree().get_nodes_in_group("enemies"):
		if e.kind == "iele":
			iel = e
			break
	iel.global_position = player.global_position + Vector2(40, 0)
	var ih := iel.hp
	await get_tree().create_timer(0.3).timeout
	chk.call(not is_instance_valid(iel) or iel.hp < ih, "salt burns the Iele")
	await snap("11_hills_salt")
	await clear_enemies()
	chk.call(get_tree().get_nodes_in_group("enemies").is_empty(), "all hills enemies killable")
	enter_caves()
	await get_tree().create_timer(1.2).timeout
	chk.call(current == "caves", "Salt Caves loaded")
	var mo := 0
	for e in get_tree().get_nodes_in_group("enemies"):
		if e.kind == "moroi":
			mo += 1
	chk.call(mo >= 8, "moroi lie in the salt (%d)" % mo)
	var cry: Prop = null
	for n in get_tree().get_nodes_in_group("interactable"):
		if n.kind == "crystal":
			cry = n
			break
	var s0 := player.salt
	prop_used(cry)
	chk.call(player.salt == s0 + 2 and not cry.can_interact(), "salt crystal chipped")
	player.global_position = Vector2(700, 760)
	cam.reset_smoothing()
	await get_tree().create_timer(1.2).timeout
	await snap("12_caves")
	var risen := false
	for e in get_tree().get_nodes_in_group("enemies"):
		if e.kind == "moroi" and e.state != "dormant":
			risen = true
	chk.call(risen, "moroi rise when approached")
	await clear_enemies()
	chk.call(get_tree().get_nodes_in_group("enemies").is_empty(), "all cave enemies killable")
	enter_hollow()
	await get_tree().create_timer(0.8).timeout
	chk.call(current == "hollow" and boss is Muma, "Muma Pădurii spawned")
	await get_tree().create_timer(3.2).timeout
	await snap("13_hollow")
	var m: Muma = boss
	m.hop_t = 99.0
	m.root_t = 99.0
	m.hurt(20.0, Vector2.UP)
	chk.call(m.hp == 400.0, "Muma takes damage in phase 1")
	m.hp = 275.0
	m.hurt(1.0, Vector2.UP)
	chk.call(m.phase == 2, "Muma phase 2")
	m.hop_t = 99.0
	var mb := m.hp
	m.hurt(10.0, Vector2.UP)
	chk.call(m.hp == mb, "bark turns steel in phase 2")
	player.global_position = m.global_position + Vector2(30, 40)
	player.salt = 5
	player.salt_cd = 0.0
	player.throw_salt()
	await get_tree().physics_frame
	await get_tree().physics_frame
	chk.call(m.vulnerable(), "salt burns away her bark")
	m.hurt(10.0, Vector2.UP)
	chk.call(m.hp == mb - 10.0, "Muma vulnerable after salt")
	await snap("14_hollow_salt")
	m.hp = 135.0
	m.hurt(1.0, Vector2.UP)
	chk.call(m.phase == 3, "Muma phase 3")
	m.root_t = 0.0
	await get_tree().create_timer(2.2).timeout
	var roots := 0
	for c in level.get_children():
		if c is RootSpike:
			roots += 1
	chk.call(roots > 0, "roots erupt (%d)" % roots)
	await snap("15_hollow_roots")
	m.hp = 5.0
	m.vuln_t = 5.0
	m.bstate = "walk"
	m.hurt(20.0, Vector2.UP)
	await get_tree().create_timer(0.3).timeout
	chk.call(boss == null or not is_instance_valid(boss), "Muma Pădurii slain")
	await get_tree().create_timer(8.5).timeout
	chk.call(quest2 == 2 and current == "richis" and player.oak_heart, "returned to Richiș with Heart of Oak")
	talk("pastor")
	while state == "dialogue":
		advance_dialogue()
	chk.call(quest2 == 3, "Level 2 completed with the pastor")
	await snap("16_richis_end")
	chk.call(has_save(), "game saved")
	var c_saved := player.coins
	player.coins = 0
	quest2 = 0
	await continue_game()
	await get_tree().create_timer(0.8).timeout
	chk.call(player.coins == c_saved and quest2 == 3 and current == "richis", "Continue restores the save")
	# ------------------------------------------------ Level 3
	player.god = true
	leave_richis_east()
	await get_tree().create_timer(1.2).timeout
	chk.call(current == "mosna", "travelled to Moșna")
	await snap("17_mosna")
	leave_mosna_east()
	await get_tree().create_timer(0.3).timeout
	chk.call(current == "mosna", "east gate waits for Konrad")
	talk("konrad")
	while state == "dialogue":
		advance_dialogue()
	chk.call(quest3 == 1 and player.torch, "Konrad's quest and torch")
	player.coins = 100
	talk("veta")
	while state == "dialogue":
		advance_dialogue()
	chk.call(player.garlic and player.coins == 60, "garlic wreath bought")
	leave_mosna_east()
	await get_tree().create_timer(1.2).timeout
	chk.call(current == "vineyard", "Burnt Vineyards loaded")
	var sg := 0
	var bt_n := 0
	var road: Enemy = null
	for e in get_tree().get_nodes_in_group("enemies"):
		if e.kind == "strigoi":
			sg += 1
			if e.state != "dormant" and road == null:
				road = e
		elif e.kind == "bat":
			bt_n += 1
	chk.call(sg >= 7 and bt_n >= 5, "strigoi (%d) and bats (%d)" % [sg, bt_n])
	player.global_position = road.global_position + Vector2(220, 0)
	cam.reset_smoothing()
	var land := player.global_position
	road.state = "chase"
	road.atk_cd = 0.0
	await get_tree().create_timer(0.75).timeout
	await snap("18_vineyard_leap")
	await get_tree().create_timer(0.6).timeout
	chk.call(road.global_position.distance_to(land) < 90.0, "strigoi leaps onto the hunter")
	road.hp = 20.0
	road.bite(Vector2.RIGHT, 1.0)
	chk.call(road.hp == 20.0, "garlic stops the strigoi drinking")
	G.dusk = 0.9
	player.global_position = Vector2(1820, 1220)
	cam.reset_smoothing()
	await get_tree().create_timer(1.4).timeout
	await snap("19_churchyard_night")
	var woke := 0
	for e in get_tree().get_nodes_in_group("enemies"):
		if e.kind == "strigoi" and e.state != "dormant":
			woke += 1
	chk.call(woke >= 3, "strigoi rise from the churchyard (%d)" % woke)
	G.dusk = 0.4
	await clear_enemies()
	chk.call(get_tree().get_nodes_in_group("enemies").is_empty(), "all vineyard enemies killable")
	enter_gorge()
	await get_tree().create_timer(0.8).timeout
	chk.call(current == "gorge" and boss is Balaur, "the Balaur spawned")
	player.global_position = Vector2(800, 860)
	cam.reset_smoothing()
	await get_tree().create_timer(3.3).timeout
	await snap("20_gorge")
	var bl: Balaur = boss
	var h0: BalaurHead = bl.heads[0]
	h0.hurt(200.0, Vector2.UP)
	chk.call(h0.hstate == "stump" and h0.can_interact(), "head cut to a stump")
	h0.regrow_t = 0.05
	await get_tree().create_timer(0.2).timeout
	chk.call(h0.hstate == "sway" and h0.hp == 78.0, "unseared head grows back")
	h0.hurt(200.0, Vector2.UP)
	h0.interact()
	chk.call(h0.sealed and not h0.can_interact(), "stump seared shut")
	var fh: BalaurHead = bl.heads[1]
	fh.hstate = "sway"
	fh.cd = 0.0
	await get_tree().create_timer(1.1).timeout
	var patches := 0
	for c in level.get_children():
		if c is FirePatch:
			patches += 1
	chk.call(patches > 0, "fire head breathes flame (%d)" % patches)
	await snap("21_gorge_fire")
	for i in [1, 2]:
		var hh: BalaurHead = bl.heads[i]
		hh.hurt(500.0, Vector2.UP)
		hh.interact()
	await get_tree().create_timer(0.3).timeout
	chk.call(boss == null, "the Balaur slain")
	await get_tree().create_timer(6.5).timeout
	chk.call(quest3 == 2 and current == "mosna", "returned to Moșna")
	talk("konrad")
	while state == "dialogue":
		advance_dialogue()
	chk.call(quest3 == 3, "Level 3 completed with Konrad")
	await snap("22_mosna_end")
	quest3 = 0
	await continue_game()
	await get_tree().create_timer(0.8).timeout
	chk.call(quest3 == 3 and current == "mosna" and player.torch and player.garlic, "Continue restores Level 3")
	player.god = false
	player.hurt(9999.0, Vector2.RIGHT)
	chk.call(state == "dead", "death state")
	respawn()
	await get_tree().create_timer(1.5).timeout
	chk.call(state == "play" and player.hp > 0.0, "respawn works")
	print("TEST RESULT: ", "OK" if fails.is_empty() else "FAILED %d" % fails.size())
	get_tree().quit(0 if fails.is_empty() else 1)


func clear_enemies() -> void:
	for i in 600:
		var es := get_tree().get_nodes_in_group("enemies")
		if es.is_empty():
			break
		var e: Node2D = es[0]
		player.global_position = e.global_position + Vector2(-50, 0)
		player.facing = Vector2.RIGHT
		player.attack_cd = 0.0
		if e is Enemy and e.state in ["dormant", "idle", "rise"]:
			e.state = "chase"
		player.swing()
		await get_tree().physics_frame
		await get_tree().physics_frame
		player.hp = player.max_hp


func snap(name: String) -> void:
	if shots_dir == "":
		return
	await get_tree().process_frame
	await get_tree().process_frame
	var img := get_viewport().get_texture().get_image()
	if img != null:
		img.save_png("%s/%s.png" % [shots_dir, name])


func run_touch_test() -> void:
	var fails: Array = []
	var chk := func(cond: bool, msg: String) -> void:
		print(("  ok   " if cond else "  FAIL ") + msg)
		if not cond:
			fails.append(msg)
	await get_tree().create_timer(1.0).timeout
	start_game()
	await get_tree().create_timer(1.5).timeout
	var p0 := player.global_position
	var down := InputEventScreenTouch.new()
	down.index = 0
	down.pressed = true
	down.position = Vector2(200, 560)
	touch._input(down)
	var drag := InputEventScreenDrag.new()
	drag.index = 0
	drag.position = Vector2(290, 560)
	touch._input(drag)
	await get_tree().create_timer(0.6).timeout
	chk.call(player.global_position.x > p0.x + 20.0, "thumbstick moves player right")
	var up := InputEventScreenTouch.new()
	up.index = 0
	up.pressed = false
	up.position = Vector2(290, 560)
	touch._input(up)
	await get_tree().create_timer(0.2).timeout
	var p1 := player.global_position
	await get_tree().create_timer(0.3).timeout
	chk.call(player.global_position.distance_to(p1) < 2.0, "releasing stick stops player")
	var b := InputEventScreenTouch.new()
	b.index = 1
	b.pressed = true
	b.position = Vector2(vp_size().x - 130, vp_size().y - 130)
	touch._input(b)
	await get_tree().create_timer(0.1).timeout
	b.pressed = false
	touch._input(b)
	chk.call(G.touch_mode, "touch mode on")
	print("TOUCH TEST ", "PASS" if fails.is_empty() else "FAIL")
	get_tree().quit(0 if fails.is_empty() else 1)


func vp_size() -> Vector2:
	return get_viewport_rect().size
