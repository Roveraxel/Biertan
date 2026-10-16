class_name HollowTree
extends Node2D
## Big decorative hollow oak.


func _draw() -> void:
	draw_set_transform(Vector2(0, 40), 0, Vector2(1, 0.4))
	draw_circle(Vector2.ZERO, 60, Color(0, 0, 0, 0.35))
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	draw_colored_polygon(PackedVector2Array([Vector2(-34, 40), Vector2(-26, -60), Vector2(26, -60), Vector2(34, 40)]), Color("3a2c1e"))
	draw_colored_polygon(PackedVector2Array([Vector2(-12, 34), Vector2(-14, -10), Vector2(0, -24), Vector2(14, -10), Vector2(12, 34)]), Color("0b0a08"))
	for s in [-1.0, 1.0]:
		draw_line(Vector2(20 * s, -50), Vector2(60 * s, -100), Color("3a2c1e"), 8.0)
		draw_line(Vector2(50 * s, -86), Vector2(74 * s, -90), Color("3a2c1e"), 4.0)
	draw_circle(Vector2(0, -90), 54, Color("1d2e18"))
	draw_circle(Vector2(-30, -74), 34, Color("1a2a16"))
	draw_circle(Vector2(30, -74), 34, Color("1a2a16"))
	draw_circle(Vector2(-6, 0), 2.5, Color("9aff6a"))
	draw_circle(Vector2(6, 0), 2.5, Color("9aff6a"))
