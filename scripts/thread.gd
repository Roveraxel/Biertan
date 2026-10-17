class_name WeaveThread
extends Node2D
## A thread woven across the clearing by the Forest Mother. Snares whoever
## crosses it. Pale while being spun, then taut and red.

var a := Vector2.ZERO
var b := Vector2.ZERO
var t := 0.0
var spin := 0.8
var life := 4.0
var tick := 0.0


func _ready() -> void:
	z_index = -1


func _physics_process(delta: float) -> void:
	t += delta
	tick -= delta
	if t > spin + life:
		queue_free()
		return
	if t > spin:
		var p = get_tree().get_first_node_in_group("player")
		if p != null:
			var q: Vector2 = Geometry2D.get_closest_point_to_segment(p.global_position, a, b)
			if q.distance_to(p.global_position) < 16.0:
				p.slow_t = maxf(p.slow_t, 0.6)
				if tick <= 0.0:
					tick = 0.5
					p.hurt(5.0, Vector2.ZERO)
	queue_redraw()


func _draw() -> void:
	if t < spin:
		var k := t / spin
		draw_line(a, a.lerp(b, k), Color(0.9, 0.9, 0.8, 0.35), 1.5)
		return
	var fade := clampf(spin + life - t, 0.0, 1.0)
	draw_line(a, b, Color(0.6, 0.1, 0.1, 0.8 * fade), 3.0)
	draw_line(a, b, Color(0.9, 0.85, 0.7, 0.5 * fade), 1.0)
