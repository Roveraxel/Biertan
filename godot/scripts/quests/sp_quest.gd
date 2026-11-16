## "The Three Churches", Șapartoc. A light walks between three churches at night and the village has emptied.
## Watch, light the five lamps along its path in order, meet Ana (walled in to guard "the holy place", and now
## guarding three), then give each church new work so they stand on their own: a canteen, a concert hall, a mass.
class_name SpQuest
extends RefCounted

const LAMPS := 5
const CLUES := ["light", "door"]

static func has(f: String) -> bool: return G.side_has(f)
static func mark(f: String) -> void: G.side_add(f)

static func lamps_lit() -> int:
	var n := 0
	for i in LAMPS:
		if has("sp_lamp%d" % i): n += 1
	return n

static func clues_found() -> int:
	var n := 0
	for c in CLUES:
		if has("sp_c_" + c): n += 1
	return n

static func ready_to_summon() -> bool: return clues_found() == CLUES.size()

static func population() -> int:
	var p := 27
	if has("sp_letters"): p += 6
	if has("sp_canteen"): p += 14
	if has("sp_concert"): p += 11
	if has("sp_mass"): p += 19
	return p

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
	if not has("sp_job"): return _to("radu", "Radu's inn")
	if not ready_to_summon():
		var l := []
		for c in CLUES:
			if not has("sp_c_" + c): l.append([c, "Something odd"])
		return _near(l)
	if not has("sp_ana"): return _to("lamp%d" % lamps_lit(), "Lamp %d of %d" % [lamps_lit() + 1, LAMPS])
	if not has("sp_plan"): return _to("radu", "Radu")
	if not has("sp_materials"): return _to("materials", "Planks and tools")
	if not has("sp_letters"): return _to("horia", "Mayor Horia")
	var todo := []
	if not has("sp_canteen"): todo.append(["canteen", "The Catholic church"])
	if not has("sp_concert"): todo.append(["concert", "The Reformed church"])
	if not has("sp_priest"): todo.append(["traveller", "The sheep pasture"])
	elif not has("sp_mass"): todo.append(["mass", "The Orthodox church"])
	if not todo.is_empty(): return _near(todo)
	if not has("sp_done"): return _to("ana", "Ana")
	return _to("road", "The road south")

func objective() -> String:
	var pop := "  (Șapartoc: %d souls)" % population()
	if not has("sp_job"): return "An almost empty village. Find somebody to talk to." + pop
	if not ready_to_summon(): return "Watch the churches after dark (%d/%d)." % [clues_found(), CLUES.size()] + pop
	if not has("sp_ana"): return "Light the lamps on the path between the churches, in order (%d/%d)." % [lamps_lit(), LAMPS] + pop
	if not has("sp_plan"): return "Tell Radu what the ghost said." + pop
	if not has("sp_materials"): return "Gather planks and tools from the old barn." + pop
	if not has("sp_letters"): return "Write to the city for help, and get Mayor Horia to sign." + pop
	var need := PackedStringArray()
	if not has("sp_canteen"): need.append("a canteen in the Catholic church")
	if not has("sp_concert"): need.append("a concert hall in the Reformed church")
	if not has("sp_priest"): need.append("a priest for the Orthodox church")
	elif not has("sp_mass"): need.append("the first mass in the Orthodox church")
	if need.size() > 0: return "Give the churches new work: " + ", ".join(need) + "." + pop
	if not has("sp_done"): return "Go and tell Ana." + pop
	return "The road south leads to Apold." + pop

func marker(id: String) -> bool:
	match id:
		"radu": return not has("sp_job") or (has("sp_ana") and not has("sp_plan"))
		"horia": return has("sp_materials") and not has("sp_letters")
		"traveller": return has("sp_letters") and not has("sp_priest")
		"ana": return has("sp_canteen") and has("sp_concert") and has("sp_mass") and not has("sp_done")
	return false

func pending(p: Prop) -> bool:
	if p.kind == "clue": return has("sp_job") and not has("sp_c_" + p.id)
	if p.id.begins_with("lamp"): return ready_to_summon() and not has("sp_ana") and not has("sp_" + p.id)
	match p.id:
		"materials": return has("sp_plan") and not has("sp_materials")
		"canteen": return has("sp_letters") and not has("sp_canteen")
		"concert": return has("sp_letters") and not has("sp_concert")
		"mass": return has("sp_priest") and not has("sp_mass")
	return false

func arrive() -> void:
	if has("sp_arrive"): return
	mark("sp_arrive")
	G.start_dialogue("Șapartoc", [
		"Șapartoc: three church towers on one little hill, and around them grass growing out of the roofs.",
		"Most of the houses are shut, their windows nailed over. One blue house has geraniums on the prispă and smoke from the chimney."])

func talk(id: String) -> bool:
	match id:
		"radu":
			if not has("sp_job"):
				G.start_dialogue("Radu, innkeeper", [
					"A guest! On foot! Sit, sit. I'm Radu. Nine years ago I left Cluj for the quiet life, and look, I got it.",
					"When I came there were eight hundred people here. Now there are twenty-seven, and two of them are goats on the register by mistake.",
					"It's the churches. Three of them: Orthodox, Catholic, Reformed. Every night a light walks between them, and the doors bang like somebody's angry.",
					"People said the village is cursed and left. I don't believe in curses. I believe in something being wrong. Will you look?",
				], func(): mark("sp_job"); Hud.toast("New quest: The Three Churches"))
			elif has("sp_ana") and not has("sp_plan"):
				G.start_dialogue("Radu, innkeeper", [
					"A woman in the wall? Guarding all three? Poor soul. No wonder she bangs the doors.",
					"Then let's take the weight off her. A church that's used doesn't fall down; a church that's empty does.",
					"The Catholic one: a canteen. Half the valley is hungry. The Reformed one has the best echo in Transylvania: concerts. And the Orthodox one stays a church, for everybody.",
					"We need planks and tools from the old barn, and letters to the city so families come. Horia, the mayor, has to sign. And we need a priest. Good luck with that.",
				], func(): mark("sp_plan"); Hud.toast("Give the three churches new work."))
			else:
				G.start_dialogue("Radu, innkeeper", ["%d people! I'll need a bigger pot." % population() if has("sp_done") else "Watch the churches after dark. That's when it happens."])
		"horia":
			if not has("sp_materials"): G.start_dialogue("Horia, mayor", ["Mayor of twenty-seven people. I sign things. Nobody has given me anything to sign in two years."])
			elif has("sp_letters"): G.start_dialogue("Horia, mayor", ["I've written to my cousin in Sighișoara as well. He has six children and no patience. Perfect."])
			else:
				G.start_dialogue("Horia, mayor", [
					"Letters? To the city? 'Free land, free roof, a canteen and music on Sundays.' Hm.",
					"(He reads it twice, signs with a flourish, and stamps it so hard the table jumps.)",
					"There. If that doesn't bring them, nothing will.",
				], func(): mark("sp_letters"); Hud.toast("Letters signed and sent. The first families are coming."))
		"traveller": _priest()
		"ana":
			if not has("sp_ana"): return true
			if has("sp_canteen") and has("sp_concert") and has("sp_mass") and not has("sp_done"):
				G.start_dialogue("Ana", [
					"(Ana floats out of the wall of the Orthodox church. She is smiling.)",
					"Soup in one, fiddles in the other, and that drunk priest in here, singing louder than the whole choir. None of them will fall down now. They are full.",
					"I am going to stay, though. I like it here. There is a little room in this wall that Manole forgot. I've had a hammock put in.",
					"(She hands you a lantern. Its light is pale and cold and does not flicker.) For you. It will find its way in the dark.",
					"Finally, some peace. Close the door on your way out.",
				], func():
					mark("sp_done"); mark("token_ana_lantern")
					G.player.coins += 20
					Audio.sfx("bell", -10.0, 1.2)
					if G.level.has_method("ana_retires"): G.level.ana_retires()
					Hud.toast("Quest complete: The Three Churches.  Șapartoc: %d souls.  Token: Ana's lantern" % population()))
			elif has("sp_done"):
				G.start_dialogue("Ana", ["(From inside the wall, the sound of a page turning.) The door. Please."])
			else:
				G.start_dialogue("Ana", ["Three churches, and only one of me. Fill them, and they'll stand on their own."])
		_: return false
	return true

func _priest() -> void:
	if has("sp_priest"):
		G.start_dialogue("Father Bálint", ["Mass first, wine after. I am a man of principle."])
		return
	if not has("sp_letters"):
		G.start_dialogue("A man among the sheep", ["(A man in a priest's cassock is asleep among the sheep, snoring, an empty jug under his arm.)"])
		return
	G.start_choice("A man among the sheep", [
		"(He opens one eye.) Bálint. Priest. Formerly of Odorhei, currently of this field. The sheep don't judge.",
		"A church? Without a priest? And you want me? Hm. And what does a church pay these days?",
	], [
		"\"Wine. As much as you like, after mass.\"",
		"\"A roof, a warm bed, and Radu's cooking.\"",
		"\"Nothing. God's work is its own reward.\"",
	], func(pick: int):
		if pick == 2:
			G.start_dialogue("Father Bálint", ["(He closes his eye again.) Then God can do it."])
			return
		G.start_dialogue("Father Bálint", [
			"(He sits up at once.) Wine. After. You drive a hard bargain, my son. Agreed.",
			"(He brushes the straw off his cassock and walks, mostly straight, toward the Orthodox church.)",
		] if pick == 0 else [
			"A bed. And the cooking. ...And a little wine?",
			"(You nod. He gets up, brushes the straw off, and walks, mostly straight, toward the Orthodox church.)",
		], func():
			mark("sp_priest")
			if G.level.has_method("priest_to_church"): G.level.priest_to_church()
			Hud.toast("Father Bálint goes to the Orthodox church.")))

func use(p: Prop) -> void:
	var L = G.level
	if p.kind == "clue":
		if not has("sp_job"):
			G.start_dialogue("Șapartoc", ["Nobody to ask yet but the wind."])
			return
		var first := not has("sp_c_" + p.id)
		mark("sp_c_" + p.id)
		var after := func():
			if first: Hud.toast("Clue %d/%d" % [clues_found(), CLUES.size()] + (". Light the lamps along the path, in order." if ready_to_summon() else ""))
		if p.id == "light":
			G.start_dialogue("The light", ["A pale light moves along the path between the churches, from one door to the next, and back. Nobody carries it.", "Where it passes, the old lamp brackets on their posts give a faint ring, like a struck glass."], after)
		else:
			G.start_dialogue("The door", ["The door of the Reformed church slams shut on its own. A moment later, across the hill, the Catholic one. Then the Orthodox.", "Not a draught. More like somebody who is very, very tired of opening doors."], after)
		return
	if p.id.begins_with("lamp"):
		var i := int(p.id.substr(4))
		if not ready_to_summon() or has("sp_ana"):
			G.start_dialogue("Lamp", ["An old iron lamp bracket on a post. There is still oil in it."])
			return
		if has("sp_lamp%d" % i): return
		if i != lamps_lit():
			for k in LAMPS: G.side.erase("sp_lamp%d" % k)
			L.lamps_out()
			G.start_dialogue("Lamp", ["The flame catches, gutters, and dies. All along the path the other lamps go out with it.", "The light walked from the Catholic church, past the Orthodox, to the Reformed. Follow its way."])
			return
		mark("sp_lamp%d" % i)
		L.light_lamp(i)
		Audio.sfx("blip", -6.0, 0.8 + i * 0.1)
		if lamps_lit() == LAMPS: L.summon()
		return
	match p.id:
		"materials":
			if not has("sp_plan"): G.start_dialogue("Old barn", ["Planks, a saw, nails in a bucket, a trestle table missing a leg."])
			elif not has("sp_materials"):
				mark("sp_materials")
				Audio.sfx("blip", -4.0, 0.7)
				G.start_dialogue("Old barn", ["You load a handcart with planks, tools, trestles and a sack of nails, and push it up the hill.", "Now somebody has to pay for the rest. Time to write to the city."])
		"canteen":
			if not has("sp_letters"): G.start_dialogue("The Catholic church", ["Empty pews and swallows in the rafters."])
			elif has("sp_canteen"): G.start_dialogue("The canteen", ["Long tables, a pot that never empties, and a queue out the door."])
			else:
				mark("sp_canteen"); L.canteen()
				G.start_dialogue("The Catholic church", ["You and Radu move the pews against the walls and set up the trestle tables. Radu lights the fire under the big pot.", "By evening the first families from the valley are eating cabbage soup under the painted saints.", "Somewhere, a door that had been banging stops."])
		"concert":
			if not has("sp_letters"): G.start_dialogue("The Reformed church", ["Plain white walls. Your footsteps come back to you three times."])
			elif has("sp_concert"): G.start_dialogue("The concert hall", ["Somebody is tuning a fiddle. Somebody else is telling him he's doing it wrong."])
			else:
				mark("sp_concert"); L.concert()
				G.start_dialogue("The Reformed church", ["You set out music stands in front of the old pulpit. Word travels fast: a fiddler from Albești arrives with his brother and a cimbalom on a cart.", "The first tune fills the church to the roof. Outside, a door that had been banging stops."])
		"mass":
			if not has("sp_priest"): G.start_dialogue("The Orthodox church", ["Icons, candle stubs, and nobody to say the mass."])
			elif not has("sp_mass"):
				mark("sp_mass")
				G.start_dialogue("The Orthodox church", ["Father Bálint says the mass in Romanian, Hungarian and something that might be Latin. Orthodox, Catholic and Reformed families stand shoulder to shoulder and nobody minds.", "Afterwards he collects his wine with great dignity.", "The last door stops banging."])
		"road":
			if not has("sp_done"): G.start_dialogue("The road south", ["Not with a ghost still banging doors."])
			else: Loader.goto_level("apold")
