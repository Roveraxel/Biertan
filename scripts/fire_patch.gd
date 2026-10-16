class_name FirePatch
extends Node2D
## Burning ground left by the Balaur's breath.

const R := 38.0

var life := 2.6
var t := 0.0
var tick := 0.0
var light: PointLight2D


func _ready() -> void:
	z_index = -1
	light = G.make_light(110.0, Color(1.0, 0.55, 0.2), 0.7)
	add_child(light)


func _physics_process(delta: float) -> void:
	t += delta
	life -= delta
	tick -= delta
	if life <= 0.0:
		queue_free()
		return
	var p = get_tree().get_first_node_in_group("player")
	if p != null and tick <= 0.0 and p.global_position.distance_to(global_position) < R:
		tick = 0.5
		p.hurt(9.0, (p.global_position - global_position).normalized())
	light.energy = 0.7 * clampf(life, 0.0, 1.0)
	queue_redraw()


func _draw() -> void:
	var a := clampf(life, 0.0, 1.0)
	draw_circle(Vector2.ZERO, R, Color(0.15, 0.05, 0.02, 0.5 * a))
	for i in 7:
		var p := Vector2.from_angle(i * 0.9 + t * 0.5) * R * 0.55
		var h := 14.0 + 8.0 * sin(t * 12.0 + i)
		draw_colored_polygon(PackedVector2Array([p + Vector2(-6, 0), p + Vector2(6, 0), p + Vector2(0, -h)]), Color(1.0, 0.5 + 0.2 * sin(t * 9.0 + i), 0.1, 0.85 * a))
