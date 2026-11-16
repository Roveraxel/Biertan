## A frame-animated pixel-art character (made with PixelLab) standing in the 3D world. Frames live in
## res://sprites/Pixel/<name>/ as rotation_<dir>.png and <anim>_<dir>_<frame>.png. The figure turns toward
## where it moves or looks and plays idle, walk, attack, hurt, death (and rise, charge) as its owner says.
class_name PixelFigure
extends Node3D

const DIRS := ["south", "south-east", "east", "north-east", "north", "north-west", "west", "south-west"]
const ONCE := ["death", "attack", "rise"]

static var _lib := {}
static var _shadow_mesh: PlaneMesh
static var _shadow_mat: StandardMaterial3D

var fig_name := ""
var height := 1.25          # metres the body stands tall (the canvas is larger)
var cur := "idle"
var dir := "south"
var flip := false
var t0 := 0.0
var hover := 0.0            # metres off the ground (iele, shades)
var sink := 0.0             # 0..1 of the body under the earth (a buried moroi)
var sway := 0.0             # degrees
var alpha := 1.0
var hurt := 0.0             # 0..1: flares red and squashes against the blow
var tint_mul := Color.WHITE
var lit := true             # takes the light of nearby fires
var board: Node3D
var sprite: Sprite3D
var shadow: MeshInstance3D
var _stills := {}
var _clips := {}
var _px := 0.01
var _base_y := 0.5
var _tint := Color.WHITE
var _tick := 0
var _fade := 1.0

static func _files(path: String) -> PackedStringArray:
	var out := PackedStringArray()
	var seen := {}
	var names := ResourceLoader.list_directory(path)
	if names.is_empty() and DirAccess.dir_exists_absolute(path): names = DirAccess.get_files_at(path)
	for f in names:
		var n: String = f.trim_suffix(".import").trim_suffix(".remap")
		if n.ends_with(".png") and not seen.has(n):
			seen[n] = true
			out.append(n)
	return out

static func library(char_name: String) -> Dictionary:
	if _lib.has(char_name): return _lib[char_name]
	var stills := {}
	var tmp := {}
	var path := "res://sprites/Pixel/" + char_name
	for f in _files(path):
		var parts := f.trim_suffix(".png").split("_")
		if parts.size() == 2 and parts[0] == "rotation":
			stills[parts[1]] = load(path + "/" + f)
			continue
		if parts.size() < 3 or not parts[parts.size() - 1].is_valid_int(): continue
		var key := "_".join(parts.slice(0, parts.size() - 1))
		if not tmp.has(key): tmp[key] = {}
		tmp[key][int(parts[parts.size() - 1])] = path + "/" + f
	var clips := {}
	for key in tmp:
		var idx: Array = tmp[key].keys()
		idx.sort()
		var frames: Array[Texture2D] = []
		for i in idx: frames.append(load(tmp[key][i]))
		clips[key] = frames
	_lib[char_name] = {"stills": stills, "clips": clips}
	return _lib[char_name]

static var _gaps := {}
## Empty rows under the lowest opaque pixel of the south-facing still, as a share of its height.
static func _foot_gap(char_name: String, still: Texture2D) -> float:
	if _gaps.has(char_name): return _gaps[char_name]
	var g := 0.03
	var img := still.get_image()
	if img:
		if img.is_compressed(): img.decompress()
		var h := img.get_height()
		var found := false
		for y in range(h - 1, -1, -1):
			for x in img.get_width():
				if img.get_pixel(x, y).a > 0.5: found = true; break
			if found: g = float(h - 1 - y) / h; break
	_gaps[char_name] = g
	return g

static func exists(char_name: String) -> bool:
	return not library(char_name).stills.is_empty()

## The first of `names` that has been drawn, as a figure `h` metres tall; null when none has.
static func make(names, h: float) -> PixelFigure:
	for n in (names if names is Array else [names]):
		if exists(n):
			var f := PixelFigure.new()
			f.height = h
			f._build()
			f.set_figure(n)
			return f
	return null

func _build() -> void:
	board = Node3D.new()
	board.rotation.x = -deg_to_rad(Fx.PITCH * 0.55)   # stands up, leaning back toward the camera
	add_child(board)
	sprite = Sprite3D.new()
	sprite.shaded = false
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	sprite.rotation.x = -deg_to_rad(Fx.PITCH * 0.45)  # the rest of the way to face the camera
	board.add_child(sprite)
	if _shadow_mesh == null:
		_shadow_mesh = PlaneMesh.new()
		_shadow_mesh.size = Vector2(0.9, 0.6)
		_shadow_mat = Mats.unlit(Color(0, 0, 0, 0.45), Fx.circle_tex())
	shadow = MeshInstance3D.new()
	shadow.mesh = _shadow_mesh
	shadow.material_override = _shadow_mat
	shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	shadow.position.y = 0.015
	add_child(shadow)
	t0 = randf()
	_tick = randi() % 6

func set_figure(char_name: String) -> void:
	if char_name == fig_name or not exists(char_name): return
	fig_name = char_name
	var lib := library(char_name)
	_stills = lib.stills
	_clips = lib.clips
	var still: Texture2D = _stills.get("south", _stills.values()[0])
	_px = height / maxf(1.0, still.get_height() * 0.82)
	# stand on the feet actually drawn: animals sit high in their canvas, people near the bottom
	_base_y = (0.47 - _foot_gap(char_name, still)) * still.get_height() * _px
	sprite.pixel_size = _px
	sprite.texture = still

func has_clip(anim: String) -> bool:
	return _clips.has(anim + "_south") or _clips.has(anim + "_east")

func _clip_length(anim: String) -> float:
	for k in [anim + "_" + dir, anim + "_east", anim + "_south"]:
		if _clips.has(k): return _clips[k].size() / 12.0
	return 0.0

static func dir_from(v: Vector2, eight: bool) -> String:
	var a := rad_to_deg(atan2(v.x, v.y))   # 0 = facing the camera (south), clockwise seen from above
	if a < 0: a += 360.0
	var i := (roundi(a / 45.0) % 8) if eight else (roundi(a / 90.0) % 4 * 2)
	return DIRS[i]

## Advance one frame. `vel` in pixels a second; `facing` is where it looks when it stands still.
func tick(state: String, vel: Vector2, facing: Vector2, dt: float) -> void:
	var speed := vel.length() * Fx.S
	var look := vel if speed >= 0.3 else facing
	if look.length_squared() > 0.0001: dir = dir_from(look, _stills.has("south-east"))
	if state == "move": state = "walk" if speed > 0.3 else "idle"
	# a strike plays through once it starts, even if the game's attack window is shorter
	var locked := cur == "attack" and t0 < _clip_length("attack")
	if state != cur and not (locked and state != "death" and state != "hurt"):
		cur = state
		t0 = 0.0
	t0 += dt
	var fps := 7.0
	match cur:
		"walk": fps = clampf(speed * 3.2, 6.0, 14.0)
		"charge": fps = 14.0
		"attack": fps = 12.0
		"death": fps = 10.0
	flip = false
	# a figure drawn without a strike (the wolf of old) springs with a quick burst of its run
	var anim := cur
	if cur == "attack" and not has_clip("attack"):
		anim = "walk"; fps = 18.0
	if cur == "dormant":
		anim = "rise"; fps = 0.0
	elif cur == "rise": fps = 11.0
	var frames: Array = _clips.get(anim + "_" + dir, [])
	if frames.is_empty():
		# a missing side borrows its mirror (west from east and so on), else the camera-facing clip
		var mirror := dir.replace("west", "@").replace("east", "west").replace("@", "east")
		if mirror != dir and _clips.has(anim + "_" + mirror):
			frames = _clips[anim + "_" + mirror]
			flip = true
		else: frames = _clips.get(anim + "_south", [])
	var tex: Texture2D
	if not frames.is_empty():
		var i := int(t0 * fps)
		i = mini(i, frames.size() - 1) if anim in ONCE else i % frames.size()
		tex = frames[i]
	else:
		tex = _stills.get(dir, _stills.get("south"))
	sprite.texture = tex
	sprite.flip_h = flip
	sprite.position = Vector3(0, _base_y - sink * height * 1.25 + hover, 0)
	sprite.rotation.z = deg_to_rad(sway)
	sprite.scale = Vector3(1.0 + 0.08 * hurt, 1.0 - 0.06 * hurt, 1.0)
	_tick += 1
	if _tick % 6 == 0 or _tint == Color.WHITE:
		_tint = Fx.light_at(global_position) if lit else Color.WHITE
	var c := Color(_tint.r * tint_mul.r, _tint.g * tint_mul.g, _tint.b * tint_mul.b, alpha * tint_mul.a)
	if hurt > 0.0: c = c.lerp(Color(1, 0.25, 0.2, c.a), hurt * 0.75)
	c = Color(c.r * _fade, c.g * _fade * 0.9, c.b * _fade * 0.9, c.a)
	sprite.modulate = c
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD if c.a >= 0.99 else SpriteBase3D.ALPHA_CUT_DISABLED

## A corpse darkens, then fades (k from 1 to 0).
func fade_to(k: float) -> void:
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISABLED
	sprite.modulate.a = k

func become_corpse() -> void:
	shadow.visible = false
	var c := sprite.modulate
	sprite.modulate = Color(c.r * 0.7, c.g * 0.6, c.b * 0.6, c.a)
