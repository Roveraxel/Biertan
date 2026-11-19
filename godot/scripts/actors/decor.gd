## A piece of street clutter (barrel, cart, firewood, a wattle fence) drawn as pixel art standing upright in
## the world like the villagers. Sprite from res://sprites/Props/<sprite>.png. Solid ones block the hunter with
## a small round footprint.
class_name Decor
extends Node3D

const PPU := 42.0
## How big each prop really stands, relative to its drawing.
const SIZES := {
	"pumpkins": 0.85, "cabbages": 0.85, "wheat_shock": 0.95, "tomatoes_stakes": 0.9, "garden_bed": 1.05,
	"wattle_fence": 0.95, "beehives": 0.85, "apple_tree_autumn": 1.9, "pepper_rack": 0.9,
	"wheelbarrow_pumpkins": 0.75, "sunflowers_dry": 0.95, "apple_basket": 0.42, "brazier_cold": 0.7, "garden_shed": 1.45,
	"bench": 0.6, "crate": 0.75, "sacks": 0.7, "barrel": 0.72, "barrels": 0.95,
	"firewood": 0.8, "handcart": 1.2, "horse_cart": 1.15, "hunter_hay": 0.85, "priest_sleep": 1.1, "haycart": 1.6, "well": 1.4, "stall": 1.8, "haystack_plain": 1.9, "hay_eyes": 1.9, "hams_rack": 1.4, "hearth": 1.15,
	"trough": 0.9, "lantern": 1.45, "cauldron": 0.75, "wheel": 0.7, "laundry": 1.1,
	"hams_beam": 1.4, "sausage_rack": 1.2, "salt_barrel": 0.75, "chopping_block": 0.7, "ham_pile": 0.8,
	"smoke_pit": 1.2, "spiridus_lantern": 0.45, "red_cap": 0.35, "ladder": 1.6, "fish_crate": 0.75,
	"potlid": 0.5, "shelf": 1.2, "jar_shelf": 1.5, "stump_stool": 0.55, "pallet_table": 1.0, "iron_grate": 1.9, "hook_empty": 0.9,
	"fig_mon": 0.6, "fig_tue": 0.6, "fig_wed": 0.6, "fig_thu": 0.6, "fig_fri": 0.6, "fig_sat": 0.6, "fig_sun": 0.6,
	"notice_board": 1.4, "guild_sign": 0.9, "portrait": 0.9, "grating": 0.8, "flour": 0.8, "hook_wall": 0.9,
	"dog_sleep": 0.75, "dog_bark": 0.8, "goose": 0.5, "goose_honk": 0.55, "scraps": 0.4, "bone": 0.35,
	"bellrope": 0.5, "chains": 0.9, "chalk_sign": 0.7, "map_scrap": 0.4, "goose_pen": 1.1, "hay": 1.1,
	"kennel": 0.9, "vine_row": 0.55, "snowdrops": 0.28, "earth_dog": 0.15, "joimarita": 0.96, "cellar_door": 1.1, "lantern_iron": 0.5, "barrel_rot": 0.75, "troita": 1.9,
	"lamp_post": 1.3, "lamp_lit": 1.3, "geraniums": 0.7, "logs": 1.0, "hammock": 1.0, "book": 0.35,
	"sheep_lie": 0.6, "sheep_graze": 0.65, "wine_jug": 0.4, "planks": 0.9, "table": 1.0, "pot_fire": 0.8,
	"music_stand": 0.7, "letters": 0.35, "ghost_lantern": 0.5, "church_door": 1.2,
	"lye": 0.5, "ribbons": 1.3, "rose_bush": 0.9, "rose_bare": 0.9, "poppies": 0.5, "petals": 0.4,
	"apples": 1.5, "plums": 0.5, "basket": 0.5, "shrine": 1.5, "grave_cross": 0.8, "open_grave": 1.0,
	"washtub": 0.7, "linen": 0.5, "pears": 0.5, "candle": 0.3,
	"feast_table": 1.5, "chair": 0.6, "wet_steps": 1.1, "stubs": 0.7, "woodpile": 1.2, "bonfire": 1.6,
	"coliva": 0.45, "colac": 0.45, "wine": 0.35, "candles2": 0.45, "clothesline": 1.3, "pot_steam": 0.8,
	"oven": 1.4, "grave_mound": 1.0, "tuica": 0.4, "bench2": 0.9,
	"door_locks": 1.8, "door_open": 1.8, "altar": 1.6, "bell_rope": 1.2, "sarcophagus": 1.5, "candelabra": 1.0, "ash_stake": 0.7,
	"nai": 0.45, "wormwood": 0.7, "walnut_leaves": 0.9, "garlic_braid": 0.5, "basil": 0.45, "decoction": 0.6,
	"well_hole": 1.0, "flower_ring": 0.4, "clay_whistle": 0.3, "calus_bells": 0.4, "ribbon_swirl": 0.8,
	"ridge_barrier": 1.8, "bench_walnut": 1.3, "trapdoor": 0.9, "iele_circle": 1.6,
	"fox_snare": 0.75, "deer_snare": 1.0, "owl_snare": 0.75, "scarecrow": 1.5, "hat_egg": 0.4, "ergot_bread": 0.4,
	"rye_sheaf": 0.9, "rye_fire": 1.4, "clay_pipe": 0.3, "bandage": 0.35, "rot_mark": 0.6, "oak_twig": 0.5,
	"leg_trap": 0.6, "haystack": 1.8, "trousers_flag": 1.0, "plum_stones": 0.35, "fluier": 0.4, "wilted_twig": 0.4, "empty_cup": 0.35,
	"plum_tree": 1.9, "barrel_lid": 0.45, "crypt_stairs": 1.3, "church_bell": 0.9, "oak_stake": 0.7, "tower_key": 0.35, "ladder2": 1.4,
	"timeline_board": 1.3, "sheep_lie2": 0.6, "trousers_hole": 0.5, "wine_mug": 0.35, "long_feast": 2.2, "herb_string": 0.9,
	"hanging_charms": 0.95, "witch_effigy": 1.0, "bone_totem": 1.15, "forest_offerings": 0.75,
	"pig": 0.75, "anvil": 0.8, "donkey": 1.15, "goat": 0.85, "watermill": 2.1, "footbridge": 1.6,
	"milestone": 0.9, "grindstone": 0.95, "plough": 1.1, "dead_tree": 2.0, "tree_stump": 0.85, "stepping_stones": 1.2,
	"livestock_trough": 1.0, "water_pump": 0.9, "sluice_gate": 1.25, "pack_saddle": 0.65, "farm_wagon": 1.55,
	"wagon_wheels": 0.75, "hitching_post": 0.9, "handbell_stand": 0.8, "notice_board_3d": 1.35, "grave_markers": 0.95,
	"votive_candles": 0.5, "roadside_shrine": 1.35, "wayside_cross": 1.4, "balance_scale": 0.55, "market_pottery": 0.65,
	"blacksmith_bellows": 0.85, "blacksmith_forge": 1.3, "laundry_tub": 0.75, "butter_churn": 0.75, "wine_press": 1.35,
	"forest_boulder": 1.35, "fallen_log": 1.4, "woodland_mushrooms": 0.45, "forest_ferns": 0.75, "berry_bush": 0.85,
	"wild_flowers": 0.5, "village_cow": 1.35, "village_sheep": 0.75, "geese_trio": 0.65, "cheese_wheel": 0.45,
	"rye_bread": 0.45, "grain_sacks": 0.75, "market_produce": 1.1, "market_counter": 1.3, "market_textiles": 0.75,
	"smith_tools": 0.9, "weapon_rack": 1.1, "ritual_stones": 1.5, "quarry_winch": 1.4, "wine_rack": 1.2,
	"cooking_hearth": 1.15, "wooden_bench_3d": 0.8, "wicker_baskets": 0.65, "coal_storage": 0.75, "carpentry_bench": 1.25,
	"rainwater_barrel": 0.85, "laundry_rack": 1.2, "kitchen_counter": 1.15, "flour_barrel": 0.75, "leaf_litter": 1.0,
	"dead_branches": 1.1, "herb_garden": 1.05, "pumpkin_plant": 0.75, "cabbage_plant": 0.7, "barley_patch": 1.0,
	"rye_patch": 1.0, "wheat_patch": 1.0, "vineyard_grape": 1.1, "red_currant": 0.85, "harvest_basket": 0.6,
	"clay_pots": 0.65, "onion_cluster": 0.55, "carrot_plant": 0.55, "iron_candelabrum": 1.2, "wooden_handcart": 1.25,
}

var sprite_name := ""
var radius := 0.0
var scale_k := 1.0
var sprite: Sprite3D
var body: StaticBody3D
var smoke := false:
	set(v):
		smoke = v
		if v: Atmosphere.smoke(self)
var _tick := randi() % 12
var _base_tint := Color.WHITE

var pos: Vector2:
	get: return Vector2(position.x, position.z) / Fx.S
	set(v): position = Fx.to3(v)

static func size_of(s: String) -> float:
	return SIZES.get(s, 1.0)

func setup(at: Vector2, sprite_id: String, r := 0.0, flip := false, scale_override := 0.0) -> void:
	pos = at
	sprite_name = sprite_id
	scale_k = scale_override if scale_override > 0.0 else size_of(sprite_id)
	radius = r * scale_k
	var tex: Texture2D = Mats.tex("res://sprites/Props/%s.png" % sprite_id)
	if tex:
		sprite = Sprite3D.new()
		sprite.texture = tex
		sprite.pixel_size = scale_k / PPU
		sprite.centered = false
		sprite.offset = Vector2(-tex.get_width() / 2.0, -tex.get_height() * 0.06)   # sink transparent bottom margin slightly so feet sit in the ground
		sprite.flip_h = flip
		sprite.shaded = false
		sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
		sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		sprite.rotation.x = -deg_to_rad(Fx.PITCH * 0.55); sprite.add_to_group("ybill")
		if sprite_id == "flour":
			_base_tint = Color(0.84, 0.8, 0.72)
		elif sprite_id in ["ritual_stones", "forest_boulder", "livestock_trough", "milestone", "grindstone", "stepping_stones"]:
			_base_tint = Color(0.52, 0.50, 0.46)
		elif sprite_id in ["quarry_winch", "wine_press", "butter_churn", "washtub", "laundry_tub", "sluice_gate", "carpentry_bench", "kitchen_counter", "wooden_bench_3d"]:
			_base_tint = Color(0.66, 0.54, 0.40)
		elif sprite_id == "cheese_wheel":
			_base_tint = Color(0.88, 0.76, 0.48)
		sprite.modulate = _base_tint
		add_child(sprite)
		if sprite_id in ["cellar_door", "door_locks", "door_open", "flour", "rot_mark", "petals"]:   # flush with wall or ground: no drop shadow of its own
			if sprite_id in ["cellar_door", "door_locks", "door_open"]: sprite.rotation.x = 0.0; sprite.remove_from_group("ybill")
			return
		var sh := MeshInstance3D.new()
		var pm := PlaneMesh.new()
		var wdt := tex.get_width() / PPU * scale_k
		pm.size = Vector2(wdt * 0.72, wdt * 0.28)
		sh.mesh = pm
		sh.material_override = Mats.unlit(Color(0, 0, 0, 0.32), Fx.circle_tex())
		sh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		sh.position = Vector3(0.0, 0.012, -wdt * 0.06)
		add_child(sh)
	set_solid(radius > 0.0)

func set_solid(on: bool) -> void:
	if on and body == null and radius > 0.0:
		body = StaticBody3D.new()
		body.collision_layer = 1
		body.collision_mask = 0
		var cs := CollisionShape3D.new()
		var sh := CylinderShape3D.new()
		sh.radius = radius * Fx.S
		sh.height = 4.0
		cs.shape = sh
		cs.position.y = 2.0
		body.add_child(cs)
		add_child(body)
	elif not on and body != null:
		body.queue_free()
		body = null

func _process(_dt: float) -> void:
	_tick += 1
	if sprite and (_tick % 12 == 0 or _tick < 3): sprite.modulate = Fx.light_at(global_position) * _base_tint
