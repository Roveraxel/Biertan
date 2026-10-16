class_name RootSpike
extends Node2D
## Telegraphed eruption of roots under the player.

const R := 48.0

var t := 0.0
var delay := 0.85
var dmg := 14.0
var done := false


func _ready() -> void:
	z_index = -1


func _physics_process(delta: float) -> void:
	t += delta
	if not done and t >= delay:
		done = true
		z_index = 0
		G.sfx("root", -4.0, randf_range(0.9, 1.1))
		var p = get_tree().get_first_node_in_group("player")
		if p != null and p.global_position.distance_to(global_position) < R + 8.0:
			p.hurt(dmg, (p.global_position - global_position).normalized())
	if t > delay + 0.6:
		queue_free()
	queue_redraw()


func _draw() -> void:
	if not done:
		var k := t / delay
		draw_circle(Vector2.ZERO, R, Color(0.1, 0.06, 0.02, 0.35))
		draw_arc(Vector2.ZERO, R * k, 0, TAU, 32, Color(0.75, 0.25, 0.1, 0.8), 3.0)
		draw_arc(Vector2.ZERO, R, 0, TAU, 32, Color(0.45, 0.3, 0.15, 0.6), 2.0)
		return
	var a := clampf(1.0 - (t - delay) / 0.6, 0.0, 1.0)
	var grow := minf(1.0, (t - delay) * 8.0)
	draw_circle(Vector2.ZERO, R * 0.9, Color(0.12, 0.08, 0.04, 0.6 * a))
	for i in 7:
		var b := Vector2.from_angle(i * TAU / 7.0 + 0.3) * R * 0.45
		var tip := b + Vector2(b.x * 0.3, -46.0 * grow)
		draw_colored_polygon(PackedVector2Array([b + Vector2(-7, 0), b + Vector2(7, 0), tip]), Color(0.29, 0.2, 0.12, a))
		draw_line(b, tip, Color(0.16, 0.1, 0.06, a), 2.0)
