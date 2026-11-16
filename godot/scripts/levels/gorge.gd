## The gorge on the road back from Biertan: a drowned quarry between rock walls, with old standing stones on
## its floor. A ragged beggar sits at its mouth. He is a Solomonar, Biertan once refused him bread, and he
## takes the hunter for one of theirs: the curse, the storm, the balaur. Then the bread, and a favour owed.
extends Level

const CENTRE := Vector2(1000, 1350)
const STONES := [Vector2(700, 1150), Vector2(1300, 1150), Vector2(1000, 1500), Vector2(620, 1600), Vector2(1380, 1600), Vector2(1000, 950)]
const LEDGE := Vector2(1560, 820)
const COL := Color(0.8, 0.88, 1)

var balaur: StormBalaur
var wizard: Prop
var cursed := false
var hail_t := 0.0
var hails: Array[Dictionary] = []
var strikes: Array[Dictionary] = []
var _arrive_t := 0.0

func ambient() -> Color:
	return Color(0.42, 0.44, 0.52) if not cursed else Color(0.24, 0.26, 0.36)

func build() -> void:
	title = "THE GORGE"
	subtitle = "The drowned quarry"
	size = Vector2(1800, 2400)
	spawn = Vector2(900, 2280)
	ground = Color("2a2723")
	tile = ""
	rng = NetRandom.new(505)
	scatter(Rect2(140, 0, 1520, 2400), 700, [Color("3a3630"), Color("1c1a17"), Color("4a4640")])
	add_path([Vector2(900, 2400), Vector2(900, 2000), Vector2(1000, 1500), Vector2(1100, 900), Vector2(1000, 0)], 110.0)
	# the drowned pit along the west wall
	add_decal(false, Vector2(480, 620), Vector2(680, 760), Color("0c1a20"), -990)
	for i in 9: add_decal(false, Vector2(220 + i * 62, 300 + (i % 4) * 150), Vector2(60, 3), Color(0.5, 0.6, 0.65, 0.25), -988)
	add_block(Rect2(140, 240, 680, 760), "hidden", 0.0)
	var y := 0.0
	while y < 2400.0:
		add_block(Rect2(0, y, 140, 100), "rock", rand(70, 110))
		add_block(Rect2(1660, y, 140, 100), "rock", rand(70, 110))
		y += 100.0
	add_block(Rect2(-200, -200, 2200, 200), "hidden", 0.0)
	add_block(Rect2(-200, 2400, 2200, 200), "hidden", 0.0)
	add_block(Rect2(LEDGE.x - 90, LEDGE.y - 70, 190, 150), "rock", 60.0)   # the ledge he reads from
	for c in STONES: add_block(Rect2(c.x - 26, c.y - 20, 52, 40), "stone", 95.0)
	for p in [Vector2(760, 2050), Vector2(1040, 2050)]: add_brazier(p)
	add_torch(CENTRE, 620.0, Color(0.6, 0.7, 0.9), 0.4)
	add_prop("task", "back", "Back to Biertan", Vector2(900, 2340), "E   Go back up to Biertan")
	add_prop("task", "road", "The road on", Vector2(1000, 120), "E   Take the road down to the vineyards")
	var has := func(f: String) -> bool: return G.side_has(f)
	if has.call("gg_done"):
		wizard = add_prop("npc", "solomonar", "The Solomonar", CENTRE + Vector2(120, -40), "E   Speak with the Solomonar")
		return
	wizard = add_prop("npc", "solomonar", "A beggar", Vector2(900, 1880), "E   Speak with the beggar")
	add_decor(Vector2(960, 1870), "book")
	add_trigger(Rect2(140, 1740, 1520, 40), curse)

func target() -> Array:
	if not G.side_has("gg_done"):
		if not cursed: return [spots["solomonar"], "A beggar on the road"]
		if is_instance_valid(balaur) and not balaur.done: return []
		return [spots["solomonar"], "The Solomonar"]
	return [spots["road"], "The road on"]

func objective() -> String:
	if G.side_has("gg_done"): return "The gorge is quiet. The road runs on down to the vineyards."
	if not cursed: return "The road back runs through the old quarry. Somebody is sitting in the middle of it."
	if is_instance_valid(balaur) and not balaur.done: return "The Solomonar's storm. Beat his balaur back; lightning takes the tallest thing."
	return "The balaur is down. The old man is climbing off his rock."

func marker(id: String) -> bool:
	return id == "solomonar" and not G.side_has("gg_done") and (not cursed or (is_instance_valid(balaur) and balaur.done))

func _process(dt: float) -> void:
	super(dt)
	if not is_instance_valid(G.player): return
	if not G.side_has("gg_arrive") and G.state == G.State.PLAY and not G.transitioning:
		_arrive_t += dt
		if _arrive_t > 0.6:
			G.side_add("gg_arrive")
			G.start_dialogue("The gorge", [
				"(The cart stops where the road turns to rubble. Magda: \"This is as far as the horse goes. HAIDA, on your feet, he has half a night on you!\")",
				"(Vlad hands you a loaf, still warm, wrapped in a cloth. \"For the road. Don't argue.\" Magda pretends she did not see him do something kind.)",
				"(Ahead: the old quarry, flooded on one side, with standing stones on its floor older than the quarry. And a man sitting on the road, wrapped in rags, with a book on his knee.)"])
	if not cursed or G.state != G.State.PLAY: return
	var live := is_instance_valid(balaur) and not balaur.done
	# hail, as long as the curse holds
	if live:
		hail_t -= dt
		if hail_t <= 0.0:
			hail_t = 0.55
			var at: Vector2 = G.player.pos + Vector2.from_angle(randf() * TAU) * sqrt(randf()) * 170.0
			Fx.ring(at, Color(0.85, 0.9, 1, 0.5), 34.0, 0.5)
			hails.append({at = at, t = 0.5})
	for h in hails.duplicate():
		h.t -= dt
		if h.t > 0.0: continue
		hails.erase(h)
		Fx.ring(h.at, Color(1, 1, 1, 0.9), 22.0, 0.15)
		if G.player.pos.distance_to(h.at) < 36.0 and G.player.inv_t <= 0.0:
			G.player.hurt(4.0, Vector2.ZERO)
			G.player.slow_t = maxf(G.player.slow_t, 0.6)
	for s in strikes.duplicate():
		s.t -= dt
		if s.t > 0.0: continue
		strikes.erase(s)
		_bolt(s.at, s.stone)

## The balaur throws lightning at a spot; it lands a moment later, on a standing stone if one is near.
func lightning(at: Vector2) -> void:
	var stone := false
	for c in STONES:
		if c.distance_to(at) < 150.0:
			at = c; stone = true
			break
	Fx.ring(at, Color(0.9, 0.95, 1, 0.8), 80.0, 0.85)
	strikes.append({at = at, t = 0.85, stone = stone})

func _bolt(at: Vector2, stone: bool) -> void:
	var m := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.12, 9.0, 0.12)
	m.mesh = bm
	m.material_override = Mats.unlit(Color(0.92, 0.96, 1))
	m.position = Fx.to3(at, 4.5)
	add_child(m)
	var l := OmniLight3D.new()
	l.light_color = COL; l.light_energy = 6.0; l.omni_range = 14.0
	l.position = Fx.to3(at, 2.0)
	add_child(l)
	get_tree().create_timer(0.12, false).timeout.connect(func(): m.queue_free(); l.queue_free())
	Fx.shake(0.25)
	Audio.sfx_at("ignite", at, 2.0, 0.5)
	Fx.ring(at, Color(1, 1, 1, 0.9), 90.0, 0.25)
	if stone:
		if randf() < 0.5: Fx.text(at, "(the stone takes it)", COL, 110.0)
	elif G.player.pos.distance_to(at) < 80.0 and G.player.inv_t <= 0.0:
		G.player.hurt(14.0, (G.player.pos - at).normalized())

func curse() -> void:
	if cursed or G.side_has("gg_done"): return
	cursed = true
	G.start_dialogue("A beggar", [
		"(He does not look up.) From Biertan. I can smell it on you. Roast pork and no salt.",
		"I came to Biertan in a wet June with my book under my arm and asked for bread. One loaf. The sexton set the dogs on me. They had dogs, then.",
		"(He stands. He is much taller than a beggar should be. The rags are a cloak, and the stick is a staff, and the book is open.)",
		"I went to the school under the mountain for seven years, boy, and I rode out of it on the back of the storm. Biertan has had hail on its vines every summer since. Now it sends me a hunter.",
		"(The sky above the quarry goes the colour of a bruise. Something very long turns over inside the cloud.)",
	], func():
		await G.show_story("balaur_rise")   # the storm opens and the balaur comes down: the picture, then the fight
		Hud.fade_to(0.0, 0.6)
		wizard.display = "The Solomonar"
		wizard.pos = LEDGE
		spots["solomonar"] = LEDGE
		WorldBuilder.apply_darkness(self)
		Hud.banner("THE SOLOMONAR", "Hail, wind, and what he rides. The standing stones are older than he is.")
		Audio.sfx("boss_roar", -2.0, 0.8)
		balaur = spawn_enemy("storm_balaur", CENTRE + Vector2(520, 0), StormBalaur)
		balaur.centre = CENTRE; balaur.arena = self
		balaur.beaten.connect(_beaten))

func _beaten() -> void:
	hails.clear(); strikes.clear()
	WorldBuilder.apply_darkness(self)
	Hud.banner("THE BALAUR IS DOWN", "It lies in the rubble, steaming, one eye on its master.")
	var at := balaur.pos + Vector2(110, 60)
	wizard.pos = at
	spots["solomonar"] = at

func talk(id: String) -> bool:
	if id != "solomonar": return false
	if G.side_has("gg_done"):
		G.start_dialogue("The Solomonar", ["A wedding, you say, if it comes to that. In a graveyard. (He scratches the balaur under the jaw.) I have not been asked to a wedding in two hundred years. I might bring the weather."])
	elif not cursed: curse()
	elif is_instance_valid(balaur) and balaur.done:
		G.start_dialogue("The Solomonar", [
			"(He climbs down off his rock a good deal less grandly than he went up, and stands over the balaur with his hand on its neck. It is breathing. He does not look at you.)",
			"(You sit down on a stone, because your legs have decided to. You unwrap Vlad's loaf. It is still warm. You break it, the way you would at the stână with any stranger who came up out of the weather, and hold half out.)",
			"(He looks at the bread for a long time.)",
			"...You are not from Biertan.",
			"(No. A shepherd, from the mountain. Just walking through.)",
			"(He takes it. He eats it standing up, like a man who has not been handed anything in a long while. The hail stops between one bite and the next.)",
			"I cursed the wrong man. That is an embarrassing thing at my age. (He closes the book.) I owe you weather, shepherd. When you need it, look up.",
		], func():
			G.side_add("gg_done"); G.side_add("favour_solomonar")
			cursed = false
			WorldBuilder.apply_darkness(self)
			wizard.display = "The Solomonar"
			Audio.sfx("coin", -4.0)
			Hud.toast("The curse is lifted. The Solomonar owes you weather."))
	else:
		G.start_dialogue("The Solomonar", ["(He is reading aloud from the ledge, in a language with too many consonants. The hail answers him.)"])
	return true

func use(p: Prop) -> void:
	match p.id:
		"back":
			if cursed: Hud.toast("The storm has shut the road behind you.")
			else: Loader.goto_level("biertanfort")
		"road":
			if not G.side_has("gg_done"): G.start_dialogue("The road on", ["Through the quarry, and past whoever that is."])
			else: Loader.goto_level("vineyard")
