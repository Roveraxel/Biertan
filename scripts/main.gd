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
		"potion": [KEY_Q], "attack": [KEY_J],
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
	if name == "hub":
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
		toast("The road to Richiș is not yet walked. (Level 2 in development)")
		player.velocity = Vector2(-300, 0)
	else:
		goto("forest")


func leave_forest_west() -> void:
	if state == "play" and not transitioning:
		goto("hub", Vector2(1540, 600))


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
	goto("hub")


func on_boss_dead() -> void:
	banner("THE VARCOLAC FALLS", "The sun and moon are returned to the sky.")
	await get_tree().create_timer(3.0).timeout
	player.charm_dodge = true
	quest = 2
	toast("Received: Wolf-Fang Charm  (+10% dodge)")
	toast("Received: The Silver Thread  (quest item)")
	await get_tree().create_timer(2.5).timeout
	goto("hub", Vector2(900, 880))


# ---------------------------------------------------------------- frame

func _process(delta: float) -> void:
	t += delta
	if level != null and state != "title":
		mod.color = mod.color.lerp(level.ambient(), clampf(delta * 2.5, 0.0, 1.0))
	else:
		mod.color = Color.WHITE
	if state == "play":
		if current == "forest":
			G.dusk = minf(1.0, G.dusk + delta / 240.0)
		elif current == "hub":
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
	return (id == "anna" and (quest == 0 or quest == 2)) or (id == "ileana" and not met_ileana)


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
		"sign":
			start_dialogue("Carved post", ["Beyond this post, the Moon Clearing. Old shepherds say the Varcolac sleeps there between eclipses.", "Light the braziers if the sky goes dark. Beasts that swallow the moon fear a hearth."])


func talk(id: String) -> void:
	match id:
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
				start_dialogue("Frau Anna Roth", ["Richiș lies two days east, past the Hollow Hills. The pastor there will want to hear what you carry.", "Garlic tincture, ten coins?"], buy_potion)
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
	player.god = false
	player.hurt(9999.0, Vector2.RIGHT)
	chk.call(state == "dead", "death state")
	respawn()
	await get_tree().create_timer(1.5).timeout
	chk.call(state == "play" and player.hp > 0.0, "respawn works")
	print("TEST RESULT: ", "OK" if fails.is_empty() else "FAILED %d" % fails.size())
	get_tree().quit(0 if fails.is_empty() else 1)


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
