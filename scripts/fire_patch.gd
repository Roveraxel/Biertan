class_name FirePatch
extends Node2D
## Burning ground from the fire head, or rime from the frost head.

const R := 38.0

var life := 2.6
var t := 0.0
var tick := 0.0
var frost := false
var brew := false
var light: PointLight2D


func _ready() -> void:
	z_index = -1
	if frost:
		life = 3.4
	if brew:
		life = 3.0
	var lc := Color(0.6, 0.8, 1.0) if frost else Color(1.0, 0.55, 0.2)
	if brew:
		lc = Color(0.5, 1.0, 0.3)
	light = G.make_light(110.0, lc, 0.5 if frost or brew else 0.7)
	add_child(light)


func _physics_process(delta: float) -> void:
	t += delta
	life -= delta
	tick -= delta
	if life <= 0.0:
		queue_free()
		return
	var p = get_tree().get_first_node_in_group("player")
	if p != null and p.global_position.distance_to(global_position) < R:
		if brew:
			p.slow_t = maxf(p.slow_t, 0.2)
			if tick <= 0.0:
				tick = 0.5
				p.hurt(6.0, Vector2.ZERO)
		elif frost:
			p.slow_t = maxf(p.slow_t, 0.25)
			if tick <= 0.0:
				tick = 0.6
				p.hurt(4.0, Vector2.ZERO)
		elif tick <= 0.0:
			tick = 0.5
			p.hurt(9.0, (p.global_position - global_position).normalized())
	light.energy = (0.5 if frost else 0.7) * clampf(life, 0.0, 1.0)
	queue_redraw()


func _draw() -> void:
	var a := clampf(life, 0.0, 1.0)
	if brew:
		draw_set_transform(Vector2.ZERO, 0, Vector2(1, 0.6))
		draw_circle(Vector2.ZERO, R, Color(0.25, 0.45, 0.1, 0.6 * a))
		for i in 5:
			var bp := Vector2.from_angle(i * 1.3 + t) * R * 0.5
			draw_circle(bp, 4 + 2 * sin(t * 6.0 + i), Color(0.6, 1.0, 0.3, 0.7 * a))
		draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
		return
	if frost:
		draw_circle(Vector2.ZERO, R, Color(0.7, 0.85, 1.0, 0.3 * a))
		for i in 7:
			var p := Vector2.from_angle(i * 0.9) * R * 0.6
			draw_colored_polygon(PackedVector2Array([p + Vector2(-4, 0), p + Vector2(4, 0), p + Vector2(0, -14)]), Color(0.85, 0.95, 1.0, 0.8 * a))
		return
	draw_circle(Vector2.ZERO, R, Color(0.15, 0.05, 0.02, 0.5 * a))
	for i in 7:
		var p := Vector2.from_angle(i * 0.9 + t * 0.5) * R * 0.55
		var h := 14.0 + 8.0 * sin(t * 12.0 + i)
		draw_colored_polygon(PackedVector2Array([p + Vector2(-6, 0), p + Vector2(6, 0), p + Vector2(0, -h)]), Color(1.0, 0.5 + 0.2 * sin(t * 9.0 + i), 0.1, 0.85 * a))
