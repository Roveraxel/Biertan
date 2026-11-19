## The butchers' guild smoke-cellar under the Butchers' Tower in Sighișoara: the opening job's fighting half.
## Cold store (slip past the spiriduși carrying off the bacon), the first fight, the smokehouse with its
## swinging hams, then the Spiriduș-căpitan with his ladle, who winds up before each blow.
extends Level

const ROOMS := [Rect2(60, 500, 260, 200), Rect2(360, 300, 640, 600), Rect2(1080, 350, 520, 500), Rect2(1680, 250, 570, 700), Rect2(2330, 350, 420, 500)]
const CORRIDOR := Rect2(280, 530, 2100, 140)
const STORES := [
	[400, 340, "barrels"], [520, 330, "sacks"], [640, 340, "barrels"], [780, 330, "crate"], [930, 350, "sacks"],
	[400, 860, "crate"], [560, 870, "barrel"], [700, 860, "sacks"], [940, 850, "barrels"],
	[1120, 390, "crate"], [1560, 400, "barrel"], [1130, 820, "sacks"], [1560, 810, "crate"],
	[1740, 300, "firewood"], [1900, 290, "smoke_pit"], [2080, 300, "firewood"], [2200, 330, "barrels"],
	[1730, 900, "smoke_pit"], [1960, 910, "firewood"], [2190, 900, "smoke_pit"],
	# the cold store: what the spiriduși were after
	[450, 420, "hams_rack"], [600, 410, "sausage_rack"], [760, 420, "hams_rack"], [900, 440, "salt_barrel"],
	[470, 780, "ham_pile"], [640, 800, "chopping_block"], [820, 790, "shelf"], [960, 760, "fish_crate"],
	[120, 540, "ladder"], [1200, 420, "hook_empty"], [1480, 760, "spiridus_lantern"],
	# a pickle cellar corner: jars on shelves, a stump to sit on, a pallet table
	[830, 890, "jar_shelf"], [560, 640, "stump_stool"], [470, 660, "pallet_table"], [1100, 880, "jar_shelf"],
	# the captain's den
	[2420, 560, "ham_pile"], [2650, 520, "potlid"], [2700, 680, "red_cap"], [2470, 700, "spiridus_lantern"],
	[2380, 400, "sacks"], [2700, 420, "barrels"], [2690, 800, "crate"], [2390, 800, "barrel"],
]

var captain_down := false

func build() -> void:
	title = "THE SMOKE-CELLAR"
	subtitle = "Under the Butchers' Tower"
	size = Vector2(2800, 1200)
	spawn = Vector2(200, 600)
	ground = Color("24201c")
	tile = ""
	quest = SigQuest.new()
	rng = NetRandom.new(1521)
	# solid masonry wherever there is no room or passage
	for yi in 12:
		for xi in 28:
			var c := Rect2(xi * 100.0, yi * 100.0, 100, 100)
			if not _open(c): add_block(c, "stone", 70.0)
	add_block(Rect2(-600, -600, 4000, 600), "stone", 70.0)
	add_block(Rect2(-600, 1200, 4000, 600), "stone", 70.0)
	add_block(Rect2(-600, -600, 600, 2400), "stone", 70.0)
	add_block(Rect2(2800, -600, 600, 2400), "stone", 70.0)
	for s in STORES: add_decor(Vector2(s[0], s[1]), s[2], 22.0, rng.f() < 0.5)
	add_torch(Vector2(200, 560), 200.0, Color(1, 0.6, 0.3), 0.8)
	add_torch(Vector2(680, 600), 260.0, Color(0.7, 0.75, 1), 0.35)   # cold store: a grey draught of daylight
	add_torch(Vector2(1340, 600), 240.0, Color(1, 0.6, 0.3), 0.7)
	for x in [1900.0, 1730.0, 2190.0]: add_torch(Vector2(x, 320.0 if x == 1900.0 else 880.0), 220.0, Color(1, 0.45, 0.18), 0.9)   # smoking fires
	add_torch(Vector2(2540, 600), 260.0, Color(1, 0.55, 0.25), 0.8)
	# the smokehouse: hams on chains swinging across the way through
	for h in [[1800, 600, 0.0, false, "ham_hook"], [1940, 460, 0.6, true, "bacon_hook"], [1940, 760, 1.3, true, "sausage_hook"], [2090, 600, 0.9, false, "ham_hook"]]:
		var hk := SwingingHook.new()
		add_child(hk)
		hk.setup(Vector2(h[0], h[1]), h[4], 0.0, false, 0.78)
		hk.anchor = Vector2(h[0], h[1]); hk.phase = h[2]; hk.along_x = h[3]; hk.reach = 160.0 if h[3] else 140.0
	# the thieves: two in the cold store you can slip past, then the fights
	for p in [Vector2(560, 470), Vector2(820, 760)]: spawn_enemy("spiridus", p).aggro = 130.0
	for p in [Vector2(1250, 500), Vector2(1420, 520), Vector2(1300, 720), Vector2(1460, 700)]: spawn_enemy("spiridus", p)
	for p in [Vector2(1800, 450), Vector2(1950, 600), Vector2(2100, 470), Vector2(1850, 780), Vector2(2120, 760)]: spawn_enemy("spiridus", p)
	spawn_enemy("spiridus_cap", Vector2(2560, 600)).died.connect(func(_e): _on_captain())
	for p in [Vector2(2450, 480), Vector2(2460, 740)]: spawn_enemy("spiridus", p)
	# the stair up to the yard: worn steps against the west wall, lit from above
	add_decor(Vector2(132, 600), "crypt_stairs")
	add_torch(Vector2(130, 520), 170.0, Color(0.85, 0.8, 0.7), 0.55)
	add_trigger(Rect2(100, 500, 30, 200), _leave)
	add_trigger(Rect2(380, 300, 80, 600), _hat_theft)

func ambient() -> Color:
	return Color(0.34, 0.3, 0.27)

func _open(c: Rect2) -> bool:
	for r in ROOMS:
		if r.has_point(c.get_center()): return true
	return CORRIDOR.has_point(c.get_center())

## A spiriduș darts out of the hams, snatches the hunter's hat and is gone into the dark.
func _hat_theft() -> void:
	if G.side_has("sig_hat_lost"): return
	G.side_add("sig_hat_lost")
	var pl: Player = G.player
	pl.frozen = true
	# a spiriduș drops off a smoking-hook right beside him, snatches the hat and runs off into the dark between the hams
	var th := add_prop("npc", "hatthief", "", pl.pos + Vector2(70, -30), "", Color("8a2a22"))
	th.remove_from_group("interact"); th.set_solid(false)
	Audio.sfx("cackle", -10.0, 1.8)
	Fx.text(th.pos, "!", Fx.AMBER, 60.0)
	await get_tree().create_timer(0.35).timeout
	th.walk([pl.pos + Vector2(26, -6)], 260.0)
	await get_tree().create_timer(0.35).timeout
	Audio.sfx("swing", -8.0, 1.5)
	Fx.text(pl.pos, "HEY!", Color(1, 0.9, 0.8), 50.0)
	th.walk([pl.pos + Vector2(420, -60), Vector2(1340, 560), Vector2(2000, 600)], 300.0, func(): remove_prop(th))
	await get_tree().create_timer(0.9).timeout
	pl.frozen = false
	G.start_dialogue("Hey!", ["Something small and quick dropped from a smoking-hook, snatched the hat off your head and is gone between the hams, giggling.", "Your hat. Your good hat."],
		func(): Hud.toast("Get your hat back."))

## The captain faints with the rest; when the hunter has him, he comes round to apologise.
func _on_captain() -> void:
	if captain_down: return
	captain_down = true
	Audio.sfx("bell", -14.0, 1.3)
	Hud.banner("THE CAPTAIN FAINTS", "Stars circle over his little red cap.")
	add_prop("npc", "captain", "Spiriduș-căpitan", Vector2(2600, 640), "E   Wake the captain", Color("8a2a22"))

func _leave() -> void:
	var door: Vector2 = load("res://scripts/levels/sighisoara.gd").cellar_door
	Loader.goto_level("sighisoara", door + Vector2(0, 60) if door != Vector2.ZERO else null)
