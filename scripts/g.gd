class_name G
extends RefCounted
## Shared constants and helpers.

const AMBER := Color("e8a94a")
const TEXT := Color("f3ead6")
const MUTED := Color("cfc6b3")
const BLOOD := Color("b3372f")
const NIGHT := Color("0b0d14")

static var dusk := 0.3
static var _tex: Texture2D
static var _cache := {}
static var _snd := {}
static var audio: Audio
static var touch_mode := false


static func tex(path: String) -> Texture2D:
	if _cache.has(path):
		return _cache[path]
	var t: Texture2D = null
	if ResourceLoader.exists(path):
		t = load(path)
	_cache[path] = t
	return t


static func light_tex() -> Texture2D:
	if _tex == null:
		var g := Gradient.new()
		g.set_color(0, Color(1, 1, 1, 1))
		g.set_color(1, Color(1, 1, 1, 0))
		g.add_point(0.5, Color(1, 1, 1, 0.38))
		var t := GradientTexture2D.new()
		t.gradient = g
		t.fill = GradientTexture2D.FILL_RADIAL
		t.fill_from = Vector2(0.5, 0.5)
		t.fill_to = Vector2(1.0, 0.5)
		t.width = 256
		t.height = 256
		_tex = t
	return _tex


static func make_light(radius: float, col: Color, energy := 1.0) -> PointLight2D:
	var l := PointLight2D.new()
	l.texture = light_tex()
	l.texture_scale = radius / 128.0
	l.color = col
	l.energy = energy
	return l


static func ambient(d: float) -> Color:
	return Color(0.95, 0.9, 0.82).lerp(Color(0.12, 0.14, 0.3), clampf(d, 0.0, 1.0))


static func fx_ring(parent: Node, pos: Vector2, col: Color, r1 := 50.0, life := 0.4) -> void:
	if parent == null or not parent.is_inside_tree():
		return
	var f := Fx.new()
	f.kind = "ring"
	f.col = col
	f.r1 = r1
	f.life = life
	parent.add_child(f)
	f.global_position = pos


static func fx_text(parent: Node, pos: Vector2, s: String, col: Color) -> void:
	if parent == null or not parent.is_inside_tree():
		return
	var f := Fx.new()
	f.kind = "text"
	f.col = col
	f.text = s
	f.life = 0.8
	parent.add_child(f)
	f.global_position = pos


static func sound(sound_name: String, loop: bool) -> AudioStream:
	var key := sound_name + ("#loop" if loop else "")
	if _snd.has(key):
		return _snd[key]
	var path := "res://assets/audio/%s.ogg" % sound_name
	if not ResourceLoader.exists(path):
		path = "res://assets/audio/%s.wav" % sound_name
	var s: AudioStream = null
	if ResourceLoader.exists(path):
		s = load(path)
		if loop and s is AudioStreamOggVorbis:
			s = s.duplicate()
			s.loop = true
		elif loop and s is AudioStreamWAV:
			s = s.duplicate()
			s.loop_mode = AudioStreamWAV.LOOP_FORWARD
			s.loop_begin = 0
			s.loop_end = s.data.size() / 2
	_snd[key] = s
	return s


static func sfx(sound_name: String, vol := 0.0, pitch := 1.0) -> void:
	if audio != null:
		audio.play(sound_name, vol, pitch)
