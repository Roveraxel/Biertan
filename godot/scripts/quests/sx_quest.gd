## "The Missing Children", Saschiz. Three children gone in three nights; the mob blames the neighbours. Follow
## the signs (a child's footprints beside ones as long as a cart, dropped clay toys, boulders stacked like
## blocks), clear the neighbours, survive the brawl, and climb to the giants' fortress.
class_name SxQuest
extends RefCounted

const CLUES := ["tracks", "clayhorse", "stones"]
const KIDS := {"kid1": "Paul", "kid2": "Ioana", "kid3": "Andrei"}

static var hill_path := Vector2.ZERO

static func has(f: String) -> bool: return G.side_has(f)
static func mark(f: String) -> void: G.side_add(f)

static func clues_found() -> int:
	var n := 0
	for c in CLUES:
		if has("sx_c_" + c): n += 1
	return n

func _to(id: String, label: String) -> Array:
	return [G.level.spots[id], label] if G.level.spots.has(id) else []

func target() -> Array:
	if G.current == "uriasi": return _to("exit", "Down to Saschiz") if has("sx_giant") else _to("giant", "The giant")
	if not has("sx_job"): return _to("ilinca", "Ilinca")
	if clues_found() < CLUES.size():
		var pl: Vector2 = G.player.pos
		var best := []; var bd := INF
		var spots: Dictionary = G.level.spots
		for c in CLUES:
			if not has("sx_c_" + c) and spots.has(c) and pl.distance_to(spots[c]) < bd:
				bd = pl.distance_to(spots[c]); best = [spots[c], "Tracks"]
		return best
	if not has("sx_carts"): return _to("carts", "The neighbours' carts")
	if not has("sx_brawl"): return _to("mob", "The mob at the clock tower")
	if not has("sx_giant"): return _to("hill", "The fortress hill")
	if not has("sx_done"): return _to("ilinca", "Ilinca")
	return _to("road", "The road west")

func objective() -> String:
	if G.current == "uriasi": return "Go back down to Saschiz with the children." if has("sx_giant") else "Get the children away from the giant."
	if not has("sx_job"): return "The village is in uproar. Find out what has happened."
	if clues_found() < CLUES.size(): return "Three children are missing. Follow the signs (%d/%d)." % [clues_found(), CLUES.size()]
	if not has("sx_carts"): return "The mob blames the neighbours. Look at their carts at the edge of the village."
	if not has("sx_brawl"): return "Tell the mob at the clock tower what you found."
	if not has("sx_giant"): return "A child's voice on the wind, from the fortress on the hill. Go up."
	if not has("sx_done"): return "Go and see Ilinca."
	return "The road west leads on to Șapartoc."

func marker(id: String) -> bool:
	match id:
		"ilinca": return not has("sx_job") or (has("sx_giant") and not has("sx_done"))
		"mob": return has("sx_carts") and not has("sx_brawl")
		"giant": return has("sx_giant") and not has("sx_giant_talk")
	return false

func pending(p: Prop) -> bool:
	if p.kind == "clue": return has("sx_job") and not has("sx_c_" + p.id)
	match p.id:
		"carts": return clues_found() == CLUES.size() and not has("sx_carts")
		"hill": return has("sx_brawl") and not has("sx_giant")
	return false

func arrive() -> void:
	if has("sx_arrive"): return
	mark("sx_arrive")
	G.start_dialogue("Saschiz", [
		"Saschiz, Keisd to the Saxons: the church with its clock tower, the painted houses, the fortress ruins on the wooded hill above.",
		"Shouting from the square. Somebody is ringing the bell for no reason, and somebody else is crying."])

func talk(id: String) -> bool:
	match id:
		"ilinca":
			if not has("sx_job") and not has("sx_giant"):
				G.start_dialogue("Ilinca, potter", [
					"(Her hands are grey with clay to the elbows. She doesn't bother wiping them.) You're the shepherd who went to Criț. Good. We need somebody who looks at the ground before he shouts.",
					"Three children gone in three nights. Little Paul, then Ioana, then Andrei last night. Out of their beds, no screams, no blood.",
					"Ioana had one of my clay horses, blue, with the white flowers. She never let go of it.",
					"The men say it's the neighbours from Bunești and Criț, come to take our clock tower and our children with it. Look before they do something stupid.",
				], func(): mark("sx_job"); Hud.toast("New quest: The Missing Children"))
			elif has("sx_giant") and not has("sx_done"):
				G.start_dialogue("Ilinca, potter", [
					"(The square is full: the giant has set all three children down in front of the church, very gently, one by one, and gone back up his hill.)",
					"I saw him. As big as the church door. He sat there and waved at them like a child himself.",
					"Ioana gave him the horse. Her blue horse. She said he needed it more.",
					"Here. A stone from the fortress wall; he left a pile of them by the well. They say the giants built that fort. Keep it.",
				], func():
					mark("sx_done"); mark("token_fort_stone")
					G.player.coins += 25
					Audio.sfx("coin", -4.0)
					Hud.toast("Quest complete: The Missing Children.  Token: a stone from the fortress"))
			else:
				G.start_dialogue("Ilinca, potter", ["The fortress? Up through the woods, past the old well. Go." if has("sx_brawl") else "Look at the ground. That's all I ask."])
		"mob":
			if not has("sx_carts"):
				G.start_dialogue("Hannes the smith", ["It's the Bunești lot! They've always wanted our tower. First the children, then the bells. Out of the way, stranger!"])
			elif has("sx_brawl"):
				G.start_dialogue("Hannes the smith", ["(He won't meet your eye.) We were... upset."])
			else:
				G.start_dialogue("Hannes the smith", [
					"You again. Well? Found their tracks in our yards, did you?",
					"(You tell them: the Bunești carts came in by the road and never left it. The oxen haven't moved since noon. And the footprints by the yards are a child's, with something walking beside it, something with feet as long as a cart.)",
					"Feet as long as a... You're with them! He's with them, lads!",
					"(Somebody throws a turnip. Somebody throws a punch. It is not clear at whom.)",
				], func(): if G.level.has_method("brawl"): G.level.brawl())
		"giant":
			mark("sx_giant_talk")
			G.start_dialogue("Uriașul", [
				"(The giant sits in the grass with his knees up, turning a clay horse in two enormous fingers.)",
				"...Play. Only play. Little ones laugh. Then... hold too tight. Not let go. Head full of black.",
				"(He taps the back of his own neck, where the swellings were, and winces.) Gone now. Sorry.",
				"(He gathers the three children into his apron like eggs and stands up.) Take home. Gently."])
		"kid1", "kid2", "kid3":
			if has("sx_done") and not has("sx_sing"): _song()
			else: G.start_dialogue(KIDS[id], ["He's not bad. He's just big. And he was sick on his back." if has("sx_giant") else "Help! He won't let us go home!"])
		_: return false
	return true

## The children on the church steps sing the sun-calling rhyme and make up verses about the hunter.
func _song() -> void:
	mark("sx_sing")
	Audio.sfx("kids_song", -10.0)
	G.start_dialogue("The children", [
		"(The three of them climb the church steps with four more from the lane, and hold hands. The smallest counts them in.)",
		"\"Ieși, soare, din închisoare, / Că te caută o căprioară, / Cu cercei de aur mare! / Vino, soare, pe pământ, / Că la noi e numai vânt!\"",
		"Ioana (pointing at you): Look at the big shepherd! Even a stray sheep has nicer manners than he does!",
		"Paul (skipping): \"Big boots, long knife, afraid of his own wife! Came from the mountain, slept in the hay, chased all the giant's sheep away!\"",
		"(You reach into your pack, find three dried plums, and hold them out on your palm.)",
		"Andrei (grabs a plum, inspects it for dirt, wipes it on his knee, and bites): ...They're sweet. He's allowed to stay.",
		"Lorena, leaning on the low wall: Don't look so offended, hunter. Children and drunkards are the only two kinds of people who speak the plain truth."],
		func():
			G.player.coins += 10
			Audio.sfx("coin", -4.0)
			Hud.toast("The children plait you a ring of sweetgrass.  +10 coins"))

func after_brawl() -> void:
	mark("sx_brawl")
	G.start_dialogue("The square", [
		"(One by one they sit up, rubbing their jaws, looking at each other, then at the ground.)",
		"Hannes: ...Well. Feet as long as a cart, you said.",
		"(Nobody says anything. People start drifting home.)",
		"Then, on the wind, from the wooded hill above the village: a child's voice, singing a counting rhyme. And something much bigger laughing."])

func use(p: Prop) -> void:
	if p.kind == "clue":
		if not has("sx_job"):
			G.start_dialogue("Saschiz", ["Nobody has time for you; everybody is shouting."])
			return
		var first := not has("sx_c_" + p.id)
		mark("sx_c_" + p.id)
		var after := func():
			if first: Hud.toast("Clue %d/%d" % [clues_found(), CLUES.size()])
		match p.id:
			"tracks": G.start_dialogue("Footprints", ["Small bare footprints from the yards, a child's, heading out to the pasture.", "Beside them, others. Bare too, and as long as a cart, and sunk deep in the mud."], after)
			"clayhorse": G.start_dialogue("Clay horse", ["A blue clay horse with white flowers, one leg snapped off, lying in the grass. Ioana's.", "Further on, a clay lamb, and a clay cockerel. Dropped, one by one, like a trail."], after)
			_: G.start_dialogue("Stacked stones", ["Boulders, each bigger than a man, stacked into neat little towers at the edge of the pasture.", "The way a child stacks blocks."], after)
		return
	match p.id:
		"carts":
			if clues_found() < CLUES.size():
				G.start_dialogue("The neighbours' carts", ["Carts and oxen from Bunești, waiting at the edge of the village for the market."])
			else:
				mark("sx_carts")
				G.start_dialogue("The neighbours' carts", [
					"Carts from Bunești and Criț, oxen dozing in their yokes. Their wheel ruts come in along the road and stop here; nobody has driven anywhere since yesterday.",
					"Their boot prints go to the tavern and back. Not one of them comes near the yards the children vanished from.",
				], func(): Hud.toast("The neighbours are innocent. Tell the mob at the clock tower."))
		"hill":
			if not has("sx_brawl"): G.start_dialogue("The fortress hill", ["A path climbs into the woods toward the ruins on the hill."])
			else: Loader.goto_level("uriasi")
		"road":
			if not has("sx_done"): G.start_dialogue("The road west", ["Not with three children missing."])
			else: Loader.goto_level("sapartoc")
		"exit": Loader.goto_level("saschiz", hill_path + Vector2(0, 120))
