## The end of the road, in Sighișoara: Lorena in the Tinsmiths' Tower, the baron who would very much like her
## taken off his hands, the midnight he cannot help, and the wedding of the dead he was refused in 1321,
## which does not go the way anybody planned.
class_name FinQuest
extends RefCounted

const PREP := ["fir", "priest", "table"]

static func has(f: String) -> bool: return G.side_has(f)
static func mark(f: String) -> void: G.side_add(f)
static func on() -> bool: return has("v3_azorel") and not has("fin_done")

static func prep() -> int:
	var n := 0
	for x in PREP:
		if has("fin_p_" + x): n += 1
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
	if G.current == "hillchurch": return G.level.pointer()
	if G.level.night: return _to("bell", "The Clock Tower bell") if G.level.bell_ready() else []
	if not has("fin_spirid"): return _to("captain", "The Butchers' Tower")
	if not has("fin_key"): return _to("baron", "The baron") if G.current == "draculhouse" else _to("dracul_door", "The house with the dragon")
	if not has("fin_lorena"): return _to("tower", "The Tinsmiths' Tower")
	if not has("fin_dawn"): return _to("baron", "The baron")
	if prep() < PREP.size():
		var l := []
		if not has("fin_p_fir"): l.append(["bvlad", "Vlad's cart"])
		if not has("fin_p_priest"): l.append(["finpriest", "A priest, asleep"])
		if not has("fin_p_table"): l.append(["butcher", "Meister Thomas"])
		return _near(l)
	return _to("stair", "The Scholars' Stair")

func objective() -> String:
	if G.current == "hillchurch": return G.level.line()
	if G.level.night: return G.level.night_line()
	if not has("fin_arrive"): return ""
	if not has("fin_spirid"): return "Sighișoara, at dusk. Somebody under the Butchers' Tower owes you a favour."
	if not has("fin_key"): return "He is in the house with the dragon on its sign. Get her back."
	if not has("fin_lorena"): return "The Tinsmiths' Tower. You have the key."
	if not has("fin_dawn"): return "Nearly midnight. He asked you to be near him when it strikes."
	if prep() < PREP.size(): return "A wedding of the dead: a fir tree, a priest, a table. (%d/%d)" % [prep(), PREP.size()]
	return "Everything is ready. Up the Scholars' Stair, to the church on the hill."

func marker(id: String) -> bool:
	match id:
		"captain": return not has("fin_spirid")
		"baron": return (has("fin_spirid") and not has("fin_key")) or (has("fin_lorena") and not has("fin_dawn"))
		"bvlad": return has("fin_dawn") and not has("fin_p_fir")
		"finpriest": return has("fin_dawn") and not has("fin_p_priest")
		"butcher": return has("fin_dawn") and not has("fin_p_table")
	return false

func pending(p: Prop) -> bool:
	match p.id:
		"tower": return has("fin_key") and not has("fin_lorena")
		"stair": return prep() == PREP.size()
		"bell": return G.current == "sighisoara" and G.level.bell_ready()
	return false

func arrive() -> void:
	if has("fin_arrive"): return
	mark("fin_arrive")
	G.start_dialogue("Sighișoara", [
		"(The citadel on its hill, where you came down out of the mountains at the end of summer looking for winter work. It feels like a year ago.)",
		"(Dusk. Shutters closed all round the square. Azorel has his nose down and his hackles up, and he is pulling you toward the Butchers' Tower.)"])

func talk(id: String) -> bool:
	match id:
		"azorel":
			G.start_dialogue("Azorel", ["(He leans on your leg for exactly one breath, then goes back to watching the dark.)"])
		"captain": _captain()
		"butcher": _thomas()
		"baron": _baron()
		"lorena": _lorena()
		"bvlad", "bmagda": _cart()
		"finpriest": _priest()
		_: return false
	return true

func _captain() -> void:
	if has("fin_spirid"):
		G.start_dialogue("The spiriduș captain", ["Tinsmiths' Tower. South wall. We left the garlic where she hung it; none of us will go near that door, and we are not the ones it is meant for."] if not has("fin_lorena") else ["A wedding! We do weddings. We do the eating at weddings."])
		return
	G.start_dialogue("The spiriduș captain", [
		"(A very small person in a very large hat steps out from behind a ham.) HALT. Who goes... (He sees the bent tin button in your hand. The hat comes off.)",
		"It's HIM. The bacon man. He kept it. LADS, he KEPT it!",
		"(Cheering, from inside the wall.)",
		"We know why you're back. We know everything that comes into this town; we live in the cellars. A gentleman came up the Viscri road last night with a lady over his shoulder. Not carrying her like a lady. Carrying her like a sack of cats.",
		"He put her in the Tinsmiths' Tower, south wall, and locked it, and then SHE locked it, from inside, and hung it with garlic. He has been sitting in the house with the dragon sign ever since with his hand in a bowl of water.",
		"We'll watch your back. A button's a button.",
	], func(): mark("fin_spirid"); Hud.toast("The house with the dragon on its sign, on the square."))

func _baron() -> void:
	var who := "The baron of Biertan"
	if not has("fin_spirid"):
		G.start_dialogue(who, ["(A tall figure at an upstairs window of the house with the dragon sign. The curtain drops.)"])
	elif not has("fin_key"):
		G.start_dialogue(who, [
			"(He is sitting at the long table in the front room, coat immaculate, one hand wrapped in a great deal of bandage. He looks up as if he had been expecting the bailiffs.)",
			"You: Free her. Now. And if she has suffered, by so much as a hair, your whole line will regret it to the last generation.",
			"The baron: Who, that girl?",
			"(He holds up the bandaged hand. It is one finger short.)",
			"She is WILD. She bit my finger off. She tried to stuff garlic in my mouth, a whole head, with the skin on. I had to lock her in the tower. She has made it worse in there. I can smell it from here.",
			"(He takes a heavy key off his belt and holds it out at arm's length, like a man returning a wasps' nest.)",
			"Here. Take the key. Just keep her away from me.",
			"Two hundred years I waited for a bride, hunter. I had the shirt ordered. And I chose the one woman in Transylvania who... (He shudders.) Go. Please.",
		], func(): mark("fin_key"); Audio.sfx("coin", -4.0); Hud.toast("The key to the Tinsmiths' Tower."))
	elif not has("fin_lorena"):
		G.start_dialogue(who, ["South wall. Follow the smell. (He moves a little further along the bench, upwind.)"])
	elif not has("fin_dawn"):
		G.start_choice(who, [
			"(He has come out onto the square, and he is standing very carefully in the middle of it, away from every door.)",
			"It is nearly twelve. I must tell you something, and you must believe it. At midnight I am not the one you will be talking to. I have never been able to stop it. In Biertan they slept through it; you will not.",
			"There is a bell in the Clock Tower. It holds me, for a few breaths. Hit me then. Hard. Do not hesitate, and do not listen to anything I say. It lasts until the light.",
		], ["Give me a moment.", "I'm ready. Let it strike."], func(pick: int):
			if pick == 1: G.level.midnight())
	elif prep() < PREP.size():
		G.start_dialogue(who, ["(He is walking round and round the square, straightening his cuffs.) A fir tree. Is it a tall one? It should be tall. She would have been tall. (He has no idea who \"she\" is. Nobody was ever chosen.)"])
	else:
		G.start_dialogue(who, ["(He is wearing the shirt. White on white, a bridegroom's. It fits.) Up the stair, then. I have been two hundred years coming up this stair."])

func _lorena() -> void:
	if not has("fin_dawn"):
		G.start_dialogue("Lorena", ["Stop looking at me like that, I am perfectly well. Go and stand near him. Somebody should, and it is not going to be me."])
	elif prep() < PREP.size():
		G.start_dialogue("Lorena", ["Tree, priest, table. I'll do the candles. (She lowers her voice.) Have you seen the way that girl with the flowers looks at his coat? No. Of course you haven't."])
	else:
		G.start_dialogue("Lorena", ["Up the stair. And afterwards you are going to tell me about the trousers. Magda says there is a weathervane in it."])

func _thomas() -> void:
	if not has("fin_dawn"):
		G.start_dialogue("Meister Thomas", ["Not a side of bacon missing since you left. They carry it up for me now. In step. (He wipes his eye.) Finest apprentices I ever had."])
	elif has("fin_p_table"):
		G.start_dialogue("Meister Thomas", ["Six hams, forty sausages, and they have folded the napkins into little hats. I did not ask them to do that."])
	else:
		G.start_dialogue("Meister Thomas", [
			"A funeral table? For a wedding? For a funeral that is a wedding. (He thinks.) Well, people eat at both.",
			"LADS! (The wall says: AYE.) The long table, up the hill. Everything smoked. And no garlic in the sausage; the groom's a particular gentleman.",
			"(Thirty very small people go up the Scholars' Stair under a table like ants under a leaf.)",
			"(Behind you: \"That coat is two hundred years out of fashion.\" \"Madam, it was the height of fashion when I died in it.\" \"Hm. Good cloth, though. Who wove it?\" Joimărița has found the baron.)",
		], func(): mark("fin_p_table"); Hud.toast("The table (%d/%d)" % [prep(), PREP.size()]))

func _cart() -> void:
	if not has("fin_dawn"):
		G.start_dialogue("Vlad and Magda", ["(They are not here yet. The road from Biertan is long, and the horse has only the four legs.)"])
	elif has("fin_p_fir"):
		G.start_dialogue("Magda and Vlad", ["Magda: If he does not cry at this wedding I will make him.", "Vlad: I cried at ours.", "Magda: You had hay fever!", "Vlad: I did not have hay fever."])
	else:
		G.start_dialogue("Vlad and Magda", [
			"Magda: THERE you are! We drove all night. ALL NIGHT. He stopped twice to rest the horse!",
			"Vlad: A fir tree, you say. For the bride's place. (He looks at the back of the cart. Then at Magda.)",
			"Magda: ...I made him cut one. In the Wolf Forest. I had a feeling. Don't look at me like that, I get feelings.",
			"Vlad: She stood under it and told me which way it would fall. It fell the other way.",
			"Magda: It fell the way I MEANT.",
			"(A young fir, twice your height, with ribbons already on it. Magda's ribbons. Vlad carries it up the hill himself, and she walks behind telling him he is holding it wrong, with her hand on his back.)",
			"(As it goes by: \"You may hold my distaff,\" says a voice. \"Carefully.\" \"Madam, I held a sword at Mohács.\" \"That is not the same thing at all.\")",
		], func(): mark("fin_p_fir"); Hud.toast("The fir tree (%d/%d)" % [prep(), PREP.size()]))

func _priest() -> void:
	if has("fin_p_priest"):
		G.start_dialogue("Father Bálint", ["I have buried men and I have married men. Never the same man on the same morning. (He hiccups.) Is there wine after?"])
		return
	G.start_dialogue("Father Bálint", [
		"(The Hungarian priest from Șapartoc, asleep on a bench with his hat over his face. Radu sent him on Vlad's cart, \"for emergencies\", with a bottle.)",
		"(You explain. A funeral. Also a wedding. The groom is dead. Has been for some time. He is over there, straightening his cuffs.)",
		"Father Bálint: (from under the hat) ...Is he baptised?",
		"(In 1297, says the baron, from across the square. In Biertan. By Father Johannes. He can give the date.)",
		"Then I don't see the difficulty. (He sits up.) I'll want paying in wine. After. I am always paid after.",
		"(He looks past you.) Who is the young lady with the hot coals? She has just told the deceased his collar is crooked, and he is letting her fix it.",
	], func(): mark("fin_p_priest"); Hud.toast("The priest (%d/%d)" % [prep(), PREP.size()]))

func use(p: Prop) -> void:
	match p.id:
		"tower":
			if not has("fin_key"): G.start_dialogue("The Tinsmiths' Tower", ["Locked. From outside, and then again from inside. Braids of garlic on the door, the latch, the hinges. Somebody in there is singing, crossly."])
			elif has("fin_lorena"): G.start_dialogue("The Tinsmiths' Tower", ["Empty. It will smell of garlic for a hundred years."])
			else:
				G.start_dialogue("The Tinsmiths' Tower", [
					"(The key turns. Nothing happens. Then a bolt goes back on the inside, and another, and something heavy is dragged away from the door.)",
					"(Lorena, in the doorway, with a rope of bedsheets over one shoulder and a tin candlestick in her fist. She has taken two bars out of the window already.)",
					"Lorena: THREE DAYS. (It has been one night.) Where have you been? I had to do it all myself! He comes into MY yard, with those manners, \"Madam, I regret the necessity\"...",
					"I bit him. Did he tell you I bit him? He fainted. A grown man. I had to wait for him to get up again so he could finish carrying me off.",
					"(Azorel gets to her before you do. She goes down on her knees in the garlic and holds on to him, and for a moment nobody says anything at all.)",
					"Lorena: (into the dog's neck) ...You look terrible. Have you been eating? What happened to your trousers, there's a patch on them.",
					"(You say you will tell her later.)",
				], func():
					mark("fin_lorena")
					Hud.toast("Lorena is free. The baron wants a word before midnight.")
					Loader.goto_level("sighisoara", G.player.pos))
		"bell": G.level.ring_bell()
		"joimarita":
			G.start_dialogue("Joimărița", ["(She has flowers in her hair and a dead man's cuff in her fingers, and she is re-sewing a button on it without having asked.)", "His hands are good hands. Soft now, but they held a plough once; you can tell by the thumb. It is a shame to put hands like that in a box."])
		"stair":
			if prep() < PREP.size(): G.start_dialogue("The Scholars' Stair", ["The covered stair up to the Church on the Hill, and the old Saxon graveyard beside it."] if has("fin_dawn") else ["The covered stair up to the Church on the Hill. Not tonight."])
			else: Loader.goto_level("hillchurch")
		"dracul_door":
			if not has("fin_spirid"): G.start_dialogue("The house with the dragon", ["(Shut, and bolted from inside. A tall figure at an upstairs window. The curtain drops.)"])
			else: Loader.goto_level("draculhouse")
		"dracul_out": G.level.leave()
		"portrait":
			G.start_dialogue("The house with the dragon", ["Somebody else was born in this house, they say. The baron says he never met him, and that the family lowered the tone of the whole street."])
