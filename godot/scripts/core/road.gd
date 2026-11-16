## Things that travel the road with the hunter, whatever village he is in: Magda and Vlad with the cart,
## Lorena's notes left at the troițe, and the small bags of dark earth somebody keeps leaving one village ahead.
class_name Road
extends RefCounted

## Where the cart has pulled up: [what Vlad says, what Magda says].
const CART := {
	"crit": [
		["Vlad Laurențiu: You made good time. For a man on foot.", "Magda: Good time? We have been here since TUESDAY.", "Vlad: It is Wednesday, dragă.", "Magda: EXACTLY.", "(He hands her an apple without looking. She takes it without looking. Neither of them has stopped glaring.)"],
		["Magda: He drives like he is delivering eggs to a funeral. HAIDA, I tell him. Haida!", "Vlad, from the cart: The horse has only the four legs, Magda.", "Magda: (trying very hard not to smile) Then get a better horse."]],
	"sapartoc": [
		["Vlad Laurențiu: Seventy-seven souls and no shop. I could retire here.", "Magda: You could not sit still for one afternoon.", "Vlad: I sat still for you for three years before you noticed.", "(Magda opens her mouth, shuts it again, and goes to check a wheel that does not need checking.)"],
		["Magda: Three churches and not one of them open. I knocked at all of them. LOUDLY.", "Vlad: The whole valley heard, dragă.", "Magda: Good!"]],
	"cris": [
		["Vlad Laurențiu: Don't eat the bread. Magda had one slice and argued with a fence post for an hour.", "Magda: I WON that argument.", "Vlad: You did. I was very proud."],
		["Magda: You went into that forest and came out with a twig. A TWIG. I wait an hour for a twig?", "Vlad: She was worried. She walked to the last house and back eleven times.", "Magda: I was stretching my legs!"]],
	"richisvillage": [
		["Vlad Laurențiu: No note for you this time. I knocked at Lorena's in Viscri. The gate stood open and nobody came.", "Probably at the neighbours'. Still. Azorel did not come to the gate either, and that dog has never once missed my cart.", "(He turns his hat round in his hands, once.) I'll ask again on the way back."],
		["Magda: Frost in October and seven women dancing on a hill in their shirts. I told Vlad, I am not going up there.", "Vlad: I did not ask you to.", "Magda: You were ABOUT to.", "(He was not. He lets her have it. She knows he is letting her have it.)"]],
}

## Lorena's notes, pinned under a stone at the troiță.
const NOTES := {
	"crit": ["(A folded note under a stone at the foot of the troiță. Lorena's hand, small and straight.)",
		"\"Vlad says you walk like a man carrying a wardrobe. Azorel has eaten one of your boots. The left one. I am keeping the right in case you come back with one leg.\"",
		"\"Wear the scarf. L.\""],
	"sapartoc": ["(Another note, weighted with a pebble.)",
		"\"The dogs bark all night now. Thank you for that. Nobody in Viscri has slept since you left.\"",
		"\"Matei asks if you have killed anything yet. I told him you mostly talk to people. Eat something that is not cheese. L.\""],
	"apold": ["(A note, a little damp.)",
		"\"I heard about Saschiz. A giant. And you sat down and talked to it. Of course you did.\"",
		"\"Azorel sleeps on your side of the bed. He is warmer than you and complains less. L.\""],
	"malancrav": ["(A note. The paper has been folded and unfolded, as if somebody read it on the way.)",
		"\"Vlad tells me there was a feast in Criș. He would not tell me the rest, and Magda could not stop laughing long enough to.\"",
		"\"I will ask you myself. Bring the trousers. L.\""],
}

## Where the bags of earth lie: level -> spot.
const BAGS := {
	"viscri": Vector2(6790, 5880),        # behind the old barn
	"crisforest": Vector2(2420, 2180),    # in the wolves' lying-up place
	"malcrypt": Vector2(2180, 980),       # by the lower stair
	"ieleridge": Vector2(2000, 1010),     # at the edge of the ring
}

static func dress(level: Level) -> void:
	var id := level.id
	var magda_busy := id == "cris" and not G.side_has("cs_wolves")   # she is at the village edge, shouting
	if CART.has(id) and level.spots.has("shop_" + id) and not magda_busy:
		var st: Vector2 = level.spots["shop_" + id]
		var at := st + Vector2(330, 10)
		var tr := st
		for p in level.props:
			if p.kind == "troita": tr = p.pos
		var far := -1.0
		for i in 12:   # a clear spot beside the stall, on the side away from the troiță: no crowding round the cross
			var q := st + Vector2.from_angle(i * PI / 6.0) * 330.0
			if level.is_free(q, 120.0) and q.distance_to(tr) > far:
				far = q.distance_to(tr); at = q
		level.add_decor(at + Vector2(0, -40), "horse_cart", 70.0)   # the căruță and its horse
		var v := level.add_prop("npc", "road_vlad", "Vlad Laurențiu", at + Vector2(-55, 60), "E   Speak with Vlad")
		var mg := level.add_prop("npc", "road_magda", "Magda", at + Vector2(55, 60), "E   Speak with Magda")
		v.facing = Vector2(1, 0); mg.facing = Vector2(-1, 0)   # squared up to each other, as always
	if NOTES.has(id) and not G.side_has("note_" + id):
		for p in level.props:
			if p.kind == "troita":
				level.add_decor(p.pos + Vector2(46, 34), "letters")
				level.add_prop("task", "road_note", "A note", p.pos + Vector2(46, 60), "E   Read the note")
				break
	if BAGS.has(id) and not G.side_has("earth_" + id):
		level.add_decor(BAGS[id], "sacks")
		level.add_prop("task", "road_bag", "A small bag", BAGS[id] + Vector2(0, 34), "E   Look at the bag")

static func bags_found() -> int:
	var n := 0
	for k in BAGS:
		if G.side_has("earth_" + k): n += 1
	return n

## True when the thing used belongs to the road and has been dealt with here.
static func use(p: Prop) -> bool:
	var id: String = G.current
	match p.id:
		"road_vlad": G.start_dialogue("Vlad and Magda", CART[id][0])
		"road_magda": G.start_dialogue("Magda and Vlad", CART[id][1])
		"road_note":
			G.start_dialogue("Lorena's note", NOTES[id], func():
				G.side_add("note_" + id)
				_clear(p, "letters"))
		"road_bag":
			var n := bags_found()
			var lines := ["(A small linen bag, tied shut with candle wick, pushed half under the leaf mould. Inside: dark earth, cold, with the smell of a cellar that has been shut for a very long time.)"]
			match n:
				0: lines.append("(Not from here. The soil here is yellow clay. You turn it over twice and leave it where it lies.)")
				1: lines.append("(The same linen, the same knot as the one before. Somebody is carrying these along the road.)")
				2: lines.append("(A third. Whoever leaves them is always one village ahead of you.)")
				_: lines.append("(Four now, and every one of them where something went wrong. You keep this one.)")
			G.start_dialogue("A bag of earth", lines, func():
				G.side_add("earth_" + id)
				_clear(p, "sacks")
				Hud.toast("Bags of dark earth found: %d" % bags_found()))
		_: return false
	return true

static func _clear(p: Prop, sprite: String) -> void:
	var L: Level = G.level
	for d in L.decors.duplicate():
		if is_instance_valid(d) and d.sprite_name == sprite and d.pos.distance_to(p.pos) < 80.0: L.remove_decor(d)
	L.remove_prop(p)
