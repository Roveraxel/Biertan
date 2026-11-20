## "The Friday Curse", Criț. Floarea washed her trousseau on Saint Friday's day and her hands will not heal.
## Look: the laundry, the lye, the ribbons, the old path. Ask the three old women. Fill the offering basket
## (fruit, poppies from the old graveyard, wild roses), lay it at Sfânta Vineri's shrine, and talk the mother round.
class_name CritQuest
extends RefCounted

const CLUES := ["laundry", "lye", "ribbons", "path"]
const WOMEN := ["baba_ana", "baba_safta", "baba_veta"]

static var forest_gate := Vector2.ZERO   # the hunter comes back out of the forest here

static func has(f: String) -> bool: return G.side_has(f)
static func mark(f: String) -> void: G.side_add(f)

static func clues_found() -> int:
	var n := 0
	for c in CLUES:
		if has("cr_c_" + c): n += 1
	return n

static func knots() -> int:
	return int(has("cr_knot1")) + int(has("cr_knot2")) + int(has("cr_knot3"))

static func asked() -> int:
	var n := 0
	for w in WOMEN:
		if has("cr_b_" + w): n += 1
	return n

static func gathered() -> bool:
	return has("cr_fruit") and has("cr_poppy") and has("cr_roses")

func _to(id: String, label: String) -> Array:
	return [G.level.spots[id], label] if G.level.spots.has(id) else []

func target() -> Array:
	var forest: bool = G.current == "critforest"
	if not has("cr_job"): return _to("exit", "Back to Criț") if forest else _to("floarea", "Floarea")
	if not has("cr_basket"):
		if forest: return _to("exit", "Back to Criț")
		var pl: Vector2 = G.player.pos
		var best := []; var bd := INF
		var spots: Dictionary = G.level.spots
		for c in CLUES:
			if not has("cr_c_" + c) and spots.has(c) and pl.distance_to(spots[c]) < bd:
				bd = pl.distance_to(spots[c]); best = [spots[c], "Something odd"]
		for w in WOMEN:
			if not has("cr_b_" + w) and spots.has(w) and pl.distance_to(spots[w]) < bd:
				bd = pl.distance_to(spots[w]); best = [spots[w], "An old woman"]
		return best
	if not has("cr_shrine"):
		if forest:
			if not has("cr_roses"): return _to("roses", "Wild roses")
			return _to("shrine", "The shrine") if gathered() else _to("exit", "Back to Criț")
		if not has("cr_fruit"): return _to("apples", "The mother's garden")
		if not has("cr_poppy"): return _to("poppies", "The old cemetery")
		return _to("forest", "The forest path")
	if forest: return _to("exit", "Back to Criț")
	if not has("cr_mother"): return _to("mother", "Floarea's mother")
	return _to("road", "Road to Saschiz")

func objective() -> String:
	if not has("cr_job"): return "Neighbours cross the street to avoid one house. Find out why."
	if not has("cr_basket"): return "Floarea's hands will not heal. Look around (%d/%d) and ask the old women (%d/%d)." % [clues_found(), CLUES.size(), asked(), WOMEN.size()]
	if not has("cr_shrine"):
		var need := PackedStringArray()
		if not has("cr_fruit"): need.append("fruit from the mother's garden")
		if not has("cr_poppy"): need.append("poppies from the old cemetery")
		if not has("cr_roses"): need.append("wild roses from the forest trail")
		return "Fill the offering basket: " + ", ".join(need) + "." if need.size() > 0 else "Take the basket to Sfânta Vineri's shrine, deep in the forest."
	if not has("cr_mother"): return "Go back and talk to Floarea's mother."
	if has("cr_sub_found") and not has("cr_sub_done"): return "Take the distaff to Nea Toma at the still."
	return "The road north goes to Saschiz."

func marker(id: String) -> bool:
	match id:
		"floarea": return not has("cr_job")
		"baba_ana", "baba_safta", "baba_veta": return has("cr_job") and not has("cr_b_" + id)
		"mother": return has("cr_shrine") and not has("cr_mother")
		"gerda": return not has("cr_sub_job")
		"rada": return not has("cr_rada_job") or (knots() >= 3 and not has("cr_rada_done"))
		"distiller": return has("cr_sub_found") and not has("cr_sub_done")
		"vineri": return not has("cr_shrine")
	return false

func pending(p: Prop) -> bool:
	if p.kind == "clue": return has("cr_job") and not has("cr_c_" + p.id)
	match p.id:
		"windlass": return has("cr_rada_job") and knots() < 3
		"distaff": return has("cr_sub_job") and not has("cr_sub_found")
		"apples": return has("cr_basket") and not has("cr_fruit")
		"poppies": return has("cr_basket") and not has("cr_poppy")
		"roses": return has("cr_basket") and not has("cr_roses")
		"shrine": return gathered() and not has("cr_shrine")
	return false

func arrive() -> void:
	if has("cr_arrive"): return
	mark("cr_arrive")
	G.start_dialogue("Criț", [
		"Criț, Deutsch-Kreuz, under its hill of the fortified church. Wash hangs in the yards and smoke rises from the chimneys.",
		"A woman with a basket crosses the street rather than pass one house, and makes the sign of the cross as she goes."])

func talk(id: String) -> bool:
	match id:
		"gerda": _gerda()
		"rada": _rada()
		"distiller":
			if has("cr_sub_found") and not has("cr_sub_done"):
				_distaff_home()
				return true
			G.start_dialogue("Nea Toma", [
				"(An old man feeds plum mash into a copper still and watches the drip like a man watching a clock.)",
				"First run of the year. The plums were sweet, so the țuică will be honest.",
				"You're the one asking about Floarea's hands? Then listen: nobody in Criț spins, sews or washes on a Friday. My mother didn't, hers didn't.",
				"Sfânta Vineri walks the roads on her day. She is kind to those who keep it. Go on down past the mill if you want the graveyard. Mind the crossroads after dark."])
		"millwife":
			G.start_dialogue("The miller's wife", [
				"(She wrings a shirt over the brook and hangs it on the line. It is Thursday's washing, she tells you, before you can ask.)",
				"The wheel turns for everybody: Saxon rye, Romanian millet, all one flour by evening.",
				"The poppies you're after grow between the old graves, down the road. Pick them with your left hand. That's how the old women want them."])
		"floarea":
			if not has("cr_job"):
				G.start_dialogue("Floarea", [
					"(A young woman sits on the bench by the gate with her hands wrapped in wet cloths. She tries to hide them.)",
					"Don't look at them, please. They are blistered to the bone and nothing heals them. Not goose fat, not plantain, not the priest.",
					"My wedding is in three days. I wanted my trousseau finished: the linen, the embroidered shirts, all of it washed and white.",
					"So I washed it all last Friday. Mother said it was foolishness to wait. Since then the neighbours won't come near our gate.",
					"The old women know something. They always know something. Would you ask them? They won't talk to me.",
				], func(): mark("cr_job"); Hud.toast("New quest: The Friday Curse"))
			elif has("cr_mother"):
				G.start_dialogue("Floarea", ["(She opens and closes her hands as if they were new.) Look! You'll come to the church, won't you? Stand at the back, you're too tall for the front."])
			else:
				G.start_dialogue("Floarea", ["Mother is inside. Be careful with her; she has never once said she was wrong." if has("cr_shrine") else "Did the old women tell you anything? Please hurry."])
		"baba_ana":
			_woman(id, "Baba Ana", [
				"Friday? She washed on a Friday? Child, child.",
				"Friday is not ours. Friday belongs to Sfânta Vineri, Saint Friday. My mother never so much as combed her hair on a Friday."])
		"baba_safta":
			_woman(id, "Baba Safta", [
				"Sfânta Vineri is kind to girls who work hard. She gives them beauty and good husbands. All week long.",
				"But she punishes the women who work on her day. Spinning, washing, sewing. Burned hands, a burning in the fingers that will not stop. You have seen them."])
		"baba_veta":
			_woman(id, "Baba Veta", [
				"Her shrine stands in the forest, past the ribbons. Nobody has walked that path in years; the young ones laugh at us.",
				"Don't go with empty hands. Fruit from a good garden, wild roses from her own forest, and poppies, red ones, from the old graveyard."])
		"mother": _mother()
		"vineri": pass
		_: return false
	return true

## Side quest: Gerda, the miller's apprentice, dropped her carved distaff in the millrace.
func _gerda() -> void:
	if has("cr_sub_done"):
		G.start_dialogue("Gerda", ["The flax is spun and the water kept its hands to itself. Thank you, hunter. Truly."])
	elif has("cr_sub_found"):
		G.start_dialogue("Gerda", ["You have it! Take it to Nea Toma, quickly. He knows what to do with salt and plum steam."])
	elif has("cr_sub_job"):
		G.start_dialogue("Gerda", ["The wheel is right there, hunter. Don't stand and make faces at the current. A hunter will not melt."])
	else:
		mark("cr_sub_job")
		G.start_dialogue("Gerda", [
			"(A girl in a miller's apron stands crying at the sluice, wringing a wet flax bundle.)",
			"It slipped right out of my apron into the foam! My carved walnut distaff. I was rushing before Friday and now it is down there under the wheel.",
			"If unspun flax lies in running water on a Friday, the water-maid weaves a shroud with it before morning. Everyone knows that.",
			"(You look at the black water under the wheel. Then at your good boots.)"],
			func(): Hud.toast("New quest: The Distaff in the Millrace"))

## Side quest: Baba Rada's well has gone cloudy; three red knots on the windlass beam clear it.
func _rada() -> void:
	if has("cr_rada_done"):
		G.start_dialogue("Baba Rada", ["Clear as glass. You may drink, hunter, before you die of being proud."])
	elif knots() >= 3:
		mark("cr_rada_done")
		G.start_dialogue("Baba Rada", [
			"(She drops a pebble down the well. A deep, clear chime answers.)",
			"There. The eye is blinded. Take this St. John's wort, and ten coins for the knots."],
			func():
				G.player.coins += 10; G.player.potions += 1
				Audio.sfx("coin", -4.0)
				Hud.toast("Quest complete: The Red Thread.  +10 coins, +1 flask"))
	elif has("cr_rada_job"):
		G.start_dialogue("Baba Rada", ["Three knots on the beam, left over right. Pull from the thumb side! A calf could tie better with its tail.  (%d/3)" % knots()])
	else:
		mark("cr_rada_job")
		G.start_dialogue("Baba Rada", [
			"(An old woman waves a skein of wool dyed red with madder root at the well.)",
			"Some fool with yellow eyes stared straight down the shaft this morning. Never spat, never crossed himself. Now the bucket comes up tasting of sour silt.",
			"Tie three red knots round the windlass beam, hunter. Left over right, and tie them tight."],
			func(): Hud.toast("New quest: The Red Thread"))

func _distaff_home() -> void:
	mark("cr_sub_done")
	Audio.sfx("hunter_hm", -2.0)
	G.start_dialogue("Nea Toma", [
		"(He takes the dripping distaff, smells the wood, and sets it on the warm copper hood of the still.)",
		"Salt and plum steam. If any river demon had her teeth in this, she is spitting gravel by now.",
		"Here, for the cold water: a flask of the second run. Mind your head with it. And take these for the girl's trouble."],
		func():
			G.player.coins += 15; G.player.potions += 1
			Audio.sfx("coin", -4.0)
			Hud.toast("Quest complete: The Distaff in the Millrace.  +15 coins, +1 flask"))

func _mother() -> void:
	if not has("cr_shrine"):
		G.start_dialogue("Floarea's mother", ["Curse? Rubbish. Old women's talk. It is a rash; it will pass. Now get away from my gate."])
		return
	if has("cr_mother"):
		G.start_dialogue("Floarea's mother", ["Go on, the church is waiting. And wipe your boots."])
		return
	G.start_choice("Floarea's mother", [
		"Well? You've been in the forest with the old women's baskets. And now you'll tell me my girl is cursed.",
		"We have no time for saints. A house does not keep itself on a Friday or any other day.",
	], [
		"Gentle: \"You wanted her trousseau perfect. So does she. One day a week of rest is a small price.\"",
		"Blunt: \"Your daughter's hands are raw because you sent her to the washtub on a Friday.\"",
		"Practical: \"Wash on Thursday, rest on Friday. The linen is just as white.\"",
	], func(pick: int):
		var reply: Array = [
			["(Her mouth trembles.) I only wanted it to be beautiful for her. Everything I never had.", "...Fridays, then. We rest on Fridays."],
			["(She goes white, then red, and for a moment you think she will strike you.)", "...You're right. God help me, you're right. No more washing on Fridays in this house."],
			["(She sniffs.) Thursday. Hm. Thursday is the better drying day anyway, the wind comes from the hill.", "So be it. Fridays we sit. But I'm not sitting idle; I'll pray."],
		][clampi(pick, 0, 2)]
		G.start_dialogue("Floarea's mother", reply, _wedding))

func _wedding() -> void:
	mark("cr_mother")
	G.start_dialogue("The wedding", [
		"Three days later the bells of the fortified church ring for Floarea.",
		"She walks in wearing her trousseau, every stitch of it white, and her hands are smooth and whole around the candle.",
		"Her mother pretends not to cry, and smiles in spite of herself when the girl looks back at her.",
		"You watch from the back of the church, cap in your hands, and slip out before the dancing starts.",
	], func():
		mark("cr_done"); mark("token_ribbon")
		G.player.coins += 20
		Audio.sfx("bell", -8.0)
		Hud.toast("Quest complete: The Friday Curse.  Token: the ribbon from the shrine"))

func _woman(id: String, who: String, lines: Array) -> void:
	if not has("cr_job"):
		G.start_dialogue(who, ["(She looks you up and down, then looks at the house down the street, and says nothing.)"])
		return
	var first := not has("cr_b_" + id)
	G.start_dialogue(who, lines, func():
		mark("cr_b_" + id)
		if first: Hud.toast("Old women asked %d/%d" % [asked(), WOMEN.size()])
		_check_basket())

func _check_basket() -> void:
	if has("cr_basket") or asked() < WOMEN.size() or clues_found() < CLUES.size(): return
	mark("cr_basket")
	G.start_dialogue("Baba Veta", [
		"(The three old women are waiting for you together at the well. Baba Veta presses a wicker basket into your hands.)",
		"For the offering. Fill it, and lay it at her shrine with a good heart. Not for the girl's sake. For her mother's.",
	], func(): Hud.toast("Offering basket. Fill it: fruit, poppies, wild roses."))

func use(p: Prop) -> void:
	if p.id == "crossroads":
		G.start_dialogue("Wayside shrine", [
			"A small roofed shrine where the graveyard road meets the field track. Somebody keeps a candle burning in it.",
			"Crossroads are where the unquiet wait: that is why the shrine stands here, and why the candle is never let go out."])
		return
	if p.kind == "clue":
		if not has("cr_job"):
			G.start_dialogue("Criț", ["Nobody here will tell you anything yet."])
			return
		var first := not has("cr_c_" + p.id)
		mark("cr_c_" + p.id)
		var after := func():
			if first: Hud.toast("Clue %d/%d" % [clues_found(), CLUES.size()])
			_check_basket()
		match p.id:
			"laundry": G.start_dialogue("Laundry", ["A whole trousseau hangs on the line: embroidered shirts, linen, towels. Dry for days and nobody has taken it in.", "Nobody wants to touch it."], after)
			"lye": G.start_dialogue("Lye bucket", ["A bucket of grey lye by the well, still sharp enough to sting your nose. Ash and water, for the big wash.", "The ash at the bottom is from last week. Friday's wash."], after)
			"ribbons": G.start_dialogue("Ribbons", ["Faded red and white ribbons tied to the trees at the edge of the village, dozens of them, some so old they are grey.", "Offerings. Someone used to care very much about something out there."], after)
			_: G.start_dialogue("Old path", ["A trampled path runs from the ribbons into the forest, grown over, but still there under the ferns.", "Nobody has used it in years."], after)
		return
	match p.id:
		"windlass":
			if not has("cr_rada_job"): G.start_dialogue("Well", ["The windlass beam is worn smooth by a hundred years of ropes."])
			elif knots() < 3:
				var k := knots() + 1
				mark("cr_knot%d" % k)
				Audio.sfx("blip", -4.0, 1.0 + 0.1 * k)
				G.start_dialogue("Well", ["(You tie knot %d, and it looks like an old rope on a goat. Baba Rada squints at it from her bench and says nothing, which is worse.)" % k if k == 1 else "(Knot %d, left over right, pulled from the thumb side.)" % k],
					func(): if k == 3: Hud.toast("Three knots. Tell Baba Rada."))
			else: G.start_dialogue("Well", ["Three red knots on the beam. The water below is clear."])
		"distaff":
			if not has("cr_sub_job"): G.start_dialogue("Millrace", ["Black water churns under the mill wheel."])
			elif not has("cr_sub_found"):
				mark("cr_sub_found"); p.used = true
				Audio.sfx("hunter_hm", -2.0)
				Audio.sfx("blip", -4.0, 0.9)
				G.start_dialogue("Millrace", ["You wade into the sluice, dodge a paddle that wants your ribs, and fish out a carved walnut distaff, slick as an eel.", "(Somewhere downstream the water laughs, once, very softly.)", "(You shake the water out of your sleeves and climb back onto the bank, dripping like a drowned sheep.)"])
		"apples":
			if not has("cr_basket"): G.start_dialogue("Garden", ["Apple and plum trees in the mother's garden, heavy with fruit."])
			elif not has("cr_fruit"):
				mark("cr_fruit"); p.used = true
				Audio.sfx("blip", -4.0, 1.1)
				G.start_dialogue("Garden", ["You fill the bottom of the basket with red apples and dark plums from the mother's garden. She watches from the window and says nothing."])
		"poppies":
			if not has("cr_basket"): G.start_dialogue("Old cemetery", ["Red poppies grow between the oldest graves, where nobody mows."])
			elif not has("cr_poppy"):
				mark("cr_poppy"); p.used = true
				G.start_dialogue("Old cemetery", ["You pick the poppies, one by one. As you pull up the last, the earth on the grave beside you heaves."],
					func(): if G.level.has_method("raise_the_dead"): G.level.raise_the_dead())
		"forest": Loader.goto_level("critforest")
		"road":
			if not has("cr_done"): G.start_dialogue("The road north", ["Not before the wedding."])
			else: Loader.goto_level("saschiz")
		"roses":
			if not has("cr_basket"): G.start_dialogue("Wild roses", ["Wild roses, the last blooms of the year among the rosehips."])
			elif not has("cr_roses"):
				mark("cr_roses"); p.used = true
				Audio.sfx("blip", -4.0, 1.2)
				G.start_dialogue("Wild roses", ["You cut an armful of wild roses and lay them over the fruit. Thorns, of course."])
		"shrine":
			if has("cr_shrine"): G.start_dialogue("The shrine", ["The candle you lit still burns. Ribbon after ribbon hangs from the roof."])
			elif not gathered(): G.start_dialogue("The shrine", ["A little wooden shrine with an icon of a woman in red, the paint almost gone. Your basket is not full yet."])
			elif G.level.has_method("offering"): G.level.offering()
