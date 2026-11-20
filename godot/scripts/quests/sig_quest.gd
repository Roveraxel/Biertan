## "The Stolen Bacon", Sighișoara's opening job. Look: four clues around the Butchers' Tower. Use things: the
## butcher and his wife, the child who saw "little men", a crate, a lantern lit at the hearth, the lever in the
## guild sign. Fight: the cellar under the tower, where a spiriduș steals the hunter's hat and the spiriduși
## faint rather than die. Then the captain's apology, the food-for-work deal brokered with the guild, and Vlad
## Laurențiu's cart to Viscri. Progress is kept as flags in G.side, so it saves with the game.
class_name SigQuest
extends RefCounted

const CLUES := ["flour", "grating", "hook", "smoke"]
const CLUE_TITLE := {"flour": "Footprints", "grating": "Cellar grating", "hook": "Empty hook", "smoke": "Smoke"}
const CLUE_TEXT := {
	"flour": ["Flour spilled across the butcher's yard, and in it bare footprints, smaller than a child's, with long toes.", "They lead toward the tower, and come back heavier: the heels sink deep."],
	"grating": ["A cellar grating by the tower. The candle in the window above leans toward it, though there is no wind.", "Air is moving down there. Somewhere below, there is another way in."],
	"hook": ["An iron smoking-hook, empty. Flies circle where a ham hung this morning.", "The hook is too high for a child, and the ladder is still chained."],
	"smoke": ["Smoke from the tower's vents sinks down into the yard instead of rising, as if something below is drawing it in.", "Someone has opened a way between the cellar and the street."],
}

static func has(f: String) -> bool: return G.side_has(f)
static func mark(f: String) -> void: G.side_add(f)

static func clues_found() -> int:
	var n := 0
	for c in CLUES:
		if has("sig_c_" + c): n += 1
	return n

func _to(id: String, label: String) -> Array:
	return [G.level.spots[id], label] if G.level.spots.has(id) else []

func target() -> Array:
	if G.current == "cellar":
		return [Vector2(2560, 600), "The bacon thieves"] if not has("sig_cellar") else [Vector2(115, 600), "Stairs up"]
	if G.current != "sighisoara": return []
	if not has("sig_notice"): return _to("notice", "Notice board")
	if not has("sig_job"): return _to("butcher", "Meister Thomas")
	if clues_found() < CLUES.size():
		var pl: Vector2 = G.player.pos
		var best := []; var bd := INF
		for c in CLUES:
			if not has("sig_c_" + c) and G.level.spots.has(c) and pl.distance_to(G.level.spots[c]) < bd:
				bd = pl.distance_to(G.level.spots[c]); best = [G.level.spots[c], "Butchers' Tower"]
		return best
	if not has("sig_wife"): return _to("butcherwife", "Frau Gertrud")
	if not has("sig_child"): return _to("child", "Mihai")
	if not has("sig_crate"): return _to("crate", "The crate")
	if not has("sig_flame"): return _to("hearth", "Gertrud's hearth")
	if not has("sig_lever"): return _to("sign", "Guild sign")
	if not has("sig_cellar"): return _to("cellar", "Cellar door")
	if not has("sig_deal"): return _to("butcher", "Meister Thomas")
	return _to("vlad", "Vlad's cart")

func objective() -> String:
	if not has("sig_notice"): return "Find work."
	if not has("sig_job"): return "Ask about the notice at the butchers' stall on the citadel square."
	if clues_found() < CLUES.size(): return "Look around the Butchers' Tower for signs of the thief (%d/%d clues)." % [clues_found(), CLUES.size()]
	if not has("sig_wife"): return "Ask the butcher's wife, Frau Gertrud, about it."
	if not has("sig_child"): return "Find little Mihai behind Frau Gertrud's kitchen."
	if not has("sig_open"): return "Get into the cellar under the Butchers' Tower."
	if not has("sig_cellar"): return "Get your hat back. Deal with the bacon thieves." if has("sig_hat_lost") else "Go down into the cellar."
	if not has("sig_deal"): return "Broker a deal for the spiriduși with Meister Thomas."
	return "Find Vlad Laurențiu's cart in the lower town and ride to Viscri."

func marker(id: String) -> bool:
	match id:
		"butcher": return (has("sig_notice") and not has("sig_job")) or (has("sig_cellar") and not has("sig_deal"))
		"butcherwife": return clues_found() == CLUES.size() and not has("sig_wife")
		"child": return has("sig_wife") and not has("sig_child")
		"captain": return not has("sig_cellar")
		"vlad": return has("sig_deal")
		"azorel": return not has("sig_azorel")
	return false

## Clues and tasks glint softly while there is still something to learn from them.
func pending(p: Prop) -> bool:
	if p.kind == "clue": return not has("sig_c_" + p.id)
	if p.kind != "task": return false
	match p.id:
		"notice": return not has("sig_notice")
		"crate": return has("sig_child") and not has("sig_crate")
		"hearth": return has("sig_crate") and not has("sig_flame")
		"sign": return has("sig_flame") and not has("sig_lever")
		"cellar": return has("sig_child") and not has("sig_cellar")
		"portrait": return not has("sig_portrait")
	return false

func talk(id: String) -> bool:
	match id:
		"azorel":
			G.start_dialogue("Azorel", ["Azorel's tail thumps the cobbles. He knows a cart when he smells one."] if has("sig_deal")
				else ["Stay here, boy. I'll be back for dinner.", "Azorel sighs through his nose, turns twice and lies down across the inn door."], func(): mark("sig_azorel"))
		"butcher":
			var who := "Meister Thomas, guild master"
			if not has("sig_job"):
				G.start_dialogue(who, [
					"You came about the notice? A shepherd with a knife on his belt. Good.",
					"Bacon keeps vanishing from the guild's storage under the Butchers' Tower. A side here, a sausage there, every night.",
					"Nobody has seen anything. The watch says rats. Rats do not untie a ham from its hook.",
					"Look around the tower first. Find out who it is and how they get in, and the guild pays.",
					"I'll walk down with you and wait at Gertrud's door. My legs are too old for this hill twice.",
				] if has("sig_notice") else ["Meat? The stall opens at dawn. If it is work you want, read the notice on the Clock Tower gate first."], func():
					if has("sig_notice"):
						mark("sig_job")
						if G.level.has_method("butcher_to_tower"): G.level.butcher_to_tower()
						Hud.toast("New quest: The Stolen Bacon.  L: journal"))
			elif has("sig_cellar") and not has("sig_deal"):
				G.start_dialogue(who, [
					"Spiriduși? Little house spirits, in my storage? And they were only hungry?",
					"Hm. My grandmother left a bowl by the hearth for them every night, and her sausages never went bad.",
					"Very well. The guild and the innkeeper will leave food out for them each night. In return they carry our goods between the market cellars and the tower before dawn. Tell your little friends.",
					"Here is your pay. And listen: the villages around the town are in trouble, worse than missing bacon. They are asking for people with sharp eyes.",
					"Viscri, then. My girl Lorena just moved there. I'll start with her village.",
					"Vlad Laurențiu, the merchant, is taking his cart that way. Ask him in the lower town.",
					"(Something tugs at your trouser leg. The spiriduș captain, hat in hand, holds up a bent tin button with great ceremony.)",
					"\"For when you come back.\" (You have no idea what it is for. You put it in your pocket.)",
				], func():
					mark("sig_deal"); mark("token_tin_button")
					G.player.coins += 25
					Audio.sfx("coin", -4.0)
					Hud.toast("+25 coins.  Quest complete: The Stolen Bacon.  Token: a bent tin button"))
			elif clues_found() < CLUES.size(): G.start_dialogue(who, ["The Butchers' Tower is on the west wall. Look before you dig."])
			else: G.start_dialogue(who, ["Gertrud feeds every child on this hill. If anyone has heard something, it is her."])
		"butcherwife":
			if clues_found() == CLUES.size() and not has("sig_wife"):
				G.start_dialogue("Frau Gertrud", [
					"Footprints in my flour? Smaller than a child's? I saw nothing, and neither did anyone else.",
					"Except little Mihai. He keeps saying 'little men, mother Gertrud, little men by the tower.' I thought he wanted a sausage.",
					"He is out by the woodpile behind my kitchen. Be gentle; he is frightened of the watch.",
				], func(): mark("sig_wife"))
			else:
				G.start_dialogue("Frau Gertrud", ["Find out what is happening at that tower before there is no bacon left for Christmas." if has("sig_job") else "If it is work you want, the guild master is at the stall on the square."])
		"child":
			if has("sig_wife") and not has("sig_child"):
				G.start_dialogue("Mihai", [
					"I am not lying. Little men, this big, with beards and red caps, carrying a ham like a coffin.",
					"They go in at the bottom of the Butchers' Tower, behind the big crate.",
					"It is dark inside. Frau Gertrud keeps her hearth going all day; you can light a lantern there.",
					"And the cellar door has a secret. The guild sign over it, the ox. Pull its tongue.",
				], func():
					mark("sig_child")
					Hud.toast("Mihai showed you the way: the crate, a lantern, the guild sign."))
			else:
				G.start_dialogue("Mihai", ["Are you going down there? Bring me back a red cap."] if has("sig_wife") else ["...", "(He stares at your knife and says nothing.)"])
		"captain":
			if not has("sig_cellar"):
				G.start_dialogue("Spiriduș-căpitan", [
					"(The captain sits up, sees you standing over him, and squeaks. He drags the rest of his band into a row by their beards.)",
					"All together now!",
					"SORRY, SORRY, WE WON'T TOUCH IT AGAIN. WE WERE JUST VERY HUNGRY.",
					"(The smallest one steps out of the row and holds up your hat, brushing the soot off it.) And sorry about the hat.",
					"You put your hat back on. It smells of bacon now.",
				], func():
					mark("sig_cellar"); mark("sig_hat_back")
					Hud.toast("Hat recovered. Tell Meister Thomas what you found."))
			else:
				G.start_dialogue("Spiriduș-căpitan", ["Food every night and honest work! The best deal a spiriduș ever had." if has("sig_deal") else "Will they feed us, big man? Ask them. Please."])
		"vlad":
			if not has("sig_deal"):
				G.start_dialogue("Vlad Laurențiu, merchant", ["Cloth, salt and needles, friend, all the way to the villages. Not today, though. Today I wait for my wheel to be mended."])
			else:
				G.start_dialogue("Vlad Laurențiu, merchant", [
					"Viscri? I go past it. Climb up, and bring the big dog; he can guard the salt.",
					"(You whistle. Azorel is at your side before the whistle ends.)",
				], func():
					mark("sig_left")
					Loader.goto_level("viscri"))
		_: return false
	return true

func use(p: Prop) -> void:
	if p.kind == "clue":
		var first := not has("sig_c_" + p.id)
		mark("sig_c_" + p.id)
		G.start_dialogue(CLUE_TITLE.get(p.id, p.id), CLUE_TEXT.get(p.id, ["..."]), func():
			if first: Hud.toast("Clue %d/%d" % [clues_found(), CLUES.size()] + (". Ask the butcher's wife." if clues_found() == CLUES.size() else "")))
		return
	match p.id:
		"notice":
			G.start_dialogue("Notice board", [
				"BRAVE PEOPLE WANTED FOR WORK. Good pay. Ask at the butchers' stall on the citadel square.",
				"Beneath it, in another hand: 'bring your own lantern'.",
			], func(): mark("sig_notice"))
		"crate":
			if not has("sig_child"): G.start_dialogue("Crate", ["A heavy crate of salt pushed hard against the foot of the tower."])
			elif not has("sig_crate"):
				mark("sig_crate")
				Audio.sfx("blip", -4.0, 0.6)
				G.start_dialogue("Crate", ["You put your shoulder to it and shove. Behind it, low in the wall, a hole no taller than your knee, with a smear of lard on its sill."])
		"hearth":
			if not has("sig_crate"): G.start_dialogue("Hearth", ["Gertrud's hearth. Something smoked and salty hangs in the chimney."])
			elif not has("sig_flame"):
				mark("sig_flame")
				G.player.torch = true
				Audio.sfx("blip", -4.0, 1.2)
				G.start_dialogue("Hearth", ["You light the lantern from Gertrud's hearth. It will do."])
		"sign":
			if not has("sig_flame"): G.start_dialogue("Guild sign", ["An ox's head carved in oak over the cellar door, its tongue lolling out. The butchers' guild of Schäßburg."])
			elif not has("sig_lever"):
				mark("sig_lever")
				Audio.sfx("bell", -16.0, 0.6)
				G.start_dialogue("Guild sign", ["You pull the ox's tongue. Somewhere inside the wall a counterweight drops, and the cellar door swings in on its own."], func(): mark("sig_open"))
		"cellar":
			if not has("sig_child"): G.start_dialogue("Cellar door", ["An iron-bound door under the tower, barred from the inside."])
			elif not has("sig_crate"): G.start_dialogue("Cellar door", ["Barred from the inside. Mihai said they go in behind the crate."])
			elif not has("sig_flame"): G.start_dialogue("Cellar door", ["Through the hole behind the crate you see nothing at all. You need a light."])
			elif not has("sig_open"): G.start_dialogue("Cellar door", ["Still barred. Mihai said the guild sign hides the secret."])
			elif has("sig_cellar"): G.start_dialogue("Cellar", ["Quiet down there now, apart from the drip of fat and somebody small snoring."])
			else: Loader.goto_level("cellar")
		"portrait":
			mark("sig_portrait")
			G.start_dialogue("Casa Vlad Dracul", [
				"The house where, they say, Vlad Dracul lived when the town was his. A portrait hangs in the dark hall.",
				"Someone has scratched out the face with a knife, again and again, until the board shows through. The scratches are fresh.",
			])
		"watch_keys":
			if not has("sig_keys"):
				mark("sig_keys")
				G.player.coins += 12
				G.player.potions += 1
				Audio.sfx("coin", -4.0)
				G.level.remove_prop(p)
				G.start_dialogue("Watchman's chest", [
					"(A brass key ring lies beside the guild crate—the night watchman's spare keys.)",
					"(Inside you find 12 coins and a fresh tincture left for the patrol. +12 coins, +1 tincture.)",
				])
		"clock_crow":
			if not has("sig_crow"):
				mark("sig_crow")
				G.player.coins += 15
				Audio.sfx("crow", -4.0)
				G.level.remove_prop(p)
				G.start_dialogue("Clock Tower crow", [
					"(You clap your hands; the black crow hops onto the parapet and drops a glinting silver coin from its beak.)",
					"(Every hour the wooden figurines of the Clock Tower turn above the gate—and the crows still steal whatever shines. +15 coins.)",
				])
