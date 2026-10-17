class_name BloodBolt
extends Node2D
## A bolt of blood thrown by Vlad. Salt rings dissolve it.

var vel := Vector2.ZERO
var life := 3.0
var dmg := 10.0
var t := 0.0
var light: PointLight2D


func _ready() -> void:
	light = G.make_light(80.0, Color(1.0, 0.2, 0.15), 0.6)
	add_child(light)


func _physics_process(delta: float) -> void:
	t += delta
	life -= delta
	position += vel * delta
	if life <= 0.0:
		queue_free()
		return
	for r in get_tree().get_nodes_in_group("salt_rings"):
		if r.contains(global_position):
			queue_free()
			return
	var p = get_tree().get_first_node_in_group("player")
	if p != null and p.global_position.distance_to(global_position + Vector2(0, 14)) < 20.0:
		p.hurt(dmg, vel.normalized())
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var dir := vel.normalized()
	draw_line(Vector2(0, -14), Vector2(0, -14) - dir * 22.0, Color(0.6, 0.0, 0.05, 0.5), 7.0)
	draw_circle(Vector2(0, -14), 7.0, Color(0.75, 0.05, 0.08))
	draw_circle(Vector2(0, -14), 3.5, Color(1.0, 0.45, 0.4))
