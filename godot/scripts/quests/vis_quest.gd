## "The Silent Dogs", Viscri. Look: geese that scream at night, dogs asleep on full bellies, a trail of scraps.
## Ask: the butcher, the goose-keeper, the caretaker. Watch the old barn, take the sexton's key, go down under
## the churchyard, put the spellbound sexton down and free Matei. Lorena's map opens the road.
class_name VisQuest
extends RefCounted

const CLUES := ["geese", "dog", "scraps"]
const WITNESSES := ["vbutcher", "goosewife", "caretaker"]
const WHO := {"vbutcher": "The butcher", "goosewife": "The goose-keeper", "caretaker": "The caretaker"}

static var crypt_door := Vector2.ZERO   # the hunter climbs back out here

static func has(f: String) -> bool: return G.side_has(f)
static func mark(f: String) -> void: G.side_add(f)

static func clues_found() -> int:
	var n := 0
	for c in CLUES:
		if has("vis_c_" + c): n += 1
	return n

static func asked() -> int:
	var n := 0
	for w in WITNESSES:
		if has("vis_w_" + w): n += 1
	return n

## Act 3: he has come up the tunnel to an open gate, and has not got her back yet.
static func taken() -> bool: return G.side_has("tn_done") and not G.side_has("fin_lorena")

static func ready_to_watch() -> bool:
	return clues_found() == CLUES.size() and asked() == WITNESSES.size()

func _to(id: String, label: String) -> Array:
	return [G.level.spots[id], label] if G.level.spots.has(id) else []

func target() -> Array:
	if taken() and G.current == "viscri":
		if not has("v3_gate"): return _to("lorenagate", "Lorena's gate")
		if not has("v3_azorel"): return _to("azorel", "Azorel")
		return _to("v3road", "The road to Sighișoara")
	if has("bt_done") and not has("bt_home") and G.current == "viscri": return _to("lorena", "Home")
	if G.current == "crypt":
		if not has("vis_crypt"): return _to("sexton", "The sexton")
		if not has("vis_matei"): return _to("matei", "Matei")
		if not has("vis_chalk"): return _to("chalk", "Chalk sign")
		if not has("vis_scrap"): return _to("mapscrap", "Torn map")
		return _to("stairs", "Stairs up")
	if not has("vis_job"): return _to("lorena", "Lorena")
	if not ready_to_watch():
		var pl: Vector2 = G.player.pos
		var best := []; var bd := INF
		var spots: Dictionary = G.level.spots
		for c in CLUES:
			if not has("vis_c_" + c) and spots.has(c) and pl.distance_to(spots[c]) < bd:
				bd = pl.distance_to(spots[c]); best = [spots[c], "Something odd"]
		for w in WITNESSES:
			if not has("vis_w_" + w) and spots.has(w) and pl.distance_to(spots[w]) < bd:
				bd = pl.distance_to(spots[w]); best = [spots[w], WHO[w]]
		return best
	if not has("vis_key"): return _to("barn", "The old barn")
	if not has("vis_crypt") or not has("vis_matei"): return _to("cryptdoor", "Churchyard cellar")
	if not has("vis_done"): return _to("lorena", "Lorena")
	return _to("road", "Road to Criț")

func objective() -> String:
	if taken() and G.current == "viscri":
		if not has("v3_gate"): return "Viscri. Lorena's gate."
		if not has("v3_azorel"): return "Azorel is lying by the step."
		return "Sighișoara. He has taken her to Sighișoara. Azorel is coming with you."
	if has("bt_done") and not has("bt_home") and G.current == "viscri": return "Home. Lorena is waiting."
	if G.current == "crypt":
		if not has("vis_crypt"): return "Find Matei in the cellars under the churchyard. Stop whoever took him."
		if not has("vis_matei"): return "Free Matei."
		if not has("vis_chalk") or not has("vis_scrap"): return "Matei says the sexton led people down the tunnel at night. Look around it."
		return "Climb back up to the churchyard. Matei is right behind you."
	if not has("vis_job"): return "Find Lorena in the village."
	if not ready_to_watch(): return "Why are the dogs silent? Look around (%d/%d) and ask the villagers (%d/%d)." % [clues_found(), CLUES.size(), asked(), WITNESSES.size()]
	if not has("vis_key"): return "Watch the old barn after dark."
	if not has("vis_crypt") or not has("vis_matei"): return "Open the cellar in the churchyard wall with the sexton's key."
	if not has("vis_done"): return "Go back to Lorena."
	return "Take the road south to Criț."

func marker(id: String) -> bool:
	if taken(): return id == "azorel" and has("v3_gate") and not has("v3_azorel")
	match id:
		"lorena": return not has("vis_job") or (has("vis_crypt") and has("vis_matei") and not has("vis_done"))
		"vbutcher", "goosewife", "caretaker": return has("vis_job") and not has("vis_w_" + id)
		"matei": return not has("vis_matei")
		"azorel": return not has("vis_azorel")
	return false

func pending(p: Prop) -> bool:
	if p.id == "lorenagate": return not has("v3_gate")
	if p.kind == "clue": return has("vis_job") and not has("vis_c_" + p.id)
	match p.id:
		"barn": return ready_to_watch() and not has("vis_key")
		"cryptdoor": return has("vis_key") and not (has("vis_crypt") and has("vis_matei"))
		"chalk": return has("vis_matei") and not has("vis_chalk")
		"mapscrap": return has("vis_matei") and not has("vis_scrap")
	return false

func arrive() -> void:
	if has("vis_arrive"): return
	mark("vis_arrive")
	G.start_dialogue("Viscri", [
		"Vlad's cart creaks to a halt where the lane meets the village. Vlad tips his hat and rolls on toward Bunești.",
		"Azorel will not get down. When you lift him, he quivers and presses against your leg.",
		"What's wrong, boy? Are you afraid? You can wait for me here.",
		"He lies down at the edge of the lane with his ears flat, watching the houses.",
		"It is very quiet. In a Saxon village at dusk, there should be dogs barking in every yard."])

func talk(id: String) -> bool:
	match id:
		"hamkeeper":
			G.start_dialogue("Old Greta", [
				"Counted them again this morning. Every side of bacon where it should be. First time in a month.",
				"Sunday we cut, as always. You'll have a slice from mine.",
			] if has("vis_crypt") else [
				"(An old woman with a ring of keys counts the sides of bacon hanging in the tower, moving her lips.)",
				"This is the Speckturm. Every house in Viscri hangs its bacon here, stamped with the house number, and on Sunday after church each family cuts its slice. Not before.",
				"Three sides gone this month, and no lock broken. Somebody with a key, or somebody the dogs don't bark at."])
		"storeman":
			G.start_dialogue("Georg", [
				"Each family has its chest of grain here inside the wall. If the Turks come, or fire, the village eats for a year.",
				"My grandfather stood on that walkway in a siege. I air wheat. I'm told that's progress."])
		"fortkid":
			G.start_dialogue("Children", ["The geese sleep now! We're not allowed to chase them anyway. We're chasing them anyway."] if has("vis_crypt") else [
				"(Three children herd the geese in circles and call it a game.)",
				"The geese shout at the old barn every night. Mother says geese saved Rome. Father says geese are stupid."])
		"vsmith":
			G.start_dialogue("Hannes, smith", [
				"(He takes your blade without asking, sights down the edge and hands it back.)",
				"Good steel, badly kept. A summer of cutting bread and rope, by the look of it.",
				"Toader the peddler has a whetstone on his cart, by the troiță. Use it before you need the edge, not after."])
		"azorel":
			if taken():
				if not has("v3_gate"): G.start_dialogue("Azorel", ["(Azorel is lying across Lorena's step. He lifts his head when he sees you, and does not get up.)"])
				else:
					G.start_dialogue("Azorel", [
						"(There is blood in the fur of his shoulder, and a scrap of very old, very good black cloth in his teeth. He would not let go of it for the neighbours. He lets go of it for you.)",
						"(You wash the shoulder at the well and bind it with the last of Magda's bandage. He stands for it, shaking, looking down the road the whole time.)",
						"(When you pick up your stick he is already at the gate. Limping. Ahead of you.)",
					], func():
						mark("v3_azorel"); Hud.toast("Azorel is coming with you.")
						var az = G.level.prop_by_id("azorel")
						if az: az.follow(true))
				return true
			mark("vis_azorel")
			G.start_dialogue("Azorel", ["Azorel leans his whole weight against Lorena's knees and thumps his tail on her doorstep."] if has("vis_done")
				else ["Azorel stays flat on the ground. He licks your hand but will not get up."])
		"lorena": _lorena()
		"vbutcher":
			_witness(id, "Hans, the butcher", [
				"Meat goes missing from my shop at night. Offal, trimmings, whole shoulders. Three nights now.",
				"No broken door, no broken lock. Whoever it is has a key, or a friend with one.",
				"And my dogs slept through it. My dogs! They would bark at their own shadows."])
		"goosewife":
			_witness(id, "Katharina, the goose-keeper", [
				"The dogs are useless now, but my geese are not. Every night they scream at the old barn on the church lane.",
				"Always after dark, always someone walking past it. I am too old to go and look.",
				"In my grandmother's time they said a goose is a better watchman than any dog. She was right."])
		"caretaker":
			_witness(id, "Michael, the church caretaker", [
				"(He keeps looking over his shoulder at the bell tower.) The sexton? He has not rung the evening bell in three days.",
				"He sleeps in the day and walks at night. When I spoke to him he did not seem to see me.",
				"And his key to the cellars under the churchyard wall is gone from its nail. He swears he lost it."])
		"matei":
			if not has("vis_matei"):
				G.start_dialogue("Matei", [
					"(A boy chained to a ring in the wall. He shrinks back until he sees you are not the sexton.)",
					"He fed the dogs so they would not bark. Then he came for me, because I saw him.",
					"He takes people down here at night. Grown men, walking like they are asleep. Down the tunnel, that way, west.",
					"(You break the rusted chain from the wall.)",
				], func():
					mark("vis_matei"); Hud.toast("Matei is free. He is right behind you.")
					var m = G.level.prop_by_id("matei")
					if m: m.follow(true))
			else:
				G.start_dialogue("Matei", ["Can we go home now? I am so hungry. (Then, quietly:) He wasn't asleep, you know. The sexton. He counted little bags every night and wrote it in a book." if has("vis_crypt") else "He is still down here. I can hear his bell rope dragging."])
		_: return false
	return true

func _lorena() -> void:
	if has("bt_done") and not has("bt_home"):
		G.start_dialogue("Lorena", [
			"(Lorena is at the gate before you're through it. Azorel gets there first, and nearly knocks you flat.)",
			"You're back. You're back, and you smell of... (She sniffs.) Plums? Smoke? Sheep, still. And something like church.",
			"We heard the bells. All of them, all down the valley, in the middle of the night. Even ours. The old women are still crying in the street.",
			"(You tell her. Not all of it. Not the trousers. Not yet.)",
			"(She takes your hand, and Azorel leans on your leg with his whole weight, the way he does, and the three of you go in.)",
			"Supper. Then sleep. Then you can tell me about the trousers.",
		], func(): mark("bt_home"); G.ending_t = 0.0; G.state = G.State.ENDING)
	elif not has("vis_job"):
		G.start_dialogue("Lorena", [
			"(Lorena runs out of the gate and throws her arms round you.) You came! You smell of sheep and bacon.",
			"I would make you supper, but listen first. Something is wrong here.",
			"The dogs have not barked for three nights. Not one. They sleep all day in the yards, fat as priests.",
			"And Matei, the stable boy from the farm by the church lane, is gone. His mother has been to the church every hour.",
			"People here say it is nothing. Nobody wants to say what they are thinking. Will you look into it?",
		], func(): mark("vis_job"); Hud.toast("New quest: The Silent Dogs"))
	elif has("vis_crypt") and has("vis_matei") and not has("vis_done"):
		G.start_dialogue("Lorena", [
			"Listen! (Down the street a dog barks, then another, then every yard in the village at once.)",
			"(Matei is off down the street before anyone can stop him, shouting for his mother. Every dog in the village runs with him.)",
			"(Azorel trots up the lane, past you, and leans against Lorena's leg.)",
			"You protected me the whole summer from wolves and bears. You deserve a break, boy.",
			"He stays with me, then. And you take this. (She unrolls a map she drew herself: every village on the road to Biertan, and the troițe at the crossroads.)",
			"Pray at a troiță and you will find your way back to any of them. Come back to me, and not in pieces.",
			"The church caretaker brought this too. The sexton's cellar key. He said it should go with you, not stay here.",
		], func():
			mark("vis_done"); mark("map_unlocked"); mark("token_cellar_key")
			var m = G.level.prop_by_id("matei")
			if m:
				m.follow(false)
				var home: Vector2 = G.level.church_lane() if G.level.has_method("church_lane") else m.pos + Vector2(-500, 300)
				m.walk(G.level.find_path(m.pos, home, 8.0, m), 150.0, func(): m.retire())
			G.player.coins += 20
			Audio.sfx("coin", -4.0)
			Hud.toast("Quest complete: The Silent Dogs.  Map unlocked.  Token: the cellar key"))
	elif has("vis_done"):
		G.start_dialogue("Lorena", ["The road south goes to Criț. Go on, before I change my mind and keep you here too."])
	else:
		G.start_dialogue("Lorena", ["A key? The sexton's? Then the church... be careful." if has("vis_key") else "Ask around. The butcher, the goose woman, old Michael at the church. They all know something."])

func _witness(id: String, who: String, lines: Array) -> void:
	if not has("vis_job"):
		G.start_dialogue(who, ["Good evening, stranger. Mind the dogs. (The dog by the door does not even open its eyes.)"])
		return
	var first := not has("vis_w_" + id)
	G.start_dialogue(who, lines, func():
		mark("vis_w_" + id)
		if first: Hud.toast("Villagers asked %d/%d" % [asked(), WITNESSES.size()] + (". Watch the old barn after dark." if ready_to_watch() else "")))

func use(p: Prop) -> void:
	if p.id == "lorenagate":
		mark("v3_gate")
		G.start_dialogue("Lorena's gate", [
			"(The gate is open. Lorena never leaves the gate open.)",
			"(In the yard: a chair on its back. A pot lid. The washing line down. And on the step, a head of garlic, bitten clean in half, as if somebody had been trying to feed it to somebody.)",
			"(The door has been pulled shut again from outside, quite politely.)",
			"A neighbour, over the fence: A gentleman, in the middle of the night. Tall. Lovely manners. He was bleeding from the hand something terrible, and she was calling him names I haven't heard since my father's day.",
			"He kept saying \"Madam, please.\" Off toward Sighișoara. On foot, and fast, and I'd say not enjoying it.",
		])
		return
	if p.id == "v3road":
		if not has("v3_azorel"): G.start_dialogue("The road to Sighișoara", ["Not without the dog."])
		else: Loader.goto_level("sighisoara")
		return
	if p.kind == "clue":
		if not has("vis_job"):
			G.start_dialogue("Viscri", ["You should find Lorena first."])
			return
		if has("vis_crypt"):
			# after the sexton: the village is waking up, and the clues say so
			match p.id:
				"geese": G.start_dialogue("Geese", ["The geese have gone quiet. One of them tucks its head under a wing and sleeps, for the first time in days."])
				"dog": G.start_dialogue("Yard dog", ["The dog is awake now, sitting up in its straw. It growls once at the church hill, then thumps its tail when you come close.", "Somebody has set a bowl of water by it. Just water."])
				_: G.start_dialogue("Meat scraps", ["Somebody has raked the scraps into a heap and thrown ash over it. The trail is gone."])
			return
		var first := not has("vis_c_" + p.id)
		mark("vis_c_" + p.id)
		var after := func():
			if first: Hud.toast("Clue %d/%d" % [clues_found(), CLUES.size()] + (". Watch the old barn after dark." if ready_to_watch() else ""))
		match p.id:
			"geese": G.start_dialogue("Geese", ["The geese in the pen crane their necks toward the old barn on the church lane, hissing at nothing you can see.", "The dogs in the yards around them do not stir."], after)
			"dog": G.start_dialogue("Sleeping dog", ["A big yard dog asleep in its straw, belly round as a drum. It does not wake when you crouch next to it.", "Its muzzle smells of fresh blood and raw pork. Somebody has been feeding it well."], after)
			_: G.start_dialogue("Meat scraps", ["Scraps of raw meat in the mud, every few steps. Fresh, not dragged by a dog.", "The trail runs between the farms and up the lane toward the church hill."], after)
		return
	match p.id:
		"barn":
			if G.level.get("watching") == true: return
			if not ready_to_watch(): G.start_dialogue("Old barn", ["An old barn on the church lane, its doors hanging. The hay inside is dry and deep."])
			elif has("vis_key"): G.start_dialogue("Old barn", ["Your hollow is still pressed into the hay."])
			else:
				var after := func():
					G.start_dialogue("The old barn, after dark", [
						"He moved stiffly, like a man walking in his sleep.",
						"You wait until he is gone and search the mud by the geese. An old iron key, worn smooth: the sexton's key.",
					], func(): mark("vis_key"); Hud.toast("The sexton's key. The cellar door is in the churchyard wall."))
				G.start_dialogue("The old barn, after dark", [
					"You burrow into the hay and wait. The village goes dark, one window at a time.",
					"Near midnight, somebody comes down the lane with a sack.",
				], func():
					if G.level.has_method("watch_barn"): G.level.watch_barn(after)
					else: after.call())
		"cryptdoor":
			if not has("vis_key"): G.start_dialogue("Cellar door", ["A low oak door in the churchyard wall, banded with iron and locked."])
			elif has("vis_crypt") and has("vis_matei"): G.start_dialogue("Cellar door", ["Cold air breathes out of the dark. Nothing moves down there now."])
			else: Loader.goto_level("crypt")
		"chalk":
			mark("vis_chalk")
			G.start_dialogue("Chalk sign", ["A chalk arrow on the tunnel wall, pointing west, and a cross drawn upside down beside it.", "The tunnel was bricked up long ago. Someone has opened it again."])
		"mapscrap":
			mark("vis_scrap")
			G.start_dialogue("Torn map", ["A scrap of an old map, torn across. A road, a ring of walls, and one word you can read: BIRTHÄLM.", "Biertan."], func(): Hud.toast("Whatever is doing this, it leads to Biertan."))
		"road":
			if not has("vis_done"): G.start_dialogue("The road south", ["Not yet. Lorena is still waiting for news."])
			else: Loader.goto_level("crit")
