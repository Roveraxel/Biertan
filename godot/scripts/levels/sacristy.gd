## The hall church of Biertan and the sacristy door of 1515 with its nineteen bolts, shot from the inside.
## The nine things carried from the road draw eighteen; the baron draws the last himself. He fights as the
## lord with the old bell rope, breaks into wolves and bats, and is gone down the tunnel under his own tomb.
extends Level

const DOOR_AT := Vector2(1200, 520)
const BELL_AT := Vector2(260, 820)
const SPAWN_AT := Vector2(1200, 1380)

var phase := 0              # 0 locked, 1 lord, 2 swarm, 3 mort, 4 done
var lord: VampireBoss
var mort_b: VampireBoss
var swarm: Array[Enemy] = []
var allies: Array[Dictionary] = []
var door_block := {}
var door_prop: Prop
var stake_prop: Prop
var bell_cd := 0.0
var rings := 0

func build() -> void:
	title = "THE CHURCH OF BIERTAN"
	subtitle = "The sacristy door, 1515"
	size = Vector2(2400, 1600)
	spawn = SPAWN_AT
	ground = Color("242220")
	tile = ""
	quest = BtQuest.new()
	rng = NetRandom.new(1515)
	add_block(Rect2(-200, -200, 2800, 400), "stone", 90.0)
	add_block(Rect2(-200, 1500, 2800, 300), "stone", 90.0)
	add_block(Rect2(-200, -200, 300, 2000), "stone", 90.0)
	add_block(Rect2(2300, -200, 300, 2000), "stone", 90.0)
	# the hall church: two rows of pillars, the pews between
	for i in 4:
		var x := 560.0 + i * 430.0
		add_block(Rect2(x - 40, 650, 80, 80), "stone", 170.0)
		add_block(Rect2(x - 40, 1100, 80, 80), "stone", 170.0)
		if i < 3:
			add_block(Rect2(x + 120, 1230, 180, 34), "pew", 26.0)
			add_block(Rect2(x + 120, 1330, 180, 34), "pew", 26.0)
	add_decor(Vector2(1200, 330), "altar")
	add_decor(Vector2(980, 360), "candelabra"); add_decor(Vector2(1420, 360), "candelabra")
	add_torch(Vector2(1200, 420), 380.0, Color(1, 0.65, 0.35), 0.7)
	add_torch(Vector2(1200, 1200), 520.0, Color(1, 0.78, 0.55), 0.3)
	add_torch(BELL_AT, 240.0, Color(1, 0.7, 0.4), 0.5)
	add_decor(BELL_AT + Vector2(0, -40), "bell_rope")
	add_prop("task", "bell", "The bell rope", BELL_AT + Vector2(0, 40), "E   Ring the bell")
	add_trigger(Rect2(1050, 1480, 300, 20), leave)
	# the sacristy: a room behind the door, the vampire's sarcophagus inside
	add_decor(Vector2(1200, 250), "sarcophagus")
	var open := G.side_has("bt_open")
	door_prop = add_prop("task", "door", "The sacristy door", DOOR_AT + Vector2(0, 60), "" if open else "E   The nineteen locks")
	add_decor(DOOR_AT, "door_open" if open else "door_locks")
	# the sacristy wall across the east end of the church, with the door set in it
	add_block(Rect2(100, 470, DOOR_AT.x - 90.0 - 100.0, 50), "stone", 60.0)
	add_block(Rect2(DOOR_AT.x + 90.0, 470, 2300.0 - DOOR_AT.x - 90.0, 50), "stone", 60.0)
	if not open: door_block = add_block(Rect2(DOOR_AT.x - 90.0, 470, 180, 50), "hidden", 0.0)
	spots["out"] = Vector2(1200, 1440)
	if G.side_has("bt_fled"):
		phase = 4
		add_decor(Vector2(1200, 300), "trapdoor")
		add_prop("task", "trapdoor", "The stair under the tomb", Vector2(1200, 360), "E   Follow him down")

func line() -> String:
	match phase:
		0: return "The sacristy door. Nineteen bolts, shot from the inside; you can draw %d of them." % _locks()
		1: return "The baron. Mind the bell rope's lash."
		2: return "He has broken into wolves and bats. (%d left)" % _swarm_left()
		3: return "He's down. Drive Muma's oak stake into his heart." if is_instance_valid(mort_b) and mort_b.hp <= 1.0 else "The strigoi mort. Ring the bell to pin him, then strike. (Rings: %d)" % rings
	return "He is gone, down the tunnel under his own tomb. Out, and after him."

func _locks() -> int: return 2 * BtQuest.tokens_have()

func _swarm_left() -> int:
	var n := 0
	for e in swarm:
		if is_instance_valid(e) and e.hp > 0.0 and not e.fleeing: n += 1
	return n

func bell_ready() -> bool: return phase == 3 and is_instance_valid(mort_b) and mort_b.hp > 1.0 and mort_b.stun_t2 <= 0.0 and bell_cd <= 0.0
func stake_ready() -> bool: return phase == 3 and is_instance_valid(mort_b) and mort_b.hp <= 1.0

# ------------------------------------------------------------------ the nineteen locks

func door() -> void:
	if phase != 0: return
	if BtQuest.tokens_have() < BtQuest.TOKENS.size():
		var missing := PackedStringArray()
		for tk in BtQuest.TOKENS:
			if not G.side_has(tk[0]): missing.append(tk[1])
		G.start_dialogue("The sacristy door", [
			"(Oak and iron, 1515. Nineteen bolts, and every one of them shot from the inside. You can draw %d.)" % _locks(),
			"Each thing you carry from the road fits two of them. Still missing: " + ", ".join(missing) + "."])
		return
	var lines := ["(Oak and iron, 1515. Nineteen bolts, and every one of them shot from the inside. This door was never meant to keep anything in.)"]
	var n := 0
	for tk in BtQuest.TOKENS:
		n += 2
		lines.append("(%s: two bolts slide back. %d of 19.)  %s" % [tk[1].substr(0, 1).to_upper() + tk[1].substr(1), n, tk[2]])
	lines.append("(Eighteen. One bolt left, and nothing left in your pockets.)")
	lines.append("(It slides back by itself.)")
	lines.append("The baron: You took your time. Supper is cold.")
	G.start_dialogue("The sacristy door", lines, func():
		G.side_add("bt_open")
		if not door_block.is_empty(): remove_block(door_block)
		for d in decors.duplicate():
			if is_instance_valid(d) and d.sprite_name == "door_locks": remove_decor(d)
		add_decor(DOOR_AT, "door_open")
		if is_instance_valid(door_prop): remove_prop(door_prop)
		Audio.sfx("shriek", -2.0, 0.5)
		Hud.banner("THE BARON OF BIERTAN", "Midnight. He is not the man who carved your supper.")
		phase = 1
		lord = spawn_enemy("vampire", DOOR_AT + Vector2(0, 120), VampireBoss))

func call_thralls(at: Vector2) -> void:
	for o in [Vector2(-160, -40), Vector2(160, -40)]:
		var e := spawn_enemy("thrall", at + o)
		e.state = "chase"; e.aggro = 3000.0

# ------------------------------------------------------------------ the swarm, and Muma's animals

func _scatter_at(at: Vector2, r: float) -> Vector2:
	return at + Vector2.from_angle(randf() * TAU) * sqrt(randf()) * r

func shatter(v: VampireBoss) -> void:
	if phase != 1: return
	phase = 2
	var at := v.pos
	Fx.ring(at, Color(0.3, 0.05, 0.08, 0.9), 200.0, 0.8)
	Audio.sfx("shriek", 0.0, 0.7)
	G.boss = null
	get_tree().create_timer(0.05, false).timeout.connect(v.queue_free)
	Hud.banner("HE BREAKS APART", "Wolves out of his coat, bats out of his mouth.")
	for i in 5: _add("wolf", _scatter_at(at, 200.0))
	for i in 8: _add("bat", _scatter_at(at, 260.0))

func _add(kind: String, at: Vector2) -> void:
	var e := spawn_enemy(kind, at)
	e.state = "chase"; e.aggro = 3000.0
	e.died.connect(func(_e): _swarm_check())
	swarm.append(e)

func _allies() -> void:
	Hud.banner("THE OATH HOLDS", "Through the church door: a fox, a deer, an owl, and a bear with a bandaged leg.")
	Audio.sfx("boss_roar", -6.0, 1.1)
	for it in [["ally_fox", "The fox"], ["ally_deer", "The deer"], ["ally_owl", "The owl"], ["mbear", "The bear"]]:
		allies.append({p = add_prop("npc", it[0], it[1], SPAWN_AT + Vector2(randf_range(-200.0, 200.0), 30), "", Color.WHITE), cd = 0.0})

func _swarm_check() -> void:
	if phase != 2 or _swarm_left() > 0: return
	phase = 4
	G.boss = null
	for e in Enemy.all.duplicate():
		if is_instance_valid(e) and e.hp > 0.0: e.queue_free()   # his servants drop where they stand
	G.start_dialogue("The sacristy", [
		"(The last bat goes up into the vault and does not come down. The church is silent.)",
		"(In the sacristy the lid of the sarcophagus has been pushed aside. No body. A stair, going down, older than the church, and a cold draught coming up it that smells of earth.)",
		"(On the lid, a name the chisel never finished, and a year: 1321. Beside it, somebody has cut a wreath, the kind a bridegroom wears.)",
		"(Far below, getting fainter, something is barking. A small dog, by the sound. Under the ground.)",
		"(The tunnel runs east. East is Criț, and Viscri. And Lorena's gate, which stood open.)",
	], func():
		G.side_add("bt_fled")
		add_decor(Vector2(1200, 300), "trapdoor")
		add_prop("task", "trapdoor", "The stair under the tomb", Vector2(1200, 360), "E   Follow him down")
		G.player.coins += 60
		Audio.sfx("bell", -2.0, 0.8)
		Hud.banner("HE HAS FLED", "Outside, somebody has found the bell rope. Biertan is waking up.")
		Hud.toast("Quest complete: The Locked Door.  Follow him down the stair under the tomb."))

func _process(dt: float) -> void:
	super(dt)
	if not is_instance_valid(G.player) or G.state != G.State.PLAY: return
	bell_cd = maxf(0.0, bell_cd - dt)
	for a in allies:
		var p: Prop = a.p
		if not is_instance_valid(p): continue
		a.cd -= dt
		var best: Enemy = null; var bd := INF
		var pp := p.pos
		for e in Enemy.all:
			if is_instance_valid(e) and e.hp > 0.0 and not e is VampireBoss and pp.distance_to(e.pos) < bd:
				bd = pp.distance_to(e.pos); best = e
		if best:
			var sp := 280.0 if p.id == "ally_owl" else (150.0 if p.id == "mbear" else 220.0)
			if bd > 70.0: p.pos = pp.move_toward(best.pos, sp * dt)
			elif a.cd <= 0.0:
				a.cd = 3.0 if p.id == "mbear" else 2.0   # they help; the hunter still does the work
				best.hurt(8.0 if p.id == "mbear" else 3.0, (best.pos - pp).normalized())
				if randf() < 0.4: Fx.text(pp, {"mbear": "GRRAWR", "ally_owl": "HOO!", "ally_fox": "yip!"}.get(p.id, "(a kick)"), Fx.AMBER, 70.0)
		elif pp.distance_to(G.player.pos) > 160.0:
			p.pos = pp.move_toward(G.player.pos, 160.0 * dt)

# ------------------------------------------------------------------ the bell and the stake

func ring_bell() -> void:
	if phase != 3 or not is_instance_valid(mort_b):
		G.start_dialogue("The bell rope", ["The great bell's rope, hanging in the tower doorway. Not yet."])
		return
	if mort_b.hp <= 1.0: return
	if bell_cd > 0.0:
		Hud.toast("The bell is still swinging back.")
		return
	bell_cd = 7.0; rings += 1
	mort_b.stun_t2 = 4.0
	Audio.sfx("bell", 0.0, 0.6)
	Fx.shake(0.3)
	Fx.ring(BELL_AT, Color(1, 0.85, 0.5, 0.9), 400.0, 0.7)
	Fx.ring(mort_b.pos, Color(1, 0.85, 0.5, 0.9), 120.0, 0.6)
	Hud.toast("DONG. The bell's voice pins him to the floor. Strike!" if rings == 1 else "DONG. Again. Strike!")

func mort_down(v: VampireBoss) -> void:
	if is_instance_valid(stake_prop): return
	v.fainted = true   # laid out on his back, waiting for the stake
	Fx.ring(v.pos, Color(0.9, 0.85, 0.7, 0.9), 140.0, 0.6)
	Hud.banner("HE FALLS", "Not dead. He's never been alive. Muma's stake, now.")
	stake_prop = add_prop("task", "stake", "The strigoi mort", v.pos + Vector2(0, 90), "E   Drive Muma's oak stake into his heart")

func stake() -> void:
	if not stake_ready(): return
	G.start_dialogue("The sacristy", [
		"(You take the oak branch from your belt. A tree that gave itself. It is warm in your hand.)",
		"(He looks up at you with old, old eyes, and says something in the Saxon of two hundred years ago. It might be \"thank you\". It might not.)",
		"(You drive it home.)",
		"(The strigoi mort goes to ash in one long breath, and the ash goes out under the door like a draught.)",
		"(In the tower, the great bell starts to ring on its own. Then, from far off down the valley, Mălâncrav's answers. Then Richiș's. Then all of them.)",
		"(Outside, doors are opening. Lanterns in the street. Somebody laughing, somebody crying. A dog barks, and another answers.)",
		"(The nineteen bolts hang open. They can stay that way.)",
	], func():
		G.side_add("bt_done")
		G.boss = null
		if is_instance_valid(mort_b): mort_b.queue_free()
		for a in allies:
			if is_instance_valid(a.p): remove_prop(a.p)
		if is_instance_valid(stake_prop): remove_prop(stake_prop)
		phase = 4
		add_decor(Vector2(1200, 330), "ash_stake")
		G.player.coins += 100
		Hud.banner("THE BELLS OF BIERTAN", "It's over. Go home, hunter. Viscri, and Lorena, and Azorel.")
		Hud.toast("Quest complete: The Locked Door. Walk home to Viscri."))

func leave() -> void:
	if G.state != G.State.PLAY or G.transitioning: return
	if phase in [1, 2, 3]:
		Hud.toast("Not with him behind you.")
		return
	Loader.goto_level("biertanfort", load("res://scripts/levels/biertanfort.gd").C + Vector2(0, 210))
