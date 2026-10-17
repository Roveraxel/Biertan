class_name BloodGeyser
extends Node2D
## A pool of spilled blood that erupts into bloodflame after a delay.

var R := 56.0
var t := 0.0
var delay := 1.3
var dmg := 18.0
var done := false
var light: PointLight2D


func _ready() -> void:
	z_index = -1
	light = G.make_light(R * 2.2, Color(1.0, 0.15, 0.1), 0.0)
	add_child(light)


func _physics_process(delta: float) -> void:
	t += delta
	if not done and t >= delay:
		done = true
		z_index = 0
		light.energy = 1.2
		G.sfx("fire", -6.0, 1.3)
		var p = get_tree().get_first_node_in_group("player")
		if p != null and p.global_position.distance_to(global_position) < R + 6.0:
			p.hurt(dmg, (p.global_position - global_position).normalized())
	if done:
		light.energy = maxf(0.0, light.energy - delta * 2.0)
	if t > delay + 0.6:
		queue_free()
	queue_redraw()


func _draw() -> void:
	if not done:
		var k := t / delay
		draw_set_transform(Vector2.ZERO, 0, Vector2(1, 0.6))
		draw_circle(Vector2.ZERO, R * minf(1.0, k * 1.6), Color(0.35, 0.0, 0.03, 0.55))
		draw_arc(Vector2.ZERO, R, 0, TAU, 32, Color(0.9, 0.1, 0.1, 0.3 + 0.4 * k), 2.0)
		draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
		return
	var a := clampf(1.0 - (t - delay) / 0.6, 0.0, 1.0)
	for i in 6:
		var x := (i - 2.5) * R * 0.3
		var h := (80.0 + 30.0 * sin(i * 1.7 + t * 20.0)) * a
		draw_colored_polygon(PackedVector2Array([Vector2(x - 9, 0), Vector2(x + 9, 0), Vector2(x, -h)]), Color(0.85, 0.08, 0.06, 0.85 * a))
		draw_colored_polygon(PackedVector2Array([Vector2(x - 4, 0), Vector2(x + 4, 0), Vector2(x, -h * 0.6)]), Color(1.0, 0.55, 0.3, 0.9 * a))
