## "The Brothers and the Iele", Richiș. Seven Iele dance on the ridge road out of season; Toader the călușar
## has been "lovit de Iele" for years. The four protective plants calm him for a moment, and then his brother
## Ilie has to play the nai again, on the ridge, with the hunter standing in the ring.
class_name RcQuest
extends RefCounted

const HERBS := ["wormwood", "walnut", "garlic", "basil"]

static var ridge_gate := Vector2.ZERO
static var forest_gate := Vector2.ZERO

static func has(f: String) -> bool: return G.side_has(f)
static func mark(f: String) -> void: G.side_add(f)

static func herbs_have() -> int:
	var n := 0
	for h in HERBS:
		if has("rc_" + h): n += 1
	return n

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
	if G.current == "ieleridge": return []
	var forest: bool = G.current == "richisforest"
	if not has("rc_job"): return _to("ilie", "Moș Ilie")
	if not has("rc_o_ridge") or not has("rc_o_toader"):
		var l := []
		if not has("rc_o_ridge"): l.append(["ridge", "The ridge path"])
		if not has("rc_o_toader"): l.append(["toader", "Toader"])
		return _near(l)
	if herbs_have() < HERBS.size():
		var l := []
		if forest:
			if not has("rc_wormwood"): l.append(["wormwood", "Wormwood"])
			if not has("rc_walnut"): l.append(["walnut", "Walnut leaves"])
			return _to("exit", "Back to Richiș") if l.is_empty() else _near(l)
		if not has("rc_wormwood") or not has("rc_walnut"): l.append(["forest", "The forest"])
		if not has("rc_garlic"): l.append(["cellar", "The cellar"])
		if not has("rc_basil"): l.append(["denisa", "Denisa"])
		return _near(l)
	if forest: return _to("exit", "Back to Richiș")
	if not has("rc_brew"): return _to("denisa", "Denisa")
	if not has("rc_calm"): return _to("toader", "Toader")
	if not has("rc_agree"): return _to("ilie", "Moș Ilie")
	if not has("rc_iele"): return _to("ridge", "The ridge clearing")
	if not has("rc_done"): return _to("ilie", "The brothers")
	return _to("ridge", "The road to Biertan")

func objective() -> String:
	if G.current == "ieleridge": return G.level.line()
	if not has("rc_arrive"): return ""
	if not has("rc_job"): return "The road to Biertan runs over the ridge. Somebody here knows why it's shut."
	if not has("rc_o_ridge") or not has("rc_o_toader"): return "See the ridge path, and Toader, for yourself."
	if herbs_have() < HERBS.size():
		var need := PackedStringArray()
		if not has("rc_wormwood"): need.append("wormwood")
		if not has("rc_walnut"): need.append("walnut leaves")
		if not has("rc_garlic"): need.append("garlic")
		if not has("rc_basil"): need.append("basil")
		return "Gather the protective plants: " + ", ".join(need) + "."
	if not has("rc_brew"): return "Take the plants to Denisa for the decoction."
	if not has("rc_calm"): return "Give Toader the decoction."
	if not has("rc_agree"): return "Only music can pull the spell out. Ask Moș Ilie to play."
	if not has("rc_iele"): return "Ilie is waiting at the ridge clearing with his nai."
	if not has("rc_done"): return "The ridge is quiet. Go and see the brothers."
	return "The ridge path is open. Biertan lies beyond it."

func marker(id: String) -> bool:
	match id:
		"ilie": return not has("rc_job") or (has("rc_calm") and not has("rc_agree")) or (has("rc_iele") and not has("rc_done"))
		"denisa": return (herbs_have() == HERBS.size() and not has("rc_brew")) or (has("rc_job") and not has("rc_basil"))
		"toader": return has("rc_job") and (not has("rc_o_toader") or (has("rc_brew") and not has("rc_calm")))
	return false

func pending(p: Prop) -> bool:
	if p.kind != "task": return false
	match p.id:
		"ridge": return has("rc_job") and (not has("rc_o_ridge") or (has("rc_agree") and not has("rc_iele")))
		"cellar": return has("rc_job") and not has("rc_garlic")
		"forest": return has("rc_job") and not (has("rc_wormwood") and has("rc_walnut"))
		"wormwood", "walnut": return not has("rc_" + p.id)
	return false

func arrive() -> void:
	if has("rc_arrive"): return
	mark("rc_arrive")
	G.start_dialogue("Richiș", [
		"Richiș, Rätsch to the Saxons: the hall church with the green men carved in its stone, the long street in the valley.",
		"Frost on the grass, in October. Up on the ridge, where the road goes on to Biertan, something white is moving. Dancing."])

func talk(id: String) -> bool:
	match id:
		"ilie":
			if G.current == "ieleridge": return true
			if not has("rc_job"):
				G.start_dialogue("Moș Ilie", [
					"(An old man on a bench, a nai hanging on the wall behind him, unplayed and dusty.)",
					"The ridge? Shut. Seven of them dance on it every night, in the cold, when they should be asleep till summer. The Iele. Dumnealor. The fair ones.",
					"Cross it in the dark and they strike you. Your legs go, or your tongue, or your wits, for years. Lovit de Iele.",
					"It's my fault. Years ago I played the nai at the edge of the village, and they came. My brother Toader was a călușar. He went out to drive them off with his stick and his bells.",
					"They took his wits. He's been dancing ever since, out in the fields. Laughing at the wind.",
					"(He looks at the nai.) I haven't played since. I won't. The music calls them.",
				], func(): mark("rc_job"); Hud.toast("New quest: The Brothers and the Iele"))
			elif has("rc_iele") and not has("rc_done"):
				if G.level.has_method("brothers"): G.level.brothers()
			elif has("rc_calm") and not has("rc_agree"):
				G.start_dialogue("Moș Ilie", [
					"He knew me. For a moment, he knew me. (His hands are shaking.)",
					"And then he went. The plants can't do it alone. You're right. It has to be the music.",
					"(He takes the nai down from the wall and blows the dust off it.) At the clearing on the ridge, then. They will come. Be ready.",
				], func(): mark("rc_agree"); Hud.toast("Go to the ridge clearing. Ilie will play."))
			elif has("rc_done"):
				G.start_dialogue("Moș Ilie", ["(He is playing, quietly, for his brother. Nothing comes. Nothing at all.)"])
			else:
				G.start_dialogue("Moș Ilie", ["Wormwood, garlic, basil, walnut leaves. My mother hung them in every doorway in June. Maybe it's enough. I don't think it is."])
		"petrea":
			G.start_dialogue("Petrea", ["Uncle Toader asked me my name. Three times. He's never asked before." if has("rc_done") else "(A boy with very old eyes.) I was born in a caul, so I see them even in the day. There are seven. One of them is looking at you."])
		"denisa":
			if not has("rc_job"):
				G.start_dialogue("Denisa · Herbalist", ["(Denisa, from Criș, puffing her pipe on the step of the house where she's lodging.) Fancy meeting you sober. What's wrong with this one, then?"])
			elif not has("rc_basil"):
				G.start_dialogue("Denisa · Herbalist", [
					"Iele? Hm. Out of season, in the frost. That's your rot again, for once.",
					"The old women hang wormwood, garlic, basil and walnut leaves against them. Here, basil. I never travel without it. (She hands you a pot.)",
					"Bring me the rest and I'll boil you something that tastes of all four and of nothing good.",
				], func(): mark("rc_basil"); Hud.toast("Basil"))
			elif herbs_have() < HERBS.size():
				G.start_dialogue("Denisa · Herbalist", ["Wormwood and walnut from the forest, garlic from somebody's cellar. I'll wait. I'm good at waiting."])
			elif not has("rc_brew"):
				G.start_dialogue("Denisa · Herbalist", [
					"(Into the pot: the wormwood, bitter; the walnut leaves; four cloves of garlic; the basil.)",
					"This isn't in any book. My grandmother would slap me. Stir.",
					"(It smells of a church and a kitchen fighting.) Give it to the brother. A cup. All of it.",
				], func(): mark("rc_brew"); Hud.toast("The decoction. Take it to Toader."))
			else:
				G.start_dialogue("Denisa · Herbalist", ["Plants calm. Music cures. That's not mine, that's the călușari's. Go."])
		"toader":
			if not has("rc_job"):
				G.start_dialogue("Toader", ["(A man dancing alone at the edge of a field, bells on his legs, laughing at the wind.) Hop! Hop! Can you hear them? They're singing!"])
			elif not has("rc_o_toader"):
				mark("rc_o_toader")
				G.start_dialogue("Toader", [
					"(Toader, Ilie's brother. A călușar's costume gone grey with years, bells on his shins. He dances a step, stops, dances it again.)",
					"Seven sisters, seven skirts, seven, seven, seven. Hop! (He laughs at the wind as if it told a joke.)",
					"(His eyes look past you, at the ridge.)",
				], func(): Hud.toast("Protective plants, then. Ask around." if has("rc_o_ridge") else "The ridge path, next."))
			elif has("rc_brew") and not has("rc_calm"):
				G.start_dialogue("Toader", [
					"(He drinks it in one go, makes a terrible face, and stops dancing.)",
					"...Ilie? Where's Ilie? Is he still cross about the goat?",
					"(For a moment, a man is standing there. Then the wind moves on the ridge, and his foot starts tapping again.) Hop... hop...",
				], func(): mark("rc_calm"); Hud.toast("It didn't last. Tell Ilie."))
			elif has("rc_iele"): return false
			else: G.start_dialogue("Toader", ["Hop! Seven! (He spins.)"])
		_: return false
	return true

func use(p: Prop) -> void:
	match p.id:
		"ridge":
			if has("rc_done"): Loader.goto_level("biertanfort")
			elif has("rc_agree") and not has("rc_iele"): Loader.goto_level("ieleridge")
			elif has("rc_iele"): G.start_dialogue("The ridge path", ["Open, and frosty, and empty. Go and see the brothers first."])
			else:
				var first := not has("rc_o_ridge")
				if has("rc_job"): mark("rc_o_ridge")
				G.start_dialogue("The ridge path", [
					"(A barrier of poles across the road, hung with white ribbons and garlic. Beyond it, on the ridge, seven pale figures are dancing in a ring in the frost.)",
					"(They are beautiful, and you can't look at them for long. Your legs feel heavy just watching.)",
				], func():
					if first and has("rc_job"): Hud.toast("Protective plants, then. Ask around." if has("rc_o_toader") else "Now Toader."))
		"cellar":
			if not has("rc_job"): G.start_dialogue("A cellar", ["Somebody's cellar. Locked."])
			elif not has("rc_garlic"):
				mark("rc_garlic")
				G.start_dialogue("The cellar", ["(Under a widow's house: barrels, a smell of last year's cabbage, and garlic braided on every beam. She says take two braids and say a word for her husband.)"], func(): Hud.toast("Garlic"))
		"forest":
			if not has("rc_job"): G.start_dialogue("The forest", ["The wood north of the village. No reason to go in yet."])
			else: Loader.goto_level("richisforest")
		"wormwood", "walnut": G.level.pick(p)
		"exit": G.level.leave()
