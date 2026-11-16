## What happens when the hunter uses something or talks to someone.
class_name Events
extends RefCounted

static func marker_for(npc: String) -> bool:
	return Quests.marker(npc)

static func prop_used(p: Prop) -> void:
	var player: Player = G.player
	if Road.use(p): return
	if p.kind == "gate" and WoodGate.use(p): return
	if p.kind == "troita":
		Hud.open_map(true)
		return
	if p.kind in ["clue", "task"]:
		Quests.use(p)
		return
	if p.id.begins_with("shop_"):
		Shop.open(p.id.substr(5))
		return
	match p.kind:
		"npc": Quests.talk(p.id)
		"sack":
			p.used = true
			player.coins += 15
			Audio.sfx("coin", -4.0)
			Hud.toast("A shepherd's coin sack.  +15 coins")
		"fleece":
			G.start_dialogue("Torn fleece", [
				"The wool is shredded. Three nights of throats opened, and not a drop of blood on the grass.",
				"Wolf prints circle the hut, but they stop where the moonlight ends. Something walks beside them."])
		"ewe":
			p.used = true
			G.side_add(p.id)
			Audio.sfx("blip", -2.0, 1.3)
			Hud.toast("You tie a cord to the ewe. It trots off toward Saschiz.  (%d / 3)" % G.ewes_found())
		"treasure":
			p.used = true
			G.side_add(p.id)
			Audio.sfx("coin", 0.0, 0.8)
			var found := G.treasures_found()
			var gold := 35 + 15 * found
			player.coins += gold
			Hud.toast("A haiduc's buried pot of coins!  +%d coins  (%d / 3)" % [gold, found])
			if found >= 3:
				player.dmg += 4.0
				Hud.banner("THE HAIDUC'S SILVER", "At the bottom of the last pot: a silver knife.  +4 damage")
		"spring":
			G.side_add("spring")
			player.max_hp += 15.0
			player.hp = player.max_hp
			Audio.sfx("potion", 0.0, 0.7)
			Fx.ring(player.pos, Color(0.6, 0.85, 1, 0.8), 60.0)
			Hud.toast("Cold, sweet water. You feel older and stronger.  +15 max health")
		"cross":
			p.used = true
			player.hp = player.max_hp
			Audio.sfx("potion", -4.0, 0.8)
			Fx.ring(player.pos, Color(1, 0.85, 0.5, 0.8), 60.0)
			G.start_dialogue("Wayside cross", [
				"A troiță of carved oak, painted with suns and a little roof against the rain. Someone has left bread at its foot.",
				"You stand a moment. The wind drops. Your wounds close."])
		"greenman":
			G.start_dialogue("The Green Man", [
				"A stone face wreathed in oak leaves, carved by Saxon masons three hundred years ago.",
				"Some say it guards the church from the wood. Some say the wood is watching through it."])
		"bones":
			p.used = true
			player.coins += 25
			player.potions += 1
			Audio.sfx("coin", -4.0)
			Hud.toast("A miner's purse and a stoppered flask.  +25 coins, +1 tincture")

# ------------------------------------------------------------------ buying

static func pay(cost: int, need: String) -> bool:
	if G.player.coins >= cost:
		G.player.coins -= cost
		return true
	Hud.toast(need)
	return false

static func buy_potion() -> void:
	if not pay(10, "You need ten coins."): return
	G.player.potions += 1
	Hud.toast("Garlic tincture bought.  -10 coins")

static func buy_salt() -> void:
	if not pay(10, "You need ten coins."): return
	G.player.salt += 3
	Hud.toast("Three pinches of salt.  -10 coins")

static func buy_garlic() -> void:
	if not pay(40, "You need forty coins."): return
	G.player.garlic = true
	Hud.toast("Garlic wreath.  Strigoi bite half as hard and cannot drink.")

static func buy_wormwood() -> void:
	if not pay(40, "You need forty coins."): return
	G.player.wormwood = true
	Hud.toast("Wormwood sprig.  The Iele's song no longer slows you.")
