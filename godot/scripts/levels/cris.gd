## Criș (Keresd): the castle village where half the street has gone soft in the head on this year's rye.
## Quest: Muma Pădurii and the Feast. The forest lies west, past the last houses.
extends Village

const SQUARE := Vector2(11500, 6900)

func build() -> void:
	title = "CRIȘ"
	subtitle = "Keresd · Muma Pădurii and the Feast"
	quest = CsQuest.new()
	arrive_flag = "cs_arrive"
	standard("cris", 1452)
	churches_and_houses()
	spawn = free_spot(Vector2(14600, 7600), 120.0)   # the road from Apold comes in from the east
	graves_and_trees()
	_quest_things()
	finish()

func _quest_things() -> void:
	var has := func(f: String) -> bool: return G.side_has(f)
	var church: Vector2 = m.boxes("churches")[0].c
	var sq := free_spot(SQUARE, 60.0)
	add_prop("npc", "gheorghe", "Gheorghe · Forester", sq, "E   Speak with Gheorghe", Color("4a5a3a"))
	add_torch(sq + Vector2(0, -60), 260.0, Color(1, 0.65, 0.35), 0.6)
	if not has.call("cs_wolves"): add_prop("npc", "magda", "Magda", free_spot(spawn + Vector2(-160, 40), 40.0), "E   Speak with Magda", Color("8a3a4a"))
	var den := free_spot(Vector2(11000, 3600), 50.0)
	add_prop("npc", "denisa", "Denisa · Herbalist", den, "E   Speak with Denisa", Color("5a4a5a"))
	add_decor(den + Vector2(110, -30), "herb_string")
	add_torch(den + Vector2(0, -40), 200.0, Color(1, 0.7, 0.4), 0.5)
	if not has.call("cs_wolves"):
		var oak := free_spot(Vector2(9300, 6300), 60.0)
		add_tree(oak + Vector2(0, -70))
		add_prop("npc", "oakman", "A man hugging an oak", oak + Vector2(40, 10), "E   Watch him")
		var hen := free_spot(Vector2(10300, 5200), 40.0)
		add_prop("npc", "henwoman", "Gheorghe's cousin", hen, "E   Watch her")
		add_decor(hen + Vector2(50, 25), "hat_egg")
		var gs := free_spot(Vector2(12400, 4400), 60.0)
		add_prop("npc", "goose1", "A neighbour", gs + Vector2(-70, 0), "E   Listen")
		add_prop("npc", "goose2", "Another neighbour", gs + Vector2(70, 0), "E   Listen")
		add_decor(gs + Vector2(0, 50), "goose_honk")
		var fm := free_spot(Vector2(8800, 8300), 60.0)
		add_decor(fm + Vector2(90, -20), "scarecrow", 14.0)
		add_prop("npc", "farmer", "A farmer", fm, "E   Watch him")
		add_prop("npc", "towerkid", "A small boy", free_spot(church + Vector2(0, 400), 40.0), "E   Ask him what he sees")
		var rye := free_spot(Vector2(12600, 6200), 40.0)
		add_decor(rye, "rye_sheaf"); add_decor(rye + Vector2(70, 10), "rye_sheaf", 0.0, true)
		add_prop("task", "rye", "This year's rye", rye + Vector2(30, 50), "E   Look at the rye")
	else:
		# the feast: the bad rye burns and the whole street sits down to eat
		var rye := free_spot(sq + Vector2(420, -40), 60.0)
		add_decor(rye, "rye_fire", 30.0)
		add_torch(rye, 420.0, Color(1, 0.55, 0.25), 1.0)
		var tb := free_spot(sq + Vector2(0, 220), 80.0)
		add_decor(tb, "long_feast", 50.0)
		add_decor(tb + Vector2(-90, -10), "wine_mug"); add_decor(tb + Vector2(110, 0), "wine_mug")
		var guests := ["oakman", "henwoman", "goose1", "goose2", "farmer", "towerkid"]
		for i in guests.size():
			add_prop("npc", guests[i], "A villager", tb + Vector2(-300 + i * 100, -90 if i % 2 == 0 else 90), "E   Talk")
		add_prop("npc", "feaster", "A villager", tb + Vector2(360, 20), "E   Talk")
	if has.call("cs_done"): add_decor(free_spot(SQUARE + Vector2(-700, 500), 60.0), "hay", 30.0)
	# the way to the forest: the west road, where the beeches begin
	var gate := nearest_road_point(Vector2(2600, 3300))
	CsQuest.forest_gate = gate
	add_decor(gate + Vector2(0, -80), "troita", 22.0)
	add_prop("task", "forest", "The forest", gate, "E   Go into the forest")
	add_prop("troita", "troita", "Troiță", gate + Vector2(120, -60), "E   Pray at the troiță")
	add_prop("task", "road", "The road south", free_spot(Vector2(11800, 15400), 40.0), "E   Take the road to Mălâncrav")

func feast() -> void:
	G.side_add("cs_done"); G.side_add("token_muma_twig")
	G.player.coins += 25
	Audio.sfx("coin", -4.0)
	Hud.toast("Quest complete: Muma Pădurii and the Feast.  Token: a twig from Muma's oak")
	Loader.goto_level("malancrav")   # the feast cuts to black, straight into the haystack morning
