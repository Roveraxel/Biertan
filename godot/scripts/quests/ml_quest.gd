## "The Morning After", Mălâncrav. The hunter wakes without his trousers and reconstructs the night from four
## witnesses and three memories (each a short playable flashback), climbs the tower for his trousers, clears
## the crypt his bell-ringing woke, and keeps a drunken oath to Muma Pădurii.
class_name MlQuest
extends RefCounted

const WITNESSES := ["msexton", "orchard", "mbaker", "mchild"]
const FLASH := ["cup", "twig", "stones"]

static var crypt_door := Vector2.ZERO

static func has(f: String) -> bool: return G.side_has(f)
static func mark(f: String) -> void: G.side_add(f)

static func heard() -> int:
	var n := 0
	for w in WITNESSES:
		if has("ml_c_" + w): n += 1
	return n

static func remembered() -> int:
	var n := 0
	for f in FLASH:
		if has("ml_f_" + f): n += 1
	return n

static func unlocked(f: String) -> bool:
	match f:
		"cup": return has("ml_job")
		"twig": return has("ml_c_mchild")
		"stones": return has("ml_c_orchard")
	return false

func _flashing() -> bool:
	return G.current == "malancrav" and G.level.in_flashback

func _to(id: String, label: String) -> Array:
	return [G.level.spots[id], label] if G.level.spots.has(id) else []

func target() -> Array:
	if _flashing() or G.current == "malcrypt": return []
	if not has("ml_job"): return _to("petru", "Petru the farmer")
	if remembered() < FLASH.size() or heard() < WITNESSES.size():
		var l := []
		for w in WITNESSES:
			if not has("ml_c_" + w): l.append([w, "Somebody who saw you"])
		for f in FLASH:
			if not has("ml_f_" + f) and unlocked(f): l.append([f, "Something from last night"])
		var pl: Vector2 = G.player.pos
		var best := []; var bd := INF
		for it in l:
			if G.level.spots.has(it[0]) and pl.distance_to(G.level.spots[it[0]]) < bd:
				bd = pl.distance_to(G.level.spots[it[0]]); best = [G.level.spots[it[0]], it[1]]
		return best
	if not has("ml_pants"): return _to("tower", "The church tower")
	if not has("ml_crypt"): return _to("crypt", "The crypt")
	if not has("ml_moroi"): return _to("muma", "The edge of the village")
	if not has("ml_stake"): return _to("muma", "Muma Pădurii")
	if not has("ml_done"): return _to("msexton", "The sexton")
	return _to("road", "The road to Richiș")

func objective() -> String:
	if _flashing(): return G.level.flash_line()
	if G.current == "malcrypt": return G.level.line()
	if not has("ml_arrive"): return ""
	if not has("ml_pants") and not has("ml_job"): return "Find my pants.  (What happened last night?)"
	if not has("ml_pants") and (heard() < WITNESSES.size() or remembered() < FLASH.size()):
		return "Find my pants.  Last night: " + _timeline()
	if not has("ml_pants"): return "Find my pants. They are flying from the church tower."
	if not has("ml_crypt"): return "Something is stirring under the church. The crypt."
	if not has("ml_moroi"): return "Dusk. Moroi are hunting at the edge of the village."
	if not has("ml_stake"): return "Muma Pădurii is waiting for you at the edge of the village."
	if not has("ml_done"): return "The sexton wants a word about his bell rope."
	return "The road leads on to Richiș, and Biertan."

func _timeline() -> String:
	var parts := PackedStringArray()
	parts.append("the brawl at Criș" if has("ml_f_cup") else "? ? ?")
	parts.append(("the old woman at the forest edge" if has("ml_f_twig") else "an old woman at the forest edge? ? ?") if has("ml_c_mchild") else "? ? ?")
	parts.append(("the plum tree, the wolves, the tower" if has("ml_f_stones") else "a plum thief and wolves? ? ?") if has("ml_c_orchard") else "? ? ?")
	if has("ml_c_mbaker"): parts.append("a bear eating a loaf")
	return " → ".join(parts) + "  (witnesses %d/%d, memories %d/%d)" % [heard(), WITNESSES.size(), remembered(), FLASH.size()]

func marker(id: String) -> bool:
	match id:
		"petru": return not has("ml_job")
		"msexton", "orchard", "mbaker", "mchild":
			return (has("ml_job") and not has("ml_c_" + id)) or (id == "msexton" and has("ml_stake") and not has("ml_done"))
		"muma": return has("ml_moroi") and not has("ml_stake")
	return false

func pending(p: Prop) -> bool:
	if p.kind != "task": return false
	match p.id:
		"cup", "twig", "stones": return unlocked(p.id) and not has("ml_f_" + p.id)
		"tower": return remembered() == FLASH.size() and heard() == WITNESSES.size() and not has("ml_pants")
		"crypt": return has("ml_pants") and not has("ml_crypt")
	return false

func arrive() -> void:
	if has("ml_arrive"): return
	mark("ml_arrive"); mark("ml_pantsless")
	G.start_dialogue("Mălâncrav", [
		"(You wake up face-down in a haystack. Your mouth tastes of plums and regret. Something is very wrong.)",
		"(There is a draught. A specific draught.)",
		"Where are my trousers?",
	], func(): Hud.toast("New quest: The Morning After.  Find my pants."))

func talk(id: String) -> bool:
	match id:
		"petru":
			if not has("ml_job"):
				G.start_dialogue("Petru · Farmer", [
					"(A farmer with a pitchfork, trying very hard not to laugh.) Good morning, Your Majesty.",
					"You came at three in the morning. You stood on my gate and shouted that you were king of Mălâncrav. Then you dived into my haystack.",
					"Trousers? You had them at the gate. You did not have them in the haystack. What happened in between, ask the village. The whole village was awake.",
				], func(): mark("ml_job"); Hud.toast("What happened last night? Ask around."))
			else: G.start_dialogue("Petru · Farmer", ["Long live the king. (He bows, very low, shaking.)"])
		"msexton":
			if has("ml_stake") and not has("ml_done"):
				G.start_dialogue("The sexton", [
					"The crypt quiet. The bell rope spliced, by you, sober this time. I'll call it even.",
					"(He presses a heavy iron key into your hand.) The tower key. If a king climbs my tower again, let him use the door.",
					"And hunter: Biertan's bell answered ours. Whatever sleeps over there heard you. Go carefully.",
				], func():
					mark("ml_done"); mark("token_tower_key")
					G.player.coins += 25
					Audio.sfx("coin", -4.0)
					Hud.toast("Quest complete: The Morning After.  Token: the church tower key"))
			else:
				_witness("msexton", "The sexton", [
					"Three in the morning, the bell. MY bell. Rung like a wedding and a fire at once.",
					"And somebody shouting from the tower. Something about a king. I didn't go up. I'm not paid enough to go up at three in the morning."])
		"orchard":
			_witness("orchard", "The orchard keeper", [
				"A plum thief! In my top tree! He fell out of it like a sack of turnips, and the wolves came out of the dark after him.",
				"Funny thing. He fought them off with a branch and a barrel lid, singing. The plum stones are still all over the grass.",
				"(He looks at you. He looks at your legs. He decides not to say anything.)"])
		"mbaker":
			_witness("mbaker", "The baker", [
				"A bear. A BEAR sat outside my shop at two in the morning, eating a loaf, quite politely.",
				"And a man was singing to it. Love songs. Badly. (She looks at you.) It took the second loaf too."])
		"mchild":
			_witness("mchild", "A child", [
				"I saw you! You were talking to an old woman at the edge of the forest. A really ugly one.",
				"You told her she was beautiful. She went all red. Then the bear came. (Giggles.)"])
		"kidsa", "kidsb":
			G.start_dialogue("Children", ["Long live the king! (They run off shrieking.)" if has("ml_pants") else "(They point at your legs and laugh until they fall over.)"])
		"mgranny":
			G.start_dialogue("A grandmother", ["Better. Much better. Disgraceful, but better." if has("ml_pants") else "Shame! SHAME! A grown man, and a church right there! Cover yourself!"])
		"muma":
			if G.level.has_method("muma_talk"): G.level.muma_talk()
		"mbear":
			G.start_dialogue("The bear", ["(The bear from the snare. It has followed you all the way from Criș. It sniffs your coat, approves, and sits down.)"])
		_: return false
	return true

func _witness(id: String, who: String, lines: Array) -> void:
	if not has("ml_job"):
		G.start_dialogue(who, ["(They look at your legs, then very hard at your face.) Talk to Petru. It's his haystack."])
		return
	var first := not has("ml_c_" + id)
	mark("ml_c_" + id)
	G.start_dialogue(who, lines, func():
		if first: Hud.toast("Last night: %d/%d witnesses" % [heard(), WITNESSES.size()]))

func use(p: Prop) -> void:
	match p.id:
		"cup", "twig", "stones":
			if has("ml_f_" + p.id): return
			if not unlocked(p.id): G.start_dialogue(p.display, ["It means nothing to you. Yet."])
			else: G.level.flashback(p.id)
		"tower":
			if has("ml_pants"): G.start_dialogue("The church tower", ["Your trousers are back on you. The weathervane looks bare without them."])
			elif remembered() < FLASH.size() or heard() < WITNESSES.size(): G.start_dialogue("The church tower", ["Something brown flaps from the weathervane. You don't want to know. Not yet."])
			else: G.level.climb_tower()
		"crypt":
			if not has("ml_pants"): G.start_dialogue("The crypt stairs", ["Not without trousers. Some things are sacred."])
			elif has("ml_crypt"): G.start_dialogue("The crypt stairs", ["Quiet now. Let them sleep."])
			else: Loader.goto_level("malcrypt")
		"road":
			if not has("ml_done"): G.start_dialogue("The road", ["Not before the sexton has had his word."])
			else: Loader.goto_level("richisvillage")
