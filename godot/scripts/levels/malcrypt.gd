## The crypt under the church of Mălâncrav: two waves up the lower stair, then the Crypt Warden.
extends Level

const LOWER_STAIR := Vector2(2350, 700)

var wave := 0
var foes: Array[Enemy] = []
var warden: CryptWarden

func build() -> void:
	title = "THE CRYPT"
	subtitle = "Under the church of Mălâncrav"
	size = Vector2(2600, 1400)
	spawn = Vector2(320, 700)
	ground = Color("201e1c")
	tile = ""
	quest = MlQuest.new()
	rng = NetRandom.new(1461)
	add_block(Rect2(-200, -200, 3000, 400), "stone", 70.0)
	add_block(Rect2(-200, 1200, 3000, 400), "stone", 70.0)
	add_block(Rect2(-200, -200, 300, 1800), "stone", 70.0)
	add_block(Rect2(2500, -200, 300, 1800), "stone", 70.0)
	# pillars down the nave, and the old pews between them
	for i in 5:
		var x := 650.0 + i * 380.0
		add_block(Rect2(x - 40, 420, 80, 80), "stone", 160.0)
		add_block(Rect2(x - 40, 900, 80, 80), "stone", 160.0)
		if i < 4:
			add_block(Rect2(x + 110, 560, 160, 34), "pew", 26.0)
			add_block(Rect2(x + 110, 806, 160, 34), "pew", 26.0)
	for k in 4: add_decal(false, Vector2(126.0 + k * 14.0, 700), Vector2(14, 200), Color8(0x5a - k * 8, 0x52 - k * 8, 0x48 - k * 8), -988)
	add_decor(LOWER_STAIR, "crypt_stairs")
	add_torch(Vector2(200, 620), 220.0, Color(0.85, 0.8, 0.7), 0.55)
	add_torch(Vector2(1300, 700), 420.0, Color(1, 0.55, 0.28), 0.55)
	add_torch(LOWER_STAIR, 260.0, Color(0.6, 0.65, 1), 0.35)
	for it in [[Vector2(700, 300), "bone"], [Vector2(1500, 1100), "bone"], [Vector2(2100, 300), "chains"], [Vector2(1100, 1100), "barrel_rot"], [Vector2(1900, 1100), "lantern_iron"]]:
		add_decor(it[0], it[1])
	add_trigger(Rect2(100, 600, 30, 200), leave)
	spots["stairs"] = Vector2(130, 700)
	if G.side_has("ml_crypt"): return
	add_trigger(Rect2(500, 300, 200, 800), func():
		if wave != 0: return
		Audio.sfx("bell", -10.0, 0.6)
		_start_wave(1))

func line() -> String:
	match wave:
		0: return "The crypt. Something is coming up the lower stair."
		1: return "The moroi climb out of the crypt stairs. (%d left)" % _alive()
		2: return "Strigoi, leaping between the pews. (%d left)" % _alive()
		3: return "The Crypt Warden."
	return "The crypt is quiet. Back up the stairs."

func _alive() -> int:
	var n := 0
	for e in foes:
		if is_instance_valid(e) and e.hp > 0.0: n += 1
	return n

func _start_wave(w: int) -> void:
	wave = w; foes.clear()
	if w == 1:
		Hud.banner("THE FIRST WAVE", "Moroi drag themselves up out of the lower stair.")
		for o in [Vector2(0, -120), Vector2(0, 120), Vector2(-150, -260), Vector2(-150, 260)]: _add("moroi", LOWER_STAIR + o)
	elif w == 2:
		Hud.banner("THE SECOND WAVE", "Strigoi. They go over the pews like cats.")
		for o in [Vector2(-200, -300), Vector2(-200, 300), Vector2.ZERO]: _add("strigoi", LOWER_STAIR + o)
	else:
		warden = spawn_enemy("warden", LOWER_STAIR + Vector2(-150, 0), CryptWarden)
		warden.call_up.connect(func():
			for o in [Vector2(0, -200), Vector2(0, 200)]: _add("moroi", LOWER_STAIR + o))
		warden.beaten.connect(_won)

func _add(kind: String, g: Vector2) -> void:
	var e := spawn_enemy(kind, g)
	e.state = "chase"; e.aggro = 4000.0
	foes.append(e)
	e.died.connect(func(_e):
		if wave in [1, 2] and _alive() == 0: _start_wave(wave + 1))

func _won() -> void:
	wave = 4
	for e in foes:
		if is_instance_valid(e) and e.hp > 0.0: e.queue_free()
	G.side_add("ml_crypt")
	G.start_dialogue("The crypt", [
		"(Silence. Dust coming down from the vault. The Warden's shovel lies across the lower stair like a bar across a door.)",
		"(Up above, the light through the door has gone orange. Dusk already. And from the edge of the village, a sound you know: wolves... no. Moroi. Hunting.)"])

func leave() -> void:
	if G.state != G.State.PLAY or G.transitioning: return
	if wave in [1, 2, 3]:
		Hud.toast("Not with the dead at your back.")
		return
	Loader.goto_level("malancrav", MlQuest.crypt_door + Vector2(0, 120) if MlQuest.crypt_door != Vector2.ZERO else null)
