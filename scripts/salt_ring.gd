class_name SaltRing
extends Node2D
## A circle of thrown salt. The unclean dead cannot cross it and burn inside it.

const RADIUS := 120.0

var life := 6.0
var t := 0.0
var specks: Array = []
var light: PointLight2D


func _ready() -> void:
	add_to_group("salt_rings")
	z_index = -1
	for i in 70:
		var a := randf() * TAU
		specks.append([Vector2.from_angle(a) * RADIUS * randf_range(0.93, 1.05), randf_range(1.0, 2.6), randf() * TAU])
	light = G.make_light(RADIUS * 1.5, Color(0.85, 0.9, 1.0), 0.45)
	add_child(light)
	G.fx_ring(get_parent(), global_position, Color(1, 1, 1, 0.8), RADIUS, 0.4)


func contains(p: Vector2, extra := 0.0) -> bool:
	return p.distance_to(global_position) < RADIUS + extra


func _physics_process(delta: float) -> void:
	t += delta
	life -= delta
	if life <= 0.0:
		queue_free()
		return
	for e in get_tree().get_nodes_in_group("enemies"):
		if e.has_method("undead") and e.undead() and contains(e.global_position, e.radius):
			e.salt_hit(self, delta)
	light.energy = 0.45 * clampf(life, 0.0, 1.0)
	queue_redraw()


func _draw() -> void:
	var a := clampf(life, 0.0, 1.0)
	draw_arc(Vector2.ZERO, RADIUS, 0, TAU, 64, Color(0.95, 0.96, 1.0, 0.35 * a), 6.0)
	draw_circle(Vector2.ZERO, RADIUS, Color(0.9, 0.92, 1.0, 0.05 * a))
	for s in specks:
		var tw := 0.6 + 0.4 * sin(t * 6.0 + s[2])
		draw_circle(s[0], s[1], Color(1, 1, 1, tw * a))
