## "Muma Pădurii and the Feast", Criș. The village has gone mad (on ergot in the rye, as Denisa says and
## nobody believes); the forester blames the strigoi's rot and sends the hunter into Muma Pădurii's wood,
## where he frees her animals from the village's snares and breaks the rot mark on a wolf pack's alpha.
class_name CsQuest
extends RefCounted

const MAD := ["oakman", "henwoman", "goose1", "farmer", "towerkid"]
const SNARES := ["fox", "deer", "owl"]

static var forest_gate := Vector2.ZERO

static func has(f: String) -> bool: return G.side_has(f)
static func mark(f: String) -> void: G.side_add(f)

static func mad_seen() -> int:
	var n := 0
	for x in MAD:
		if has("cs_m_" + x): n += 1
	return n

static func freed() -> int:
	var n := 0
	for a in SNARES:
		if has("cs_" + a): n += 1
	return n

static func all_freed() -> bool: return freed() == SNARES.size() and has("cs_bear")

func _to(id: String, label: String) -> Array:
	return [G.level.spots[id], label] if G.level.spots.has(id) else []

func _near(ids: Array) -> Array:
	var pl: Vector2 = G.player.pos
	var best := []; var bd := INF
	for it in ids:
		if G.level.spots.has(it[0]) and pl.distance_to(G.level.spots[it[0]]) < bd:
			bd = pl.distance_to(G.level.spots[it[0]]); best = [G.level.spots[it[0]], it[1]]
	return best

func target() -> Array:
	var forest: bool = G.current == "crisforest"
	if not has("cs_job"): return _to("gheorghe", "Gheorghe the forester")
	if mad_seen() < MAD.size():
		var l := []
		for x in MAD:
			if not has("cs_m_" + x): l.append([x, "Somebody acting strangely"])
		return _near(l)
	if not has("cs_denisa"): return _to("denisa", "Denisa the herbalist")
	if not has("cs_wolves"):
		if not forest: return _to("forest", "The forest")
		if not all_freed():
			var l := []
			for a in SNARES:
				if not has("cs_" + a): l.append([a, "A snare"])
			if not has("cs_bear"): l.append(["bandage" if has("cs_bear_down") else "bear", "A snare"])
			return _near(l)
		if not has("cs_muma"): return _to("muma", "The old oak")
		var ap = G.level.alpha_pos()
		if ap != null: return [ap, "The marked alpha"]
		return _to("exit", "The way back to Criș")
	if forest: return _to("exit", "The way back to Criș")
	if not has("cs_done"): return _to("gheorghe", "The feast")
	return _to("road", "The road to Mălâncrav")

func objective() -> String:
	if not has("cs_job"): return "Half the village is acting strangely. Find whoever is in charge."
	if mad_seen() < MAD.size(): return "See what has got into the village (%d/%d)." % [mad_seen(), MAD.size()]
	if not has("cs_denisa"): return "Denisa the herbalist wants a look at it."
	if not has("cs_wolves"):
		if G.current != "crisforest": return "The rot is in the forest, Gheorghe says. Go and find it."
		if not all_freed(): return "Free the forest's animals from the snares (%d/%d)." % [freed() + (1 if has("cs_bear") else 0), SNARES.size() + 1]
		if not has("cs_muma"): return "Somebody is watching you from under the old oak."
		return G.level.hunt_line() if G.level.hunting else "Get back to Criș."
	if not has("cs_done"): return "The rye is burning in the square. There is a feast."
	return "The road leads on to Mălâncrav."

func marker(id: String) -> bool:
	match id:
		"gheorghe": return not has("cs_job") or (has("cs_wolves") and not has("cs_done"))
		"denisa": return mad_seen() == MAD.size() and not has("cs_denisa")
		"muma": return all_freed() and not has("cs_muma")
	return id in MAD and has("cs_job") and not has("cs_m_" + id)

func pending(p: Prop) -> bool:
	if p.kind != "task": return false
	match p.id:
		"fox", "deer", "owl": return not has("cs_" + p.id)
		"bandage": return has("cs_bear_down") and not has("cs_bear")
		"forest": return has("cs_denisa") and not has("cs_wolves")
	return false

func arrive() -> void:
	if has("cs_arrive"): return
	mark("cs_arrive")
	G.start_dialogue("Magda", [
		"(Magda is waiting at the edge of the village, arms crossed, tapping her foot.)",
		"YOU ARE SO SLOW! The whole village had to wait for you. Do you know how long I've been standing here?",
		"Criș. The castle, the church, and everybody in it gone soft in the head. Gheorghe the forester is in the square. HAIDAAA, HAIDA!"])

func talk(id: String) -> bool:
	match id:
		"magda":
			G.start_dialogue("Magda", ["Still here? HAIDA! The forest won't walk to you." if has("cs_job") else "The square! Gheorghe! Go! HAIDAAA!"])
		"gheorghe":
			if not has("cs_job"):
				G.start_dialogue("Gheorghe · Forester", [
					"You're the hunter. Good. Look around you.",
					"Half the village has gone mad in a week. Men talking to trees. My own cousin thinks she's a hen.",
					"It's the rot. The strigoi's rot, the same that turned the wolves. It comes out of the forest, I'd bet my axe on it.",
					"See for yourself. Then we'll go in after it.",
				], func(): mark("cs_job"); Hud.toast("New quest: Muma Pădurii and the Feast"))
			elif mad_seen() < MAD.size():
				G.start_dialogue("Gheorghe · Forester", ["Go on, look at them. Then tell me it isn't the rot."])
			elif not has("cs_denisa"):
				G.start_dialogue("Gheorghe · Forester", ["The rot, see? The rot.", "(You nod. Obviously the rot.)", "Denisa wants a look first. Humour her; she's the only one who still makes sense."])
			elif not has("cs_wolves"):
				G.start_dialogue("Gheorghe · Forester", ["Bread, she says. BREAD. The forest, hunter. West, past the last houses."])
			elif not has("cs_done"):
				G.start_dialogue("Gheorghe · Forester", [
					"So. The bread. (He scratches his neck.) We burned every sheaf of this year's rye. The whole street sobered up, red as beetroot.",
					"My cousin laid an egg in my hat, hunter. A real egg. Nobody can explain that one.",
					"Sit. Eat. Drink. You're the only guest Criș has had in a month who didn't see the church breathing.",
					"(A cup. Another cup. Somebody's uncle. Țuică, then wine, then something green from Denisa's pipe-shelf.)",
					"(For the first time on the road, you don't say no. The lanterns start to swim.)",
					"(The music goes on without you...)",
				], func():
					if G.level.has_method("feast"): G.level.feast())
			else:
				G.start_dialogue("Gheorghe · Forester", ["You drink like a forester. Mălâncrav is down the road, if you can find it."])
		"denisa":
			if mad_seen() < MAD.size():
				G.start_dialogue("Denisa · Herbalist", ["(She chews a stalk of dried mint.) Look at them all first. Then come back and tell me what they ate."])
			elif has("cs_denisa"):
				G.start_dialogue("Denisa · Herbalist", ["Cornul secarei. Black spurs. Burn the rye. I've said it three times; I'll say it at your funeral."])
			else:
				G.start_dialogue("Denisa · Herbalist", [
					"(Denisa tucks a dried mint stalk in her teeth and takes a long look at you, as if you were the next patient.)",
					"A strigoi's rot, Gheorghe says. Hm. Rot doesn't make a woman lay eggs in a hat.",
					"(She breaks a loaf from the baker's shelf and holds it to the lamp. In the crumb, little black spurs.)",
					"Cornul secarei. Rye ergot. The harvest was wet, the rye went black in the ear, and everybody ate it.",
					"Somebody in a big city will one day boil this into a medicine that makes people see God in a cupboard. Here it just makes them talk to geese.",
					"(You shrug. Ergot, sure. But somebody turned the wolves, and that wasn't bread.)",
					"Go and ask in the forest if you don't believe me. Ask politely. She doesn't like hunters.",
				], func(): mark("cs_denisa"); Hud.toast("The forest lies west, past the last houses."))
		"oakman": _mad("oakman", "A man hugging an oak", ["(A grown man has his arms round an oak and is whispering into the bark.)", "...and then I told her it was the goat. The oak won't tell. The oak never tells."])
		"henwoman": _mad("henwoman", "Gheorghe's cousin", ["(A woman squats over a felt hat, clucking, very serious.)", "Bok. BOK. Don't look! A lady needs privacy.", "(When she stands up there is an egg in the hat. You decide not to ask.)"])
		"goose1", "goose2": _mad("goose1", "Two neighbours and a goose", ["(Two neighbours are arguing politics with a goose. The goose is winning.)", "— And the price of fertiliser? Answer that! — HONK. — ...He's got a point, you know."])
		"farmer": _mad("farmer", "A farmer and a scarecrow", ["(A farmer bows deeply to a scarecrow, hat in hand.)", "Your Excellency. The tithe will be late again. Forgive us. (To you:) Bow, you oaf! He's the mayor!"])
		"towerkid": _mad("towerkid", "A child by the church", ["(A small boy is staring up at the church tower.)", "It's breathing. In... and out. In... and out. Can you see it? It's got a cold."])
		"muma":
			if G.level.has_method("meet_muma"): G.level.meet_muma()
		"feaster":
			G.start_dialogue("A villager", ["(Embarrassed.) I bowed to a scarecrow for three days. Don't tell my wife. She was the hen."])
		_: return false
	return true

func _mad(id: String, who: String, lines: Array) -> void:
	var first := not has("cs_m_" + id)
	if not has("cs_job"):
		G.start_dialogue(who, lines)
		return
	mark("cs_m_" + id)
	G.start_dialogue(who, lines, func():
		if not first: return
		var n := mad_seen()
		Hud.toast("Madness %d/%d" % [n, MAD.size()] if n < MAD.size() else "The rot, surely. Gheorghe was right. Still, Denisa wanted a look."))

func use(p: Prop) -> void:
	var L = G.level
	match p.id:
		"forest":
			if not has("cs_denisa"): G.start_dialogue("The forest", ["The old beech wood west of Criș. The village has business with you first."])
			else: Loader.goto_level("crisforest")
		"fox", "deer", "owl":
			if not has("cs_" + p.id): L.free_animal(p)
		"bear": L.wake_bear()
		"bandage":
			if has("cs_bear_down") and not has("cs_bear"): L.bandage_bear()
		"exit": L.leave()
		"road":
			if not has("cs_done"): G.start_dialogue("The road south", ["Not while Criș is still talking to its geese."])
			else: Loader.goto_level("malancrav")
		"rye":
			G.start_dialogue("The rye", ["The bad rye, burning. It smells of bread and of something sour underneath." if has("cs_wolves") else "This year's rye, stacked by the barns. Black specks in the ears."])
