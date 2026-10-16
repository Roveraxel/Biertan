class_name Brazier
extends StaticBody2D

var lit := true
var lit_t := 0.0
var decays := false
var base_energy := 1.25
var light: PointLight2D
var t := 0.0


func _ready() -> void:
	add_to_group("interactable")
	add_to_group("braziers")
	collision_layer = 1
	collision_mask = 0
	var cs := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = 13.0
	cs.shape = c
	add_child(cs)
	light = G.make_light(270.0, Color(1.0, 0.66, 0.32), 1.25)
	light.position = Vector2(0, -16)
	add_child(light)
	set_lit(lit)


func set_lit(v: bool) -> void:
	lit = v
	if light:
		light.visible = v
	if v:
		lit_t = 26.0


func can_interact() -> bool:
	return not lit


func prompt_text() -> String:
	return "E   Light the brazier"


func interact() -> void:
	if not lit:
		set_lit(true)
		G.sfx("ignite", -4.0)
		G.fx_ring(get_parent(), global_position, Color(1, 0.7, 0.3), 90)


func _process(delta: float) -> void:
	t += delta
	if lit and decays:
		lit_t -= delta
		if lit_t <= 0.0:
			set_lit(false)
	if light and lit:
		light.energy = base_energy + 0.12 * sin(t * 13.0) + 0.06 * sin(t * 29.0)
	queue_redraw()


func _draw() -> void:
	draw_set_transform(Vector2(0, 2), 0, Vector2(1, 0.45))
	draw_circle(Vector2.ZERO, 18, Color(0, 0, 0, 0.35))
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	draw_rect(Rect2(-3, -14, 6, 14), Color("2a2622"))
	draw_colored_polygon(PackedVector2Array([Vector2(-14, -22), Vector2(14, -22), Vector2(9, -12), Vector2(-9, -12)]), Color("3a3530"))
	if lit:
		var k := sin(t * 14.0) * 2.0
		draw_colored_polygon(PackedVector2Array([Vector2(-9, -22), Vector2(0, -42 + k), Vector2(9, -22)]), Color("e8742a"))
		draw_colored_polygon(PackedVector2Array([Vector2(-5, -22), Vector2(0, -34 + k), Vector2(5, -22)]), Color("ffd27a"))
		if decays and lit_t < 6.0:
			draw_arc(Vector2(0, -22), 20, 0, TAU * (lit_t / 6.0), 20, Color(1, 0.8, 0.4, 0.8), 2.0)
	else:
		draw_circle(Vector2(0, -22), 5, Color("1a1714"))
