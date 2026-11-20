## Moves between levels with a fade and sets each one up: camera, music, the hour, the market stall, autosave.
## Autoloaded as Loader.
extends Node

const MUSIC := {
	"music_hub": ["hub", "richis", "mosna", "sighisoara", "viscri", "crit", "saschiz", "sapartoc", "apold", "cris", "malancrav", "richisvillage"],
	"music_forest": ["forest", "critforest", "crisforest", "richisforest", "ieleridge", "uriasi", "walls", "biertanfort", "hillchurch"],
	"music_boss": ["arena"], "music_hills": ["hills"], "music_cave": ["caves", "cellar", "crypt", "malcrypt", "tunnel"],
	"music_muma": ["hollow"], "music_vineyard": ["vineyard"], "music_balaur": ["gorge"],
	"music_biertan": ["biertan"], "music_vlad": ["church", "sacristy"],
}

## True while the level the game opens with is being built: a test drop, not an arrival by road.
var direct_start := false

func exists(level_id: String) -> bool:
	return ResourceLoader.exists("res://scripts/levels/%s.gd" % level_id)

## Go to a level; `at` (map pixels) overrides its own spawn point.
func goto_level(level_id: String, at = null) -> void:
	if G.transitioning: return
	if not exists(level_id):
		Hud.toast("The road to '%s' is not open yet." % level_id)
		return
	G.transitioning = true
	await Hud.fade_to(1.0, 0.35)
	var from := G.current
	if G.RECAP_AFTER.has(from) and G.side_has(G.RECAP_AFTER[from]) and not G.side_has("recap_" + from) and not G.instant:
		G.side_add("recap_" + from)
		await G.show_story("recap_" + from)   # the story so far, on the road between villages
	var act := _act_card(level_id)
	if act != "" and not G.instant:
		G.side_add(act)
		await G.show_story(act)   # a new act begins: its title card
	var dest := level_id
	if at == null and not G.instant and from != "road_stretch":
		var route := "%s_%s" % [from, level_id]
		if route in ["sighisoara_viscri", "viscri_crit", "crit_saschiz", "saschiz_sapartoc", "apold_cris"] and not G.side_has("road_" + level_id):
			var rs: GDScript = load("res://scripts/levels/road_stretch.gd")
			rs.set("route_key", route)
			rs.set("next_dest", level_id)
			dest = "road_stretch"
	unload()
	Hud.loading("On the road...")
	await get_tree().process_frame   # let the old level go
	await get_tree().process_frame   # and let the line reach the screen before the build blocks it
	enter(dest, at)
	Hud.loading("")
	G.state = G.State.PLAY
	await Hud.fade_to(0.0, 0.35)
	G.transitioning = false

func unload() -> void:
	if is_instance_valid(G.level):
		G.level.get_parent().remove_child(G.level)
		G.level.queue_free()
	G.level = null
	G.boss = null
	G.current = ""

func enter(level_id: String, at = null) -> void:
	var script: GDScript = load("res://scripts/levels/%s.gd" % level_id)
	var level: Level = script.new()
	level.id = level_id
	level.name = "Level " + level_id
	G.current = level_id
	G.side_add("seen_" + level_id)   # the map lets him travel back to places he has been
	G.level = level
	G.midnight_done = false
	get_tree().current_scene.add_child(level)
	level.build()
	_add_stall(level)
	Road.dress(level)
	_clear_quest_spots(level)
	if level is Village: level.compact()
	WorldBuilder.build(level)
	level.built = true

	var p: Player = G.player
	p.pos = at if at != null else level.spawn
	p.vel = Vector2.ZERO
	p.madness = 0.0; p.blood = 0.0; p.vamp_t = 0.0; p.haste_t = 0.0
	get_tree().current_scene.snap_camera()

	for track in MUSIC:
		if level_id in MUSIC[track]: Audio.set_music(track, -9.0)
	if level_id == "richis": G.visited_richis = true
	if level_id == "mosna": G.visited_mosna = true
	if level_id == "biertan": G.visited_biertan = true
	if Mats.is_village(level_id):
		G.dusk = 0.45
		G.save_game()
	elif level_id == "hills" and G.dusk < 0.2: G.dusk = 0.2
	elif level_id == "vineyard" and G.dusk < 0.45: G.dusk = 0.45
	elif level_id == "forest" and G.dusk < 0.15: G.dusk = 0.15
	WorldBuilder.apply_darkness(level)
	if is_instance_valid(G.player): G.player.unarmed = false
	level.on_enter()
	_azorel_at_heel(level)
	Hud.banner(level.title, level.subtitle)
	Narration.arrive(level_id)

## Once Lorena is taken, Azorel goes everywhere with the hunter (unless a place walks him itself).
func _azorel_at_heel(level: Level) -> void:
	if not G.side_has("v3_azorel") or "follower" in level or level.id in ["stana", "hillchurch"]: return
	var a := level.prop_by_id("azorel")
	if a == null: a = level.add_prop("npc", "azorel", "Azorel", level.spawn + Vector2(-60, 40), "E   Azorel", Color("d8d0c0"))
	a.pos = G.player.pos + Vector2(-60, 40)
	a.follow(true)

## A market stall by the troiță of every village on the road: the shop sits where people already stop.
func _add_stall(level: Level) -> void:
	if not Shop.STALLS.has(level.id): return
	var st: Dictionary = Shop.STALLS[level.id]
	var c := level.spawn
	for p in level.props:
		if p.kind == "troita":
			c = p.pos
			break
	var at := c + Vector2(150, 40)
	for i in 16:
		var a := i * PI / 8.0; var r := 360.0 + (i / 8) * 140.0   # near the troiță, but with room between them
		var q := c + Vector2(cos(a), -sin(a)) * r
		if level.is_free(q, 46.0) and level.is_free(q + Vector2(0, -40), 40.0):
			at = q
			break
	level.add_decor(at + Vector2(0, -34), "stall", 30.0)
	level.add_prop("npc", "shop_" + level.id, st.keeper, at, "E   Trade with " + st.keeper.split(",")[0])

## Clutter never boxes in something you have to use: decorations standing on top of a person, a clue or a task
## keep their looks but lose their collision, so the spot can be walked up to from any side.
func _clear_quest_spots(level: Level) -> void:
	for d in level.decors:
		for p in level.props:
			if p.kind in ["npc", "task", "clue", "troita"] and d.pos.distance_to(p.pos) < 60.0:
				d.set_solid(false)
				break

## The title card of the act that starts on arriving at level_id, once each.
func _act_card(level_id: String) -> String:
	if level_id == "biertanfort" and not G.side_has("bt_arrive") and not G.side_has("act_2"): return "act_2"
	if level_id == "gorge" and G.side_has("bt_fled") and not G.side_has("act_3"): return "act_3"
	if level_id == "viscri" and VisQuest.taken() and not G.side_has("act_4"): return "act_4"
	return ""
