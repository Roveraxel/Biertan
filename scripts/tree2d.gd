class_name Tree2D
extends StaticBody2D

var seed_v := 0
var kind := 0
var pine := false


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	var cs := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = 11.0
	cs.shape = c
	add_child(cs)
	var r := RandomNumberGenerator.new()
	r.seed = seed_v
	kind = r.randi() % 3
	scale = Vector2.ONE * r.randf_range(0.85, 1.25)


func _draw() -> void:
	draw_set_transform(Vector2(0, 2), 0, Vector2(1, 0.4))
	draw_circle(Vector2.ZERO, 26, Color(0, 0, 0, 0.3))
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	draw_rect(Rect2(-5, -24, 10, 26), Color("2e2217"))
	if pine:
		var c1 := Color("0f1d1a")
		var c2 := Color("183029")
		draw_colored_polygon(PackedVector2Array([Vector2(0, -110), Vector2(-30, -50), Vector2(30, -50)]), c1)
		draw_colored_polygon(PackedVector2Array([Vector2(0, -85), Vector2(-38, -28), Vector2(38, -28)]), c2)
		draw_colored_polygon(PackedVector2Array([Vector2(0, -60), Vector2(-46, -6), Vector2(46, -6)]), c1)
		return
	var palette := [
		[Color("1f3a22"), Color("2d4d2c")],
		[Color("27402a"), Color("3a5a30")],
		[Color("4a3a1c"), Color("7a5a24")],
	]
	var p: Array = palette[kind]
	draw_circle(Vector2(0, -46), 34, p[0])
	draw_circle(Vector2(-16, -34), 24, p[0])
	draw_circle(Vector2(16, -34), 24, p[0])
	draw_circle(Vector2(-4, -58), 20, p[1])
	draw_circle(Vector2(12, -50), 11, p[1])
