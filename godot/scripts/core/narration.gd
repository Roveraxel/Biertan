## Lorena tells the story: one spoken line under each picture of a story card (card id -> one line per panel),
## and a line when the hunter first walks into each of the wild places between the villages ("lvl_<id>").
## She is fond of him, and does not let him forget anything. The recordings are res://audio/voice/<key>_<n>.mp3,
## made with Fish Audio; a line without a recording is simply not spoken.
class_name Narration
extends RefCounted

const VOICE := "6d76b9c0a0c54f6a97a1c1748270cee1"   # Fish Audio voice: "Romania", warm storyteller (drama-3)

const LINES := {
	"prologue": ["Let me tell you about my hunter. That summer he was minding other people's cows on the high pastures, with a dog who thought he was the one in charge. He was right, of course. Azorel usually is."],
	"descent": ["At first light he gave the cows back, took his wage in coins and cheese, and walked north to Sighișoara. Looking for winter work, he said. Looking for trouble, I say. He found both."],
	"recap_sighisoara": [
		"In Sighișoara the butchers' guild was losing bacon, a slab a night, and nobody had seen the thief.",
		"My brave hunter followed flour footprints with long toes, all the way under the tower, and found the spiriduși. One of them stole his hat. He still will not talk about the hat.",
		"So the guild feeds the little ones now, and they sweep and mend at night. And at dawn Vlad's cart took him east. Towards me.",
	],
	"recap_cris": [
		"In Criș they burned the rye in the square and laid the tables, because the curse of the forest was lifted. By him. He was very proud. Somebody's uncle kept pouring.",
		"Then two boys from Mălâncrav shared a pipe with him behind the barn. It was not tobacco. The smoke danced, and so, I am told, did the hunter.",
		"And then the whole world turned round him, and my foolish hunter set off for Mălâncrav with a cup for the road. He remembers nothing after that. Luckily, the whole valley does.",
	],
	"flash_cup": ["It comes back in pieces. The table. The fiddles. The foolish hunter, standing on the table, dancing like a bear at a fair. The bench did not survive it."],
	"flash_twig": ["The forest edge, and Muma Pădurii herself. And what does my hunter do? He kneels in the moss and tells her she is the most beautiful woman in Transylvania. I have never been so jealous of a tree."],
	"flash_stones": ["The best plums are always at the top. The foolish hunter knew that. He did not know about the branch. Or about the wolves waiting underneath it."],
	"flash_stones2": ["And at the end of the night, the king of Mălâncrav, ringing the church bell for the whole valley. With his trousers on a stick for a flag. That is the man I am waiting for. God help me."],
	"act_2": ["Biertan. Three walls on one hill, a church on top like a ship, a busy friendly village. Not one dog. My hunter noticed that. Eventually."],
	"supper_biertan": [
		"The baron laid a long table under the walls. Roast meat, warm bread, wine from his own vines. Everything a man could want, except salt.",
		"He carved for my hunter, poured for him, asked about every village on his road, and never once took a bite himself. A brave man notices these things. My hunter noticed the pork first.",
	],
	"act_3": ["The baron went down the stair under his own tomb, and the hunter went after him. Through a gorge where the weather has a master, through the vineyards and the Wolf Forest, and under the ground, where a small pale dog was waiting."],
	"balaur_rise": [
		"In the quarry a beggar stood up and opened his book, and he was no beggar. A Solomonar, a master of storms.",
		"And out of the cloud came the balaur, with hail on its back and lightning in its teeth. My hunter drew his sabre. He told me later he was not afraid. He was."],
	"act_4": ["And then he came home to Viscri, and my gate was open, and I was gone. Azorel was lying on the step, with blood in his fur and a piece of black cloth in his teeth. He would not give it to anyone else. Only to the hunter."],
	"lvl_gorge": ["An old quarry east of Biertan, and a storm that would not move on. Somebody in that gorge was keeping it there on purpose."],
	"lvl_vineyard": ["The vineyards above the valley, after the harvest. Empty rows, and a table set for somebody who never comes home. Mind the vessels, hunter."],
	"lvl_forest": ["The Wolf Forest. Old beech, black paths, wolf sign everywhere. And snowdrops, in October. Even my hunter knew that was wrong."],
	"lvl_tunnel": ["Under the hills, a maze older than any church. No light, except one. A little dog who knows the way. Follow him, hunter, and for once, do as you are told."],
	"lvl_crisforest": ["The beech woods above Criș, where Muma Pădurii keeps her animals. Walk softly there. She hears everything."],
	"lvl_critforest": ["The woods above Criț, where the Friday is kept. Something there remembers every promise you ever broke."],
	"lvl_richisforest": ["The forest behind Richiș, all moss and green faces carved in the stone. Three children went in there, and did not come out."],
	"lvl_ieleridge": ["The ridge where the iele dance. Do not look at them, hunter. Do not listen. And whatever you do, do not dance."],
	"lvl_uriasi": ["Up the hill above Saschiz, in the giants' old fortress, something very big was playing with the village children. It did not want to stop."],
}

static func key_for(card: String, panel: int) -> String:
	return "%s_%d" % [card, panel]

static func path_for(card: String, panel: int) -> String:
	return "res://audio/voice/%s.mp3" % key_for(card, panel)

## Speak this card's line for the panel, if it has been recorded.
static func speak(card: String, panel: int) -> void:
	var p := path_for(card, panel)
	if ResourceLoader.exists(p): Audio.voice(load(p))
	else: Audio.voice(null)

## The first time he walks into a wild place, Lorena says a word about it.
static func arrive(level_id: String) -> void:
	var k := "lvl_" + level_id
	if not LINES.has(k) or G.side_has("heard_" + level_id): return
	G.side_add("heard_" + level_id)
	speak(k, 0)
