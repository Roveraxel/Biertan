## A handful of flat coloured shapes (squares, discs, triangles) standing upright to the camera: the simple
## drawn things of the world (a coin sack, a signpost, a wayside cross). Positions and sizes in pixels, y up.
class_name Board
extends Node3D

var parts: Array[Sprite3D] = []
var base: Array[Color] = []
var glow: Array[bool] = []
var _tick := randi() % 12

func _init() -> void:
	rotation.x = -deg_to_rad(Fx.PITCH * 0.55); add_to_group("ybill")

func part(shape: String, local: Vector2, sz: Vector2, color: Color, order := 0, unlit := false, parent: Node3D = null) -> Sprite3D:
	var s := Sprite3D.new()
	var tex: Texture2D = Mats.tex("res://sprites/%s.png" % shape)
	s.texture = tex
	s.pixel_size = 1.0 / tex.get_width()
	s.shaded = false
	s.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	s.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD if color.a >= 0.99 else SpriteBase3D.ALPHA_CUT_DISABLED
	s.position = Vector3(local.x * Fx.S, local.y * Fx.S, 0.002 * order)
	s.scale = Vector3(sz.x * Fx.S, sz.y * Fx.S, 1.0)
	s.modulate = color
	(parent if parent else self).add_child(s)
	parts.append(s); base.append(color); glow.append(unlit)
	return s

func set_color(s: Sprite3D, c: Color) -> void:
	var i := parts.find(s)
	if i >= 0: base[i] = c
	s.modulate = c
	if c.a < 0.99: s.alpha_cut = SpriteBase3D.ALPHA_CUT_DISABLED

func _process(_dt: float) -> void:
	_tick += 1
	if _tick % 12 != 0: return
	var t := Fx.light_at(global_position)
	for i in parts.size():
		if glow[i] or not is_instance_valid(parts[i]): continue
		var c := base[i]
		parts[i].modulate = Color(c.r * t.r, c.g * t.g, c.b * t.b, c.a)
