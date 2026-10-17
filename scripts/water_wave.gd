class_name WaterWave
extends Node2D
## A ring of lake water spat out by the thirsting head. Dodge through it.

var r := 30.0
var speed := 430.0
var band := 34.0
var max_r := 900.0
var hit := false
var dmg := 16.0
var fire := false


func _physics_process(delta: float) -> void:
	r += speed * delta
	if r > max_r:
		queue_free()
		return
	var p = get_tree().get_first_node_in_group("player")
	if p != null and not hit:
		var dv: Vector2 = p.global_position - global_position
		dv.y /= 0.75
		var dd: float = dv.length()
		if absf(dd - r) < band * 0.5 and p.inv_t <= 0.0:
			hit = true
			p.hurt(dmg, (p.global_position - global_position).normalized())
	queue_redraw()


func _draw() -> void:
	var a := clampf(1.0 - r / max_r, 0.0, 1.0)
	draw_set_transform(Vector2.ZERO, 0, Vector2(1, 0.75))
	var c1 := Color(1.0, 0.4, 0.1, 0.75 * a) if fire else Color(0.45, 0.65, 0.8, 0.7 * a)
	var c2 := Color(1.0, 0.85, 0.4, 0.7 * a) if fire else Color(0.9, 0.95, 1.0, 0.6 * a)
	draw_arc(Vector2.ZERO, r, 0, TAU, 72, c1, band)
	draw_arc(Vector2.ZERO, r + band * 0.4, 0, TAU, 72, c2, 3.0)
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
