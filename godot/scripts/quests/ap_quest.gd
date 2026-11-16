## "Sâmedru's Fire", Apold. The dead have come home for Moșii and found empty tables. Look round the village,
## prepare the offerings (colivă, colaci, wine, candles on three graves), then keep the hungry dead off the
## table through the night. They cannot be killed, only knocked back; the Sâmedru fire on the hill slows them.
class_name ApQuest
extends RefCounted

const CLUES := ["chairs", "footprints", "stubs", "woodpile"]

static func has(f: String) -> bool: return G.side_has(f)
static func mark(f: String) -> void: G.side_add(f)

static func clues_found() -> int:
	var n := 0
	for c in CLUES:
		if has("ap_c_" + c): n += 1
	return n

static func graves() -> int:
	var n := 0
	for i in 3:
		if has("ap_grave%d" % i): n += 1
	return n

static func offerings() -> bool:
	return has("ap_coliva") and has("ap_colaci") and has("ap_wine") and graves() == 3

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
	if has("ap_pub") and not has("ap_done"): return []
	if not has("ap_job"): return _to("dumitru", "Old Dumitru")
	if clues_found() < CLUES.size():
		var l := []
		for c in CLUES:
			if not has("ap_c_" + c): l.append([c, "Something odd"])
		return _near(l)
	if not offerings():
		var l := []
		if not has("ap_coliva"): l.append(["granny", "The grandmother"])
		if not has("ap_colaci"): l.append(["baker", "The baker's wife"])
		if not has("ap_wine"): l.append(["cellar", "The cellar"])
		else:
			for i in 3:
				if not has("ap_grave%d" % i): l.append(["grave%d" % i, "A grave"])
		return _near(l)
	if not has("ap_night"): return _to("dumitru", "Old Dumitru")
	if not has("ap_dawn"):
		var b: String = G.level.get("between") if G.level.get("between") != null else ""
		if b != "": return _to(b, "The pot" if b == "pot" else "The graves")
		if not has("ap_fire"): return _to("fire", "The woodpile on the hill")
		return _to("table", "The table")
	if not has("ap_done"): return _to("pub", "The pub")
	return _to("road", "The road west")

func objective() -> String:
	if not has("ap_job"): return "Plates rattle in empty houses. Find somebody awake."
	if clues_found() < CLUES.size(): return "Look round the village (%d/%d)." % [clues_found(), CLUES.size()]
	if not offerings():
		var need := PackedStringArray()
		if not has("ap_coliva"): need.append("colivă")
		if not has("ap_colaci"): need.append("colaci")
		if not has("ap_wine"): need.append("wine and candles")
		elif graves() < 3: need.append("candles on the graves (%d/3)" % graves())
		return "Prepare the offerings: " + ", ".join(need) + "."
	if not has("ap_night"): return "Tell Dumitru the offerings are ready."
	if not has("ap_dawn"): return G.level.night_line() if G.level.has_method("night_line") else "Hold the dead off until the ritual is done."
	if not has("ap_done"): return "Dawn. Somebody is boasting in the pub."
	return "The road west leads to Criș."

func marker(id: String) -> bool:
	match id:
		"dumitru": return not has("ap_job") or (offerings() and not has("ap_night"))
		"granny": return clues_found() == CLUES.size() and not has("ap_coliva")
		"baker": return clues_found() == CLUES.size() and not has("ap_colaci")
	return false

func pending(p: Prop) -> bool:
	if p.kind == "clue": return has("ap_job") and not has("ap_c_" + p.id)
	if p.id.begins_with("grave"): return has("ap_wine") and not has("ap_" + p.id)
	match p.id:
		"cellar": return clues_found() == CLUES.size() and not has("ap_wine")
		"fire": return has("ap_night") and not has("ap_fire")
		"pot", "candles": return G.level.get("between") == p.id
	return false

func arrive() -> void:
	if has("ap_arrive"): return
	mark("ap_arrive")
	G.start_dialogue("Apold", [
		"Apold, Trappold to the Saxons, in its valley: the fortified church, the long farmyards, the brook.",
		"It is the end of October. Every gate is shut before dusk, and somewhere inside a house a plate is rattling on a table nobody sits at."])

func talk(id: String) -> bool:
	match id:
		"dumitru":
			if not has("ap_job"):
				G.start_dialogue("Old Dumitru", [
					"(An old shepherd with a crook, named after the saint whose day it is.) You're the one who came down from the mountains? Then you know what Sâmedru is. The end of the shepherds' summer.",
					"And Moșii. The dead come home in autumn, to be remembered. You set a table, you give them colivă and bread and wine and candles, and they go back content.",
					"Nobody has done it here in years. The young went down to the towns and the wars, the old forgot. So the dead came home this year and found empty tables.",
					"Now they are hungry and angry, and every night they come for whatever we have. You can't kill what's already dead. But you might help us do it properly.",
				], func(): mark("ap_job"); Hud.toast("New quest: Sâmedru's Fire"))
			elif offerings() and not has("ap_night"):
				G.start_dialogue("Old Dumitru", [
					"Colivă, colaci, wine, candles on every grave. Good. Then tonight we do it properly.",
					"We set the table by the graveyard and say the names. They will come for the food before we're done; they always do. Keep them off it.",
					"You can't hurt them. Knock them back, that's all. And if you light the Sâmedru fire on the hill, the light will slow them.",
				], func():
					mark("ap_night")
					if G.level.has_method("begin_night"): G.level.begin_night())
			elif has("ap_dawn"):
				G.start_dialogue("Old Dumitru", ["They ate. They complained. They went. That's how it should be."])
			else:
				G.start_dialogue("Old Dumitru", ["Look around first. Then the offerings: the grandmother does the colivă, the baker's wife the colaci, the wine is in the old cellar."])
		"granny":
			if has("ap_coliva"): G.start_dialogue("The grandmother", ["Don't touch the colivă. It's for them."])
			elif clues_found() < CLUES.size(): G.start_dialogue("The grandmother", ["Go and look at the village, then come back. I'm not boiling wheat for nothing."])
			else:
				G.start_dialogue("The grandmother", [
					"Colivă? Finally somebody asks. Sit. No, stir.",
					"(You stir the wheat for an hour while she cracks walnuts and tells you about every dead person in the village, in detail.)",
					"Sugar on top, and a cross in cinnamon. There. My mother made it sweeter. They'll say so, you'll see.",
				], func(): mark("ap_coliva"); Hud.toast("Colivă"))
		"baker":
			if has("ap_colaci"): G.start_dialogue("The baker's wife", ["Colaci for the dead, bread for the living. Separate baskets."])
			elif clues_found() < CLUES.size(): G.start_dialogue("The baker's wife", ["The oven's cold. Talk to Dumitru, look around, then come back."])
			else:
				G.start_dialogue("The baker's wife", [
					"Colaci. Braided, round, for the souls. My hands know it even if my head forgot.",
					"(You knead until your arms ache. She braids, you carry the trays to the oven.)",
					"Smell that. Even the dead will stop to sniff.",
				], func(): mark("ap_colaci"); Hud.toast("Colaci"))
		"costache":
			G.start_dialogue("Moș Costache", ["(He groans from the ground.) My head... I've got a bump, a cucui... buy me a țuică and the pain will go away."])
		"pubcostache", "pubghost": pass
		_: return false
	return true

func use(p: Prop) -> void:
	var L = G.level
	if p.kind == "clue":
		if not has("ap_job"):
			G.start_dialogue("Apold", ["Everyone has shut their gates. Find someone awake."])
			return
		var first := not has("ap_c_" + p.id)
		mark("ap_c_" + p.id)
		var after := func():
			if first: Hud.toast("Clue %d/%d" % [clues_found(), CLUES.size()] + (". Prepare the offerings." if clues_found() == CLUES.size() else ""))
		match p.id:
			"chairs": G.start_dialogue("Empty chairs", ["A table laid for six in a yard, every chair pulled out, every plate licked clean.", "Nobody in this house has eaten outdoors since summer."], after)
			"footprints": G.start_dialogue("Footprints", ["Wet bare footprints on a dry doorstep, coming in. None going out.", "They smell of cold earth."], after)
			"stubs": G.start_dialogue("Candle stubs", ["On the old graves, candle stubs burned right down. Years old; nobody has lit a new one."], after)
			_: G.start_dialogue("The woodpile", ["On the hill above the village, a great pile of wood for the Sâmedru fire. Stacked years ago, never lit, half of it rotten."], after)
		return
	if p.id.begins_with("grave"):
		if not has("ap_wine"): G.start_dialogue("A grave", ["An old grave, its candle stubs long burned out."])
		elif not has("ap_" + p.id):
			mark("ap_" + p.id); p.used = true
			L.candles_on(int(p.id.substr(5)))
			Audio.sfx("blip", -6.0, 1.1)
			Hud.toast("Two candles on the grave (%d/3)" % graves())
		return
	match p.id:
		"cellar":
			if clues_found() < CLUES.size(): G.start_dialogue("The cellar", ["A cellar door under the church hill."])
			elif not has("ap_wine"):
				mark("ap_wine")
				G.start_dialogue("The cellar", ["Dusty bottles of red, and a box of beeswax candles. You take a bottle and six candles: two for each of three graves."], func(): Hud.toast("Wine and candles. Two candles on each of three graves."))
		"fire":
			if not has("ap_night"): G.start_dialogue("The woodpile", ["The Sâmedru fire. Not yet; it's lit on the night."])
			elif not has("ap_fire"): L.light_fire()
		"pot", "candles": L.help(p.id)
		"road":
			if not has("ap_done"): G.start_dialogue("The road west", ["Not while the dead are still hungry."])
			else: Loader.goto_level("cris")
