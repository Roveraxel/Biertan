class_name Fx
extends Node2D
## Short-lived visual effect (expanding ring or floating text).

var kind := "ring"
var t := 0.0
var life := 0.4
var col := Color.WHITE
var r0 := 8.0
var r1 := 50.0
var text := ""


func _ready() -> void:
	z_index = 50


func _process(delta: float) -> void:
	t += delta
	if t >= life:
		queue_free()
	queue_redraw()


func _draw() -> void:
	var k := clampf(t / life, 0.0, 1.0)
	if kind == "ring":
		draw_arc(Vector2.ZERO, lerpf(r0, r1, k), 0.0, TAU, 28, Color(col, col.a * (1.0 - k)), 3.0)
	else:
		var f := ThemeDB.fallback_font
		draw_string_outline(f, Vector2(-30, -34 - 30 * k), text, HORIZONTAL_ALIGNMENT_CENTER, 60, 16, 4, Color(0, 0, 0, 1.0 - k))
		draw_string(f, Vector2(-30, -34 - 30 * k), text, HORIZONTAL_ALIGNMENT_CENTER, 60, 16, Color(col, 1.0 - k))
