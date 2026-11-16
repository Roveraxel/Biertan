## Inside Casa Vlad Dracul on the square in Sighișoara: a low vaulted front room, a stove, a long table, an old
## portrait nobody will name. In the last act the baron sits here with his bandaged hand in a bowl of water.
extends Level

const DOOR := Vector2(550, 740)
var night := false   # the quest asks the place it is in whether midnight has come; not in here

func ambient() -> Color:
	return Color(0.62, 0.52, 0.44)

func build() -> void:
	title = "CASA VLAD DRACUL"
	subtitle = "The house with the dragon on its sign"
	size = Vector2(1100, 820)
	spawn = DOOR + Vector2(0, -230)
	ground = Color("2a2420")
	tile = ""
	quest = FinQuest.new()
	rng = NetRandom.new(1431)
	# the walls of the low front room, a doorway in the south wall
	add_block(Rect2(-200, -200, 1500, 380), "stone", 80.0)
	add_block(Rect2(-200, -200, 300, 1200), "stone", 80.0)
	add_block(Rect2(1000, -200, 300, 1200), "stone", 80.0)
	add_block(Rect2(-200, DOOR.y + 20, DOOR.x + 200 - 70, 300), "stone", 80.0)
	add_block(Rect2(DOOR.x + 70, DOOR.y + 20, 1300 - DOOR.x - 70, 300), "stone", 80.0)
	add_patch(Vector2(550, 470), Vector2(900, 580), "px_planks", Color(0.75, 0.6, 0.48), 1.2, -990, false)   # a plank floor
	# a stove in the corner, the long table, the portrait over it, shelves and barrels
	add_decor(Vector2(880, 250), "hearth", 40.0)
	add_torch(Vector2(880, 280), 380.0, Color(1, 0.55, 0.28), 0.9)
	add_decor(Vector2(550, 196), "portrait")
	add_prop("task", "portrait", "An old portrait", Vector2(550, 250), "E   Look at the portrait")
	add_decor(Vector2(550, 420), "table", 60.0)
	add_decor(Vector2(430, 440), "chair", 18.0); add_decor(Vector2(670, 440), "chair", 18.0, true)
	add_decor(Vector2(520, 400), "candles2"); add_decor(Vector2(600, 405), "wine_jug")
	add_torch(Vector2(550, 420), 280.0, Color(1, 0.7, 0.4), 0.7)
	add_decor(Vector2(200, 250), "shelf", 30.0); add_decor(Vector2(170, 560), "barrels", 40.0)
	add_decor(Vector2(330, 220), "candelabra"); add_decor(Vector2(770, 220), "candelabra")
	if G.side_has("fin_spirid") and not G.side_has("fin_lorena"):
		add_prop("npc", "baron", "The baron of Biertan", Vector2(670, 490), "E   Speak with the baron", Color("5a2030"))
	add_prop("task", "dracul_out", "Out to the square", DOOR, "E   Go out to the square")
	add_trigger(Rect2(DOOR.x - 70, DOOR.y + 30, 140, 40), leave)

func leave() -> void:
	var sc: GDScript = load("res://scripts/levels/sighisoara.gd")
	var d: Vector2 = sc.get("dracul_door")
	Loader.goto_level("sighisoara", d + Vector2(0, 70) if d != Vector2.ZERO else null)
