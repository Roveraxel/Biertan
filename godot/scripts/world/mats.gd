## Shared materials: textured surfaces (pixel-art sets in the Saxon villages, photo textures elsewhere),
## plain colours, unlit colours and the see-through twins used when a house stands in front of the hunter.
class_name Mats
extends RefCounted

const VILLAGES := ["sighisoara", "viscri", "crit", "saschiz", "sapartoc", "apold", "cris", "malancrav", "richisvillage"]
const OLD_VILLAGES := ["hub", "richis", "mosna", "biertan"]
const WOODS := ["forest", "critforest", "crisforest", "richisforest", "ieleridge", "uriasi", "hollow"]
const SAXON := [Color(0.92, 0.78, 0.56), Color(0.66, 0.77, 0.88), Color(0.68, 0.75, 0.62), Color(0.86, 0.66, 0.62), Color(0.94, 0.88, 0.72), Color(0.88, 0.70, 0.56), Color(0.78, 0.77, 0.74), Color(0.93, 0.89, 0.80)]
const SHUTTERS := [Color(0.16, 0.36, 0.62), Color(0.55, 0.14, 0.12), Color(0.2, 0.42, 0.24), Color(0.12, 0.45, 0.48), Color(0.36, 0.24, 0.14)]

static var _cache := {}
static var _tex := {}

static func px() -> bool:
	return G.current in VILLAGES

## Underground rooms: vaulted brick cellars and crypts, and the salt-mine caves and tunnels.
const BRICK_LEVELS := ["cellar", "crypt", "malcrypt"]
const SALT_LEVELS := ["tunnel", "caves"]

static func under_wall(id: String) -> Material:
	if id in BRICK_LEVELS: return mat("px_brick", 2.2, Color(0.66, 0.6, 0.56), 0.1)
	if id in SALT_LEVELS: return mat("px_salt", 3.2, Color(0.95, 0.88, 0.8), 0.08)
	return null

static func is_village(id: String) -> bool:
	return id in VILLAGES or id in OLD_VILLAGES

static func tex(path: String) -> Texture2D:
	if not _tex.has(path):
		_tex[path] = load(path) if ResourceLoader.exists(path) else null
	return _tex[path]

static func _set_tex(set_name: String, kind: String) -> Texture2D:
	for ext in ["png", "jpg"]:
		var t := tex("res://textures/%s_%s_1k.%s" % [set_name, kind, ext])
		if t: return t
	return null

## A lit, textured surface; `tile` is how many metres one repeat of the texture covers.
static func mat(set_name: String, tile: float, tint: Color, smooth := 0.12) -> StandardMaterial3D:
	var key := "%s|%s|%s|%s" % [set_name, tile, tint, smooth]
	if _cache.has(key): return _cache[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = tint
	m.vertex_color_use_as_albedo = true
	m.albedo_texture = _set_tex(set_name, "diff")
	var nor := _set_tex(set_name, "nor_gl")
	if nor:
		m.normal_enabled = true
		m.normal_texture = nor
		m.normal_scale = 1.2
	m.roughness = 1.0 - smooth
	m.metallic_specular = 0.3
	m.uv1_scale = Vector3(1.0 / tile, 1.0 / tile, 1.0)
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	if set_name.begins_with("px_"): m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
	_cache[key] = m
	return m

static func plain(c: Color, smooth := 0.1, emission = null) -> StandardMaterial3D:
	var key := "plain|%s|%s|%s" % [c, smooth, emission]
	if _cache.has(key): return _cache[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(c.r, c.g, c.b, 1.0)
	m.roughness = 1.0 - smooth
	m.metallic_specular = 0.3
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	if emission != null:
		m.emission_enabled = true
		m.emission = emission
		m.emission_energy_multiplier = 1.6
	_cache[key] = m
	return m

## A lit colour laid thinly over what is under it.
static func fade(c: Color) -> StandardMaterial3D:
	var key := "fade|%s" % c
	if _cache.has(key): return _cache[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.roughness = 0.9
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	_cache[key] = m
	return m

## Unlit and see-through: glows, telegraphs, shadows, rings.
static func unlit(c: Color, texture: Texture2D = null, additive := false) -> StandardMaterial3D:
	var key := "unlit|%s|%s|%s" % [c, texture, additive]
	if _cache.has(key): return _cache[key]
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = c
	m.albedo_texture = texture
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.disable_fog = false
	if additive: m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_cache[key] = m
	return m

## The same surface at a fraction of its opacity.
static func see_through(src: Material) -> Material:
	if not (src is StandardMaterial3D): return src
	var key := "see|%d" % src.get_instance_id()
	if _cache.has(key): return _cache[key]
	var m: StandardMaterial3D = src.duplicate()
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color.a = 0.14
	m.metallic_specular = 0.0
	_cache[key] = m
	return m

# ---- the named surfaces of the Unity build ----
static func ground() -> Material: return mat("px_meadow", 2.6, Color(0.74, 0.72, 0.62), 0.1) if px() else mat("grass_path_2", 5.0, Color(0.62, 0.66, 0.55))
static func cobble() -> Material: return mat("px_cobble", 1.4, Color(1.0, 0.94, 0.84), 0.4) if px() else mat("cobblestone_floor_08", 2.4, Color(0.78, 0.76, 0.72), 0.2)
static func road() -> Material: return mat("forest_leaves_02", 3.0, Color(0.7, 0.62, 0.52))
static func roof() -> Material: return mat("px_roof", 1.5, Color(1, 0.96, 0.94), 0.32) if px() else mat("clay_roof_tiles_02", 1.6, Color(0.85, 0.8, 0.78), 0.18)
static func plaster() -> Material: return mat("px_plaster0", 1.8, Color.WHITE) if px() else mat("clay_plaster", 2.5, Color(0.92, 0.88, 0.8))
static func stone() -> Material: return mat("px_stone", 1.5, Color(0.85, 0.85, 0.85), 0.25) if px() else mat("castle_wall_slates", 2.4, Color(0.8, 0.78, 0.74))
static func wood() -> Material: return mat("px_shingle", 1.4, Color(0.85, 0.85, 0.85)) if px() else mat("brown_planks_05", 1.6, Color(0.75, 0.68, 0.6))
static func rubble() -> Material: return mat("castle_wall_slates", 2.4, Color(0.72, 0.69, 0.64))

## Saxon families painted their houses: ochre, pale blue, sage, pink, cream, a light yellow. `p` is the
## house's spot in the Unity build's 2D space (x, -y), which keeps every house the colour it had there.
static func saxon_plaster(p: Vector2) -> Material:
	var k := absi(int(p.x * 0.37) * 31 + int(p.y * 0.53) * 17)
	var c: Color = SAXON[k % SAXON.size()].lerp(Color(0.62, 0.58, 0.52), 0.2)
	return mat("px_plaster%d" % (k % 5), 1.8, c) if px() else mat("clay_plaster", 2.5, c)

static func roof_at(p: Vector2) -> Material:
	if not px(): return roof()
	return mat("px_roof2", 1.5, Color(0.95, 0.9, 0.88), 0.32) if absi(int(p.x * 0.29) + int(p.y * 0.41)) % 3 == 0 else roof()

static func shutter(p: Vector2) -> Color:
	return SHUTTERS[absi(int(p.x * 0.13) * 7 + int(p.y * 0.11) * 3) % SHUTTERS.size()]

static func ground_for(id: String, level: Node) -> Material:
	if id == "stana": return mat("grass_path_2", 4.5, Color(0.55, 0.68, 0.45))
	if is_village(id): return ground()
	if id in ["forest", "critforest", "crisforest", "richisforest", "ieleridge", "uriasi", "hills", "vineyard", "walls", "biertanfort"]: return mat("forest_leaves_02", 3.0, Color(0.6, 0.58, 0.52))
	if id in ["arena", "hollow"]: return mat("forest_leaves_02", 3.0, Color(0.42, 0.44, 0.38))
	if id == "cellar": return mat("px_cobble", 1.8, Color(0.62, 0.58, 0.54), 0.15)
	if id in BRICK_LEVELS: return mat("px_flag", 2.6, Color(0.82, 0.78, 0.72), 0.2)
	if id in SALT_LEVELS: return mat("px_gravel", 2.0, Color(1.5, 1.4, 1.3), 0.05)
	if id in ["caves", "gorge"]: return mat("castle_wall_slates", 3.0, Color(0.36, 0.34, 0.32))
	if id in ["church", "sacristy"]: return mat("cobblestone_floor_08", 1.6, Color(0.55, 0.53, 0.5), 0.3)
	return plain(level.ground * 0.9) if level.tile == "" else ground()
