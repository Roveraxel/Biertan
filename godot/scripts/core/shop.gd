## A market stall in every village on the road. Each sells tinctures, a whetting for the blade and a sheepskin
## lining, and one thing the village is known for. Whettings and linings are counted for the whole road and
## each costs more than the last, so coins from the jobs turn into a hunter who can take the later bosses.
class_name Shop
extends RefCounted

const MAX_WHET := 6
const MAX_LINING := 5
const STALLS := {
	"sighisoara": {"keeper": "Meister Georg, cutler", "figure": "npc_radu", "hello": "Blades from the Cutlers' Tower, tinctures from the apothecary next door. Coin first, hunter.", "special": "salt", "line": "Salt from the Praid mines, blessed at the Church on the Hill. Three pinches for ten."},
	"viscri": {"keeper": "Konrad, peddler", "figure": "npc_toader", "hello": "I go village to village with what people forget they need.", "special": "garlic", "line": "A wreath of garlic. A strigoi's teeth slide off it. Forty coins."},
	"crit": {"keeper": "Veta, herb seller", "figure": "npc_veta", "hello": "Herbs from the hill, cut before sunrise. That is the only way they work.", "special": "salt", "line": "Salt, three pinches for ten. Throw it where they walk."},
	"saschiz": {"keeper": "Michael, potter", "figure": "npc_petru", "hello": "Blue Saschiz pots, and whatever else fits on the cart.", "special": "salt", "line": "Salt, three pinches for ten."},
	"sapartoc": {"keeper": "Andreas, herdsman", "figure": "npc_andreas", "hello": "Cheese, wool, and a stone for your blade. The cows give me nothing else to sell.", "special": ""},
	"apold": {"keeper": "Sofia, baker", "figure": "npc_sofia", "hello": "Bread for the living, colaci for the dead. And tinctures, for the ones in between.", "special": ""},
	"cris": {"keeper": "Vasile, charcoal burner", "figure": "npc_vasile", "hello": "Charcoal, whetstones, and tinctures my wife makes. Don't eat the rye bread here.", "special": ""},
	"malancrav": {"keeper": "Hans, apple grower", "figure": "npc_hans", "hello": "Apples from the Apafi orchard, and a few things for people in your trade.", "special": ""},
	"richisvillage": {"keeper": "Ileana, weaver", "figure": "npc_ileana", "hello": "You're going up to the ridge? Then listen to me before you go.", "special": "wormwood", "line": "Pelin. Wormwood, tied at the belt. The Iele cannot bear its smell, and their song won't hold your legs. Forty coins."},
	"biertanfort": {"keeper": "Hannes, from Moșna", "figure": "npc_hannes", "hello": "Every family keeps its ham in the tower. I keep a few other things, for people who go into the church at night.", "special": "garlic", "line": "Garlic, braided for the neck. Forty coins."},
}

static func _count(prefix: String) -> int:
	var n := 0
	while G.side_has(prefix + str(n)): n += 1
	return n

static func whet_cost() -> int: return 20 + 15 * _count("whet")
static func lining_cost() -> int: return 25 + 15 * _count("lining")

static func open(village: String, again := false) -> void:
	if not STALLS.has(village): return
	var s: Dictionary = STALLS[village]
	var p: Player = G.player
	var opts := ["Tincture  (10 coins, you carry %d)" % p.potions]
	var acts: Array[Callable] = [Events.buy_potion]
	if _count("whet") < MAX_WHET:
		opts.append("Whet the blade  +3 damage  (%d coins)" % whet_cost()); acts.append(Shop._whet)
	if _count("lining") < MAX_LINING:
		opts.append("Sheepskin lining  +10 health  (%d coins)" % lining_cost()); acts.append(Shop._lining)
	var lines := ["Anything else?" if again else s.hello]
	if s.special == "salt":
		opts.append("Salt, three pinches  (10 coins)"); acts.append(Shop._salt)
		if not again: lines.append(s.line)
	elif s.special == "garlic" and not p.garlic:
		opts.append("Garlic wreath  (40 coins)"); acts.append(Events.buy_garlic)
		if not again: lines.append(s.line)
	elif s.special == "wormwood" and not p.wormwood:
		opts.append("Wormwood sprig  (40 coins)"); acts.append(Events.buy_wormwood)
		if not again: lines.append(s.line)
	opts.append("That's all, thanks" if again else "Nothing today")
	lines.append("You have %d coins." % p.coins)
	G.start_choice(s.keeper, lines, opts, func(i: int):
		if i >= 0 and i < acts.size():
			acts[i].call()
			Audio.sfx("coin", -4.0)
			# stay at the stall: the menu comes back until he says that's all
			G.get_tree().create_timer(0.05).timeout.connect(func(): if G.state == G.State.PLAY: Shop.open(village, true)))

static func _pay(cost: int) -> bool:
	return Events.pay(cost, "You need %d coins. Jobs and the creatures you put down pay." % cost)

static func _salt() -> void:
	if not _pay(10): return
	G.player.salt_unlocked = true
	G.player.salt += 3
	Hud.toast("Three pinches of salt.  R to throw")

static func _whet() -> void:
	if not _pay(whet_cost()): return
	G.side_add("whet%d" % _count("whet"))
	G.player.dmg += 3.0
	Hud.toast("Blade whetted.  Damage %d" % roundi(G.player.dmg))

static func _lining() -> void:
	if not _pay(lining_cost()): return
	G.side_add("lining%d" % _count("lining"))
	G.player.max_hp += 10.0
	G.player.hp += 10.0
	Hud.toast("Sheepskin lining sewn in.  Health %d" % roundi(G.player.max_hp))
