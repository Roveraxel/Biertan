class_name Prop
extends StaticBody2D
## Interactable world object: NPC, coin sack, torn fleece, signpost.

var main
var kind := "npc"
var id := ""
var display := ""
var col := Color("a05030")
var prompt := ""
var used := false
var t := 0.0
var regrow := 0.0
var light: PointLight2D


func _ready() -> void:
	add_to_group("interactable")
	collision_layer = 1
	collision_mask = 0
	var cs := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = 12.0
	cs.shape = c
	add_child(cs)
	if kind == "crystal":
		light = G.make_light(170.0, Color(0.75, 0.85, 1.0), 0.8)
		light.position = Vector2(0, -16)
		add_child(light)
	elif kind == "cross":
		light = G.make_light(150.0, Color(1.0, 0.8, 0.5), 0.5)
		light.position = Vector2(0, -30)
		add_child(light)


func can_interact() -> bool:
	if kind == "crystal":
		return regrow <= 0.0
	return not (used and kind in ["sack", "cross", "bones"])


func interact() -> void:
	main.prop_used(self)


func prompt_text() -> String:
	return prompt


func _process(delta: float) -> void:
	t += delta
	if regrow > 0.0:
		regrow = maxf(0.0, regrow - delta)
	if light != null and kind == "crystal":
		light.energy = (0.25 if regrow > 0.0 else 0.8) + 0.08 * sin(t * 2.0 + position.x)
	queue_redraw()


func _draw() -> void:
	var f := ThemeDB.fallback_font
	draw_set_transform(Vector2(0, 2), 0, Vector2(1, 0.45))
	draw_circle(Vector2.ZERO, 15, Color(0, 0, 0, 0.35))
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	match kind:
		"npc":
			var bob := sin(t * 2.0 + position.x) * 1.0
			var ntex := G.tex("res://assets/sprites/npc_%s.svg" % id)
			if ntex != null:
				draw_texture_rect(ntex, Rect2(-40, -69 + bob, 80, 80), false)
			else:
				draw_circle(Vector2(0, -14 + bob), 12, col)
				draw_circle(Vector2(0, -16 + bob), 8, col.lightened(0.15))
				draw_circle(Vector2(0, -30 + bob), 8, Color("d9b48f"))
				draw_circle(Vector2(0, -34 + bob), 8, col.darkened(0.45))
				draw_circle(Vector2(0, -30 + bob), 5.5, Color("d9b48f"))
			draw_string_outline(f, Vector2(-110, -50), display, HORIZONTAL_ALIGNMENT_CENTER, 220, 13, 4, Color(0, 0, 0, 0.9))
			draw_string(f, Vector2(-110, -50), display, HORIZONTAL_ALIGNMENT_CENTER, 220, 13, G.TEXT)
			if main != null and main.marker_for(id):
				draw_string_outline(f, Vector2(-10, -66 + sin(t * 4.0) * 2.0), "!", HORIZONTAL_ALIGNMENT_CENTER, 20, 22, 5, Color(0, 0, 0, 0.9))
				draw_string(f, Vector2(-10, -66 + sin(t * 4.0) * 2.0), "!", HORIZONTAL_ALIGNMENT_CENTER, 20, 22, G.AMBER)
		"sack":
			if not used:
				draw_circle(Vector2(0, -8), 10, Color("8a6a3a"))
				draw_circle(Vector2(0, -16), 5, Color("8a6a3a"))
				draw_rect(Rect2(-4, -20, 8, 3), Color("c9a24a"))
		"fleece":
			draw_circle(Vector2(0, -4), 12, Color("cfc6b3"))
			draw_circle(Vector2(8, -2), 7, Color("9a2020", 0.6))
			draw_circle(Vector2(-6, -6), 6, Color("e8e0cc"))
		"crystal":
			var k := 0.45 if regrow > 0.0 else 1.0
			var cols := [Color(0.86, 0.9, 1.0, 0.95), Color(0.95, 0.85, 0.9, 0.9), Color(0.75, 0.82, 0.95, 0.95)]
			for i in 5:
				var bx := -14.0 + i * 7.0
				var hh := (18.0 + float((i * 7) % 11) * 2.0) * k
				var c: Color = cols[i % 3]
				draw_colored_polygon(PackedVector2Array([Vector2(bx - 5, 0), Vector2(bx + 5, 0), Vector2(bx + 2, -hh), Vector2(bx - 1, -hh - 6)]), c)
				draw_line(Vector2(bx, -2), Vector2(bx + 1, -hh), Color(1, 1, 1, 0.8), 1.0)
		"cross":
			draw_rect(Rect2(-3, -64, 6, 64), Color("4a3320"))
			draw_rect(Rect2(-18, -52, 36, 6), Color("4a3320"))
			draw_colored_polygon(PackedVector2Array([Vector2(-24, -60), Vector2(0, -76), Vector2(24, -60)]), Color("2e2217"))
			draw_circle(Vector2(0, -40), 5, Color("c9a24a"))
			for i in 8:
				var a := Vector2.from_angle(i * TAU / 8.0)
				draw_line(Vector2(0, -40) + a * 6.0, Vector2(0, -40) + a * 10.0, Color("c9a24a"), 1.5)
			if not used:
				draw_circle(Vector2(0, -6), 3, Color(1, 0.7, 0.3, 0.6 + 0.3 * sin(t * 5.0)))
		"greenman":
			draw_rect(Rect2(-22, -56, 44, 52), Color("8d877a"))
			draw_circle(Vector2(0, -32), 15, Color("6a6458"))
			for i in 7:
				var a := Vector2.from_angle(PI + i * PI / 6.0)
				draw_circle(Vector2(0, -32) + a * 17.0, 7, Color("5a6a44"))
			draw_circle(Vector2(-5, -34), 2, Color("1a1410"))
			draw_circle(Vector2(5, -34), 2, Color("1a1410"))
			draw_line(Vector2(-6, -24), Vector2(6, -24), Color("3a3a2a"), 2.0)
			draw_line(Vector2(-6, -24), Vector2(-12, -14), Color("5a6a44"), 3.0)
			draw_line(Vector2(6, -24), Vector2(12, -14), Color("5a6a44"), 3.0)
		"bones":
			if not used:
				draw_circle(Vector2(0, -8), 10, Color("8a6a3a"))
				draw_rect(Rect2(-4, -20, 8, 3), Color("c9a24a"))
			draw_line(Vector2(-18, -2), Vector2(4, -6), Color("d8d2c0"), 3.0)
			draw_circle(Vector2(12, -6), 6, Color("d8d2c0"))
			draw_circle(Vector2(10, -7), 1.5, Color("1a1410"))
		"sign":
			draw_rect(Rect2(-2, -34, 4, 34), Color("4a3320"))
			draw_rect(Rect2(-16, -40, 32, 16), Color("6b4a2e"))
			draw_line(Vector2(-10, -34), Vector2(10, -34), Color("2a1c10"), 2.0)
