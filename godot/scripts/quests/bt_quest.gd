## Biertan. By day "The Baron's Table": a warm welcome, a supper with no salt on it, and three things in the
## three walls that add up to what the baron is. By night "The Locked Door": the sexton empties his bags of
## grave earth into the streets, the village runs, and the hunter fights up through the three gates to the
## sacristy door of 1515. Each of the nine things carried from the road draws two of its nineteen bolts;
## the baron draws the last himself.
class_name BtQuest
extends RefCounted

## flag, what it is, the memory it carries
const TOKENS := [
	["token_tin_button", "a bent tin button", "Sighișoara: the spiriduși carrying hams up the tower stair before dawn, in step."],
	["token_cellar_key", "the cellar key", "Viscri: the dogs barking again in the yards, every one of them."],
	["token_ribbon", "the ribbon from the shrine", "Criț: Floarea's wedding, her hands healed, the whole village dancing."],
	["token_fort_stone", "a stone from the fortress", "Saschiz: the giant carrying the children home down the hill, two on each arm."],
	["token_ana_lantern", "Ana's lantern", "Șapartoc: Ana in her hammock, swinging, finally at rest."],
	["token_samedru_candle", "a candle lit from Sâmedru's fire", "Apold: the dead at their tables, grumbling about the colivă."],
	["token_muma_twig", "a twig from Muma's oak", "Criș: Muma Pădurii under her oak. \"It's the bread, boy.\""],
	["token_tower_key", "the church tower key", "Mălâncrav: your trousers, flying from the weathervane."],
	["token_flower_ring", "a ring of dried flowers", "Richiș: Toader waking beside his brother with the nai."],
]
const WALLS := ["the outer wall", "the middle wall", "the inner wall"]
const SIGNS := ["salt", "garlic", "wine", "servant", "kennel"]       # what is odd at the baron's table
const PROOFS := ["couple", "grave", "ledger"]                         # one in each wall

static func has(f: String) -> bool: return G.side_has(f)
static func mark(f: String) -> void: G.side_add(f)

static func tokens_have() -> int:
	var n := 0
	for tk in TOKENS:
		if has(tk[0]): n += 1
	return n

static func bolts() -> int:
	var n := 0
	for i in 3:
		if has("bt_bolt%d" % i): n += 1
	return n

static func signs() -> int:
	var n := 0
	for s in SIGNS:
		if has("bt_s_" + s): n += 1
	return n

static func proofs() -> int:
	var n := 0
	for s in PROOFS:
		if has("bt_i_" + s): n += 1
	return n

static func night() -> bool: return has("bt_night") and not has("bt_fled")

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
	if G.current == "sacristy":
		return _to("door", "The sacristy door") if not has("bt_open") else ([] if not has("bt_fled") else _to("trapdoor", "The stair under the tomb"))
	if has("bt_fled"): return _to("down", "The road down to the gorge")
	if has("bt_night"):
		for i in 3:
			if not has("bt_bolt%d" % i): return _to("guard%d" % i, "The" + WALLS[i].substr(3))
		return _to("church", "The church door")
	if not has("bt_invited"): return _to("baron", "The baron")
	if signs() < SIGNS.size():
		var l := []
		for s in SIGNS:
			if not has("bt_s_" + s): l.append([s, "Something odd"])
		return _near(l)
	if not has("bt_supper"): return _to("baron", "The baron")
	if proofs() < PROOFS.size():
		var l := []
		if not has("bt_i_couple"): l.append(["spouse1", "The outer wall"])
		if not has("bt_i_grave"): l.append(["grave", "The middle wall"])
		if not has("bt_i_ledger"): l.append(["ledger", "The inner wall"])
		return _near(l)
	return _to("baron", "The baron")

func objective() -> String:
	if G.current == "sacristy": return G.level.line()
	if not has("bt_arrive"): return ""
	if has("bt_fled"): return "He has gone down the stair under his tomb. Follow him: the stair in the sacristy, or the road down the hill to the gorge."
	if has("bt_night"):
		for i in 3:
			if not has("bt_bolt%d" % i): return "Biertan by night. Fight through %s. (Gates open: %d/3)" % [WALLS[i], bolts()]
		return "The three gates stand open. He is in the church."
	if not has("bt_invited"): return "Biertan is busy and cheerful. The baron himself is coming down the stair to meet you."
	if signs() < SIGNS.size(): return "Supper at the baron's table, in the middle ring. Keep your eyes open. (%d/%d)" % [signs(), SIGNS.size()]
	if not has("bt_supper"): return "Sit down to supper with the baron."
	if proofs() < PROOFS.size(): return "Something is wrong in Biertan. Ask in each of the three walls. (%d/%d)" % [proofs(), PROOFS.size()]
	return "You know what he is. Say it to his face."

func marker(id: String) -> bool:
	match id:
		"baron": return not night() and not has("bt_fled") and (not has("bt_invited") or (signs() == SIGNS.size() and not has("bt_supper")) or (proofs() == PROOFS.size() and not has("bt_night")))
		"spouse1", "spouse2": return has("bt_supper") and not has("bt_i_couple")
		"bvlad": return has("bt_supper") and not has("bt_i_grave")
	return false

func pending(p: Prop) -> bool:
	if p.id in SIGNS: return has("bt_invited") and not has("bt_s_" + p.id)
	match p.id:
		"grave": return has("bt_supper") and not has("bt_i_grave")
		"ledger": return has("bt_supper") and not has("bt_i_ledger")
		"church": return night() and bolts() == 3
		"door": return not has("bt_open")
	return false

func arrive() -> void:
	if not has("bt_arrive"):
		mark("bt_arrive")
		G.start_dialogue("Biertan", [
			"(The covered stair climbs the hill under its old wooden roof. Below it the long street is full: a market, carts, women with baskets, somebody selling roast chestnuts.)",
			"(People nod to you. A child waves. After the road you have walked, it is almost alarming.)",
			"(Above, three rings of wall, one inside the other, and the hall church on top like a ship on a wave of stone.)",
			"(It takes you the length of the street to notice what is missing. Nobody here keeps a dog.)",
		], func(): Hud.toast("New quest: The Baron's Table"))
	elif has("bt_night") and not has("bt_night_seen"):
		mark("bt_night_seen")
		G.start_dialogue("Biertan by night", [
			"(The bell. Not rung: beaten, like a pot. The sexton is running along the top of the inner wall with a sack on his shoulder, shaking it out over the roofs. Black earth, coming down like soot.)",
			"(Where it lands, things get up.)",
			"(The whole of Biertan comes down the covered stair past you in its nightshirts. Magda is at the bottom throwing children onto the cart two at a time. \"HAIDA! HAIDAAA!\" Vlad already has the horse turned.)",
			"(In the time it takes the street to empty, the three gates above you grind shut.)",
		], func(): Hud.banner("THE LOCKED DOOR", "Three walls between you and the church, and every one of them awake."))

func talk(id: String) -> bool:
	match id:
		"baron": _baron()
		"servant":
			G.start_dialogue("A servant", ["(He bows, slowly. It takes him a moment to remember to straighten up again.)"])
		"bsexton":
			G.start_dialogue("The sexton", ["(A lean man with good boots and a ring of keys: the Viscri sexton, who woke up so confused in his own cellar. He does not look confused now. He looks straight through you.)", "I keep two churches, hunter. Two bells, two salaries, and nobody ever asks a sexton where he goes at night.", "This one is shut for repairs. Has been for some time. His lordship is very generous about repairs."])
		"spouse1", "spouse2": _couple()
		"bvlad", "bmagda":
			if not has("bt_supper"): G.start_dialogue("Vlad and Magda", ["Vlad: Good custom here. They pay on the nail and never haggle.", "Magda: They never do ANYTHING. I said good morning to a woman and she thought about it."])
			elif not has("bt_i_grave"): G.start_dialogue("Vlad Laurențiu", ["Come and look at this plot with me. I don't like it and I can't say why."])
			else: G.start_dialogue("Vlad and Magda", ["Magda: We are sleeping on the cart tonight, with the horse in the shafts.", "Vlad: She is right. Don't tell her I said so.", "Magda: I HEARD that."])
		"market1": G.start_dialogue("A woman with a basket", ["Welcome, welcome. His lordship said a hunter was coming. He hears everything, his lordship. (She smiles. It takes a while to arrive.)"])
		"market2": G.start_dialogue("The chestnut seller", ["Dogs? No. No dogs. They... don't settle here. (He looks up at the church, and then at his chestnuts.)"])
		"market3": G.start_dialogue("An old man", ["Thirty years since I heard that bell. The sexton says the rope is rotten. Thirty years is a long time for a rope."])
		_: return id in ["ally_fox", "ally_deer", "ally_owl", "mbear"]
	return true

func _baron() -> void:
	var who := "The baron of Biertan"
	if not has("bt_invited"):
		G.start_dialogue(who, [
			"(A tall man in a coat two hundred years out of fashion and beautifully kept. He comes down the stair with his hand already out.)",
			"The hunter! We have heard of nothing else for a week. Giants, ghosts, a village gone mad on its own bread. You must be worn to the bone.",
			"You will take supper with me. I insist. My table is laid in the middle ring, under the church; we eat late here, you will forgive it. I keep late hours.",
			"(His hand is cold, the way a hand is cold that has been outdoors all day. It is a warm evening.)",
		], func():
			mark("bt_invited")
			G.level.seat_baron()
			Hud.toast("Supper with the baron, in the middle ring under the church."))
	elif signs() < SIGNS.size():
		G.start_dialogue(who, ["Sit, sit. Look about you first if you like. A hunter's eyes are never off duty, I know."])
	elif not has("bt_supper"):
		_supper(who)
	elif proofs() < PROOFS.size():
		G.start_dialogue(who, ["You are restless. Walk the walls. Everyone does."])
	elif not has("bt_night"):
		G.start_dialogue(who, [
			"(He is standing at the church door, as if he had known which evening you would come.)",
			"(You say it. All of it: the supper he did not eat, the garlic that is nowhere, the dogs, the dug-over grave, the bags, the bell. And the last word, the one nobody in Biertan has said aloud in two hundred years.)",
			"(He does not deny it. He looks, more than anything, tired.) Bags? What bags?",
			"(Behind him the sexton has stopped moving. Then the sexton is not there at all.)",
			"Hunter. I think you had better go down the hill. Quickly. I am not always... I keep late hours.",
		], func():
			mark("bt_night")
			Loader.goto_level("biertanfort"))

func _couple() -> void:
	if has("bt_prison"):
		if has("bt_supper") and not has("bt_i_couple"): _couple_proof()
		else: G.start_dialogue("The couple", ["(They are holding hands and pretending they aren't.)"])
		return
	mark("bt_talked")
	G.start_dialogue("A couple, arguing", [
		"— He snores like a bear in a barrel! — She puts cold feet on me, in OCTOBER!",
		"— Thirty years! — Thirty-one, you can't even count!",
		"(They want a divorce. In Biertan the bishop's custom was simple: two weeks in the marriage prison, one bed, one plate, one spoon. Then you could ask again.)",
	], func():
		if has("bt_supper") and not has("bt_i_couple"): _couple_proof()
		else: Hud.toast("The marriage prison is the little tower by the wall."))

func _couple_proof() -> void:
	mark("bt_i_couple")
	G.start_dialogue("The couple", [
		"A wedding? Here? (They look at each other, united for once.) Nobody has married in Biertan since before our parents.",
		"His lordship does not care for weddings. Nobody ever said so. You just... find you have put it off another year.",
		"We went to Mediaș for ours. He sent a very handsome gift. No card.",
	], func(): Hud.toast("Biertan: %d/%d" % [proofs(), PROOFS.size()]))

func use(p: Prop) -> void:
	if p.id in SIGNS:
		if not has("bt_invited"):
			G.start_dialogue(p.display, ["Nothing to see. Yet."])
			return
		var first := not has("bt_s_" + p.id)
		mark("bt_s_" + p.id)
		var after := func():
			if first: Hud.toast("Odd %d/%d" % [signs(), SIGNS.size()] + (". Sit down to supper." if signs() == SIGNS.size() else ""))
		match p.id:
			"salt": G.start_dialogue("The baron's table", ["Roast pork, plum dumplings, three kinds of bread. A table for twenty, laid for two.", "No salt cellar. You look twice. On a Saxon table."], after)
			"garlic": G.start_dialogue("The kitchen", ["Onions in ropes, peppers, dill, a ham the size of a child.", "Not one head of garlic. Not a braid, not a clove, not the smell of it in the boards."], after)
			"wine": G.start_dialogue("The baron's cup", ["His cup is full. It was full when you arrived.", "A fly has drowned in it, some time ago."], after)
			"servant": G.start_dialogue("The servants", ["Six of them along the wall, grey as dishwater, swaying a little like men asleep on their feet.", "One has a scarf wound high round his neck. In this warmth."], after)
			_: G.start_dialogue("A kennel", ["A good oak kennel by the middle gate, with a chain and a bowl.", "The chain is rusted through. The bowl has a bird's nest in it."], after)
		return
	match p.id:
		"prison":
			if night(): G.start_dialogue("The marriage prison", ["(The door is barricaded from inside with the one bed.)", "— This is YOUR fault! — MINE? Who wanted to stay for the chestnuts? — Pass me the spoon, I'll hit it with the spoon!", "(They are fine.)"])
			elif has("bt_prison"): G.start_dialogue("The marriage prison", ["One bed, one plate, one spoon. Empty now."])
			elif not has("bt_talked"): G.start_dialogue("The marriage prison", ["A little tower with one bed, one plate and one spoon. For couples who want a divorce."])
			else:
				G.start_dialogue("The marriage prison", [
					"(You march them in, very politely, and turn the key. They shout for an hour.)",
					"(Then it goes quiet. Then somebody laughs.)",
					"(\"Two weeks\" later, by the bishop's reckoning, which is to say when you come back with the key: they come out sharing the spoon.)",
				], func():
					mark("bt_prison")
					G.level.reconciled()
					G.player.coins += 10
					Hud.toast("The couple reconciled. +10 coins"))
		"grave":
			if not has("bt_supper"): G.start_dialogue("A grave", ["An old plot by the middle wall, the stone worn smooth. Somebody keeps it very tidy."])
			else:
				var first := not has("bt_i_grave")
				mark("bt_i_grave")
				G.start_dialogue("The dug-over grave", [
					"(One plot among the old graves, the stone too worn to read but for a year: 1321. The earth on it is fresh. Under the fresh earth, older digging, and older under that.)",
					"Vlad Laurențiu: (He crouches and rubs a pinch of it between his fingers.) Black. Cold. I know this. I've carried this.",
					"Little linen bags, tied with candle wick. The sexton gives me a crate of them every month, \"church goods\", for Viscri, for Criș, for Mălâncrav. I never looked.",
					"Magda: You never LOOK, Vlad! (She has gone white. She takes his arm anyway.)",
				], func():
					if first: Hud.toast("Biertan: %d/%d" % [proofs(), PROOFS.size()]))
		"ledger":
			if not has("bt_supper"): G.start_dialogue("The sexton's house", ["The best house inside the walls. New shingles, glass in every window."])
			else:
				var first := not has("bt_i_ledger")
				mark("bt_i_ledger")
				G.start_dialogue("The sexton's house", [
					"(The door is on the latch. Inside: linen bags, hundreds of them, stacked to the rafters like a miller's store. The smell of a shut cellar.)",
					"(And on the table a ledger, in a neat hand. Viscri: watch on the churchyard, 40 florins. Criș: blessing of the forest paths, 60. Mălâncrav: candles for the crypt, 35. Richiș: prayers for the ridge road, 80.)",
					"(Every village on your road. A column for what was left there, and a column for what they paid him to take it away again.)",
				], func():
					if first: Hud.toast("Biertan: %d/%d" % [proofs(), PROOFS.size()]))
		"church":
			if has("bt_fled"): G.start_dialogue("The church door", ["Open. Somebody has already been up the tower: the bell is ringing properly, for the first time in thirty years."])
			elif not has("bt_night"): G.start_dialogue("The church door", ["Locked. \"Repairs,\" says a card in the sexton's neat hand. The card has gone yellow."])
			elif bolts() < 3: G.start_dialogue("The church door", ["The way to the church goes through all three walls. Gates open: %d/3." % bolts()])
			else: Loader.goto_level("sacristy")
		"down":
			if has("bt_fled"): Loader.goto_level("gorge")
			elif night(): G.start_dialogue("The road down", ["Not while he is still up there."])
			elif has("bt_arrive") and not has("bt_night") and has("bt_invited"): G.start_dialogue("The road down", ["You have been asked to supper. It would be rude."])
			else: Loader.goto_level("richisvillage", RcQuest.ridge_gate + Vector2(0, 200) if RcQuest.ridge_gate != Vector2.ZERO else null)
		"trapdoor":
			G.start_dialogue("The stair under the tomb", [
				"(Down, a long way, on steps worn into a dip by somebody's feet. Then a passage, then up again, into wind and the smell of wet stone.)",
				"(It comes out in the side of an old quarry, east of Biertan. His footprints go on along the gorge. So does the storm.)",
			], func(): Loader.goto_level("gorge"))
		"door": G.level.door()
		"bell": G.level.ring_bell()
		"out": G.level.leave()

## Supper at the baron's table: the picture first, then the talk.
func _supper(who: String) -> void:
	await G.show_story("supper_biertan")
	Hud.fade_to(0.0, 0.6)
	G.start_dialogue(who, [
		"(You eat. He talks: about the walls, the vines, a wedding the village once prepared for a whole summer. He is good company. He asks about every village on your road, and listens to the answers.)",
		"(He carves for you, pours for you, passes you everything. You never once see him swallow.)",
		"And the lady in Viscri, who draws maps? (You did not mention a lady in Viscri.) Forgive me. People talk, and I have a great deal of time to listen.",
		"Stay as long as you like. Walk the walls tomorrow; everyone does. You will find Biertan has nothing to hide.",
		"(Outside, no dog has barked since you arrived.)",
	], func():
		mark("bt_supper")
		Hud.toast("Something is wrong in Biertan. Ask in each of the three walls.")
		Loader.goto_level("biertanfort", G.player.pos))   # morning: the baron has gone, the table is as it was
