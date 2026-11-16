## The vineyards below the gorge, late in a late harvest. The women in the press-house are working through
## Tuesday night to save the grapes and to finish a shirt, and Tuesday night belongs to Marțolea. Before dark
## every vessel must be turned on its face, because she calls the things of the house to open the door for
## her, and only the ones turned down cannot answer. Each one missed answers her, and makes her stronger.
extends Level

const YARD := Rect2(1700, 960, 820, 560)
const GATE_AT := Vector2(2110, 1520)
## id, sprite, where, what she calls it
const VESSELS := [
	["pot", "pot_steam", Vector2(1900, 1130), "Pot"],
	["tub", "washtub", Vector2(2330, 1160), "Tub"],
	["jug", "wine_jug", Vector2(2130, 1250), "Jug"],
	["lamp", "lantern", Vector2(2040, 1470), "Lamp"],
	["keg", "salt_barrel", Vector2(1790, 1400), "Keg"],
	["barrel", "barrel", Vector2(2420, 900), "Barrel"],            # round the back of the press-house
	["trough", "trough", Vector2(1380, 1300), "Trough"],            # out by the well
	["lantern", "lantern_iron", Vector2(1100, 760), "Lantern"],     # left hanging among the vines
]

var vessel_decor := {}
var night := false
var over := false
var boss: Martolea
var gate: Gate
var live: Array[Dictionary] = []
var lights: Array[OmniLight3D] = []
var _arrive_t := 0.0

static func has(f: String) -> bool: return G.side_has(f)

func turned() -> int:
	var n := 0
	for v in VESSELS:
		if has("vy_t_" + v[0]): n += 1
	return n

func ambient() -> Color:
	return Color(0.95, 0.9, 0.82).lerp(Color(0.12, 0.14, 0.3), 0.88 if night else (0.45 if has("vy_done") else 0.62))

func build() -> void:
	title = "THE VINEYARDS"
	subtitle = "Tuesday evening"
	size = Vector2(3000, 2200)
	spawn = Vector2(260, 1900)
	ground = Color("2c2a1e")
	rng = NetRandom.new(1611)
	scatter(Rect2(Vector2.ZERO, size), 520, [Color("3a3424"), Color("2a2618"), Color("4a3c22")])
	add_path([Vector2(0, 1900), Vector2(700, 1860), Vector2(1500, 1720), Vector2(2110, 1640), Vector2(2700, 1700), Vector2(3000, 1650)], 100.0)
	add_path([Vector2(2110, 1640), GATE_AT], 80.0)
	# the terraces
	var y := 220.0
	while y < 1500.0:
		var x := 180.0 + fmod(y, 97.0)
		while x < 2900.0:
			var p := Vector2(x, y + (rng.f() - 0.5) * 24.0)
			x += 150.0
			if YARD.grow(160.0).has_point(p) or Rect2(1650, 700, 900, 300).has_point(p): continue
			if rng.f() < 0.12: continue
			add_decor(p, "vine_row", 0.0, rng.f() < 0.5)
		y += 170.0
	add_block(Rect2(-200, -200, 3400, 200), "hidden", 0.0)
	add_block(Rect2(-200, 2200, 3400, 200), "hidden", 0.0)
	add_block(Rect2(-200, -200, 200, 2600), "hidden", 0.0)
	add_block(Rect2(3000, -200, 200, 2600), "hidden", 0.0)
	# the press-house and its walled yard
	add_block(Rect2(1760, 760, 620, 200), "house", 58.0)
	add_block(Rect2(YARD.position.x, YARD.position.y, 24, YARD.size.y), "wall", 34.0)
	add_block(Rect2(YARD.end.x - 24, YARD.position.y, 24, YARD.size.y), "wall", 34.0)
	add_block(Rect2(YARD.position.x, YARD.end.y - 24, GATE_AT.x - 60 - YARD.position.x, 24), "wall", 34.0)
	add_block(Rect2(GATE_AT.x + 60, YARD.end.y - 24, YARD.end.x - GATE_AT.x - 60, 24), "wall", 34.0)
	add_block(Rect2(2380, 760, 140, 24), "wall", 34.0)
	gate = Gate.make(self, GATE_AT + Vector2(0, -12), Vector2(124, 24), 0.0)
	gate.open()
	lights.append(add_torch(Vector2(2110, 1200), 520.0, Color(1, 0.72, 0.42), 1.0))
	lights.append(add_torch(GATE_AT + Vector2(-70, -60), 220.0, Color(1, 0.7, 0.4), 0.7))
	add_decor(Vector2(2110, 1000), "barrels", 40.0)
	add_decor(Vector2(1980, 1020), "wine_press", 28.0)
	add_decor(Vector2(2230, 1020), "wine_rack", 24.0)
	add_decor(Vector2(2040, 1120), "harvest_basket", 12.0)
	add_decor(Vector2(1340, 1240), "well", 40.0)
	add_decor(Vector2(2200, 1330), "feast_table", 34.0)
	add_prop("task", "shirt", "A shirt on the table", Vector2(2200, 1390), "E   Look at the shirt")
	add_prop("npc", "vybaba", "Baba Veta, from Criț", Vector2(2020, 1380), "E   Speak with Baba Veta", Color("3a3430"))
	for it in [["vyw1", Vector2(1960, 1190)], ["vyw2", Vector2(2280, 1230)], ["vyw3", Vector2(2260, 1400)]]:
		add_prop("npc", it[0], "A woman of the vineyard", it[1], "E   Talk")
	for v in VESSELS:
		var d := add_decor(v[2], v[1], 16.0)
		vessel_decor[v[0]] = d
		if has("vy_t_" + v[0]): _face_down(d)
		add_prop("task", "v_" + v[0], "", v[2] + Vector2(0, 34), "E   Turn it face down")
	add_prop("task", "back", "Back to the gorge", Vector2(120, 1900), "E   Go back up to the gorge")
	add_prop("task", "road", "The road east", Vector2(2900, 1660), "E   Take the road into the forest")
	if has("vy_done"): over = true

func _face_down(d: Decor) -> void:
	if d.sprite:
		d.sprite.flip_v = true
		d.sprite.modulate = Color(0.7, 0.7, 0.7)

func target() -> Array:
	if night: return []
	if not has("vy_done"): return [spots["vybaba"], "The press-house"]
	return [spots["road"], "The road east"]

func objective() -> String:
	if night: return "Marțolea. She is as strong as the vessels that answered her." if is_instance_valid(boss) else "Somebody is knocking at the gate."
	if has("vy_done"): return "Wednesday. The shirt is finished. The road runs east into the Wolf Forest."
	if not has("vy_job"): return "Lamps in a press-house, long after dark. Somebody is still working."
	return "Turn every vessel face down before she comes: in the yard, behind the house, out among the vines. (%d turned)  Then tell Baba Veta." % turned()

func marker(id: String) -> bool:
	return id == "vybaba" and not night and not has("vy_done")

func _process(dt: float) -> void:
	super(dt)
	if not is_instance_valid(G.player): return
	if not has("vy_arrive") and G.state == G.State.PLAY and not G.transitioning:
		_arrive_t += dt
		if _arrive_t > 0.6:
			G.side_add("vy_arrive")
			G.start_dialogue("The vineyards", [
				"(Terraces of vines down the south slope, leaves gone yellow and rust, the grapes still on them in the last week of October. A late harvest, and a wet one.)",
				"(Dusk. Below the terraces, lamps in a walled yard, and women's voices. They should have gone home hours ago.)"])
	if not night or G.state != G.State.PLAY: return
	# the vessels that answered her hop after the hunter
	for v in live:
		var d: Decor = v.d
		if not is_instance_valid(d): continue
		v.cd -= dt
		var to: Vector2 = G.player.pos - d.pos
		if v.cd <= 0.0:
			d.pos += to.normalized() * (150.0 + 40.0 * sin(v.ph + Time.get_ticks_msec() * 0.006)) * dt
			if to.length() < 34.0 and G.player.inv_t <= 0.0:
				G.player.hurt(5.0, to.normalized())
				v.cd = 1.4
				Fx.text(d.pos, "clonk", Fx.AMBER, 40.0)
		if d.sprite: d.sprite.position.y = absf(sin(v.ph + Time.get_ticks_msec() * 0.012)) * 0.25

# ------------------------------------------------------------------ the night

func start_night() -> void:
	night = true
	WorldBuilder.apply_darkness(self)
	var silent := PackedStringArray(); var loud := []
	for v in VESSELS:
		if has("vy_t_" + v[0]): silent.append(v[3])
		else: loud.append(v)
	var lines := [
		"(Baba Veta drops the bar across the gate and lays the broom over the threshold. The women stop singing.)",
		"(Three knocks. Slow, polite.)",
		"\"Open up, girls. It is only an old woman, come to help with the spinning. Such a lot of work, and on a Tuesday.\"",
		"Baba Veta: Nobody answers. Nobody. Not a word.",
		"(A long quiet. Then the voice again, not at the gate now: all round the wall at once.) \"Then the house will open for me. Things of this house! Your mistress is calling!\""]
	if not silent.is_empty(): lines.append("\"%s!\"  (Nothing. They lie on their faces and cannot hear.)" % "! ".join(silent))
	for v in loud: lines.append("\"%s!\"  (The %s rocks, and rights itself. \"Coming, mistress!\")" % [v[3], v[3].to_lower()])
	if loud.is_empty(): lines.append("(Not one thing in the house answers her. When she comes over the wall she is thin as smoke, and furious.)")
	else: lines.append("(The bar lifts by itself. %s.)" % ("One friend in the house was enough" if loud.size() == 1 else "%d friends in the house" % loud.size()))
	G.start_dialogue("Tuesday night", lines, func():
		gate = Gate.make(self, GATE_AT + Vector2(0, -12), Vector2(124, 24), 0.0)
		boss = spawn_enemy("martolea", GATE_AT + Vector2(0, -130), Martolea)
		boss.strengthen(loud.size())
		boss.beaten.connect(_cockcrow)
		Audio.sfx("shriek", -4.0, 0.7)
		Hud.banner("MARȚOLEA", "Tuesday evening herself." if loud.is_empty() else "Tuesday evening herself, and %d of the house with her." % loud.size())
		for v in loud:
			var d: Decor = vessel_decor[v[0]]
			d.set_solid(false)
			live.append({d = d, cd = randf() * 1.5, ph = randf() * 6.0})
			if v[0] in ["lamp", "lantern"]:   # a lamp that answers her goes out, and takes the light with it
				for l in lights: l.light_energy *= 0.35
		for p in props.duplicate():
			if is_instance_valid(p) and p.id.begins_with("v_"): remove_prop(p))

func _cockcrow() -> void:
	night = false; over = true
	var missed := live.size()
	for v in live:
		if is_instance_valid(v.d) and v.d.sprite: v.d.sprite.position.y = 0.0
	live.clear()
	Audio.sfx("bell", -10.0, 1.6)
	G.start_dialogue("Cockcrow", [
		"(A cock crows, somewhere down the valley. Hours early; somebody's rooster has lost count. It is enough.)",
		"(She straightens up. She is only an old woman in a black headscarf, a little out of breath.)",
		"Marțolea: Wednesday. (She looks at the shirt on the table, and then, for some reason, at your hands.) Finish it on Wednesday.",
		"(She goes out by the gate like anybody else, and shuts it behind her.)",
		"Baba Veta: I told them. Every pot, I said. " + ("And every pot it was. Well done, boy." if missed == 0 else "You missed %s. I counted." % ("one" if missed == 1 else str(missed))),
		"(In the morning the women finish the shirt: fine linen, white on white, a bridegroom's. Ordered in the spring by a gentleman from Biertan, they say, who paid in very old coin and never came for it.)",
		"Baba Veta: You are going that way. Take it. Somebody ought to wear it.",
	], func():
		G.side_add("vy_done"); G.side_add("groom_shirt")
		if is_instance_valid(boss): boss.queue_free()
		if is_instance_valid(gate): gate.open()
		for l in lights: l.light_energy = 1.0
		WorldBuilder.apply_darkness(self)
		G.player.coins += 30
		Audio.sfx("coin", -4.0)
		Hud.toast("A bridegroom's shirt, never collected. You fold it into your pack."))

# ------------------------------------------------------------------ talk and use

func talk(id: String) -> bool:
	match id:
		"vybaba":
			var who := "Baba Veta, from Criț"
			if has("vy_done"):
				G.start_dialogue(who, ["Sfânta Vineri in Criț, Marțolea here. The week has more mistresses than a girl has days off. Go on, the forest won't walk to you."])
			elif not has("vy_job"):
				G.start_dialogue(who, [
					"(One of the three grandmothers of Criț, with her sleeves rolled up and juice to the elbows.) You! The one with the basket. Good. Hands.",
					"The harvest is three weeks late and rotting on the vine. My niece's girls have to press tonight or lose it. And there is a shirt on that table promised for tomorrow.",
					"And it is Tuesday. Tuesday evening is not ours. After dark on a Tuesday you don't spin, you don't sew, you don't wash, or Marțolea comes to see who is at it.",
					"She will knock. We won't open. So she will call the things of the house to open for her: the pot, the tub, every vessel by its name. They are hers on a Tuesday. But a vessel lying on its face can't hear her.",
					"So. Every one of them, face down, before full dark. In the yard, behind the house, and wherever those girls left things lying out in the vines. Then come and tell me. Count twice.",
				], func(): G.side_add("vy_job"); Hud.toast("Turn every vessel face down. Then tell Baba Veta."))
			else:
				G.start_choice(who, ["%d turned. Is that all of them? I don't know, I didn't put them out. Do we bar the gate?" % turned()],
					["Not yet. I'm still looking.", "Bar the gate. Let her come."], func(pick: int):
						if pick == 1: start_night())
		"vyw1", "vyw2", "vyw3":
			G.start_dialogue("A woman of the vineyard", ["We left a lantern up in the top rows, I think. Or was that last week?" if id == "vyw1" else ("There's a trough by the well. Does a trough count? Baba Veta says everything counts." if id == "vyw2" else "(She is sewing very fast, and does not look up.)")] if not has("vy_done") else ["Wednesday. I have never been so glad of a Wednesday."])
		_: return false
	return true

func use(p: Prop) -> void:
	if p.id.begins_with("v_"):
		var vid := p.id.substr(2)
		if not has("vy_job"):
			G.start_dialogue("A vessel", ["It is the right way up, as a thing should be."])
			return
		G.side_add("vy_t_" + vid)
		_face_down(vessel_decor[vid])
		remove_prop(p)
		Audio.sfx("blip", -6.0, 0.7)
		Hud.toast("Face down. (%d turned)" % turned())
		return
	match p.id:
		"shirt": G.start_dialogue("The shirt", ["A man's shirt, fine linen, white embroidery on white. A bridegroom's. One sleeve still to do." if not has("vy_done") else "The table is clear. The shirt is in your pack."])
		"back":
			if night: Hud.toast("The gate is barred.")
			else: Loader.goto_level("gorge", Vector2(1000, 220))
		"road":
			if night: Hud.toast("The gate is barred.")
			elif not has("vy_done"): G.start_dialogue("The road east", ["Lamps in the press-house, and women's voices. See what keeps them first."])
			else: Loader.goto_level("forest")
