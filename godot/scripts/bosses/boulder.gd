## A boulder lobbed by the giant: it arcs through the air to a marked spot and lands hard.
class_name Boulder
extends Node3D

var from := Vector2.ZERO
var to := Vector2.ZERO
var life := 1.0
var dmg := 15.0
var t := 0.0
var mark: MeshInstance3D
var mark_mat: StandardMaterial3D

static func launch(a: Vector2, b: Vector2, flight: float, damage: float) -> void:
	var o := Boulder.new()
	o.from = a; o.to = b; o.life = flight; o.dmg = damage
	Fx.root().add_child(o)
	var tex: Texture2D = Mats.tex("res://sprites/Props/boulder.png")
	if not tex: tex = Mats.tex("res://sprites/Props/forest_boulder.png")
	var s := Sprite3D.new()
	s.texture = tex if tex else Fx.circle_tex()
	s.pixel_size = 1.1 / Decor.PPU if tex else 46.0 * Fx.S / 512.0
	if not tex: s.modulate = Color(0.45, 0.42, 0.38)
	s.shaded = false
	s.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	s.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	s.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	o.add_child(s)
	o.mark = MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(140, 140) * Fx.S
	o.mark.mesh = pm
	o.mark_mat = Mats.unlit(Color(0.8, 0.2, 0.1, 0.35), Fx.circle_tex()).duplicate()
	o.mark.material_override = o.mark_mat
	Fx.root().add_child(o.mark)
	o.mark.global_position = Fx.to3(b, 0.04)
	o.position = Fx.to3(a, 1.5)

func _process(dt: float) -> void:
	t += dt
	var k := clampf(t / life, 0.0, 1.0)
	position = Fx.to3(from.lerp(to, k), 0.4 + (1.1 * (1.0 - k)) + sin(k * PI) * 3.2)
	mark_mat.albedo_color.a = 0.25 + 0.4 * k
	if k < 1.0: return
	var pl: Player = G.player
	if is_instance_valid(pl) and pl.pos.distance_to(to) < 70.0: pl.hurt(dmg, (pl.pos - to).normalized())
	Audio.sfx_at("hit", to, -4.0, 0.4)
	Fx.ring(to, Color(0.6, 0.55, 0.45, 0.8), 80.0, 0.4)
	Fx.shake(0.08)
	mark.queue_free()
	queue_free()
