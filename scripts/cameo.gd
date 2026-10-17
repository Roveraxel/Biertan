class_name Cameo
extends Node2D
## A villager who runs on, says their piece in a speech bubble, and runs off.

var tex_path := "res://assets/sprites/npc_magda.svg"
var vel := Vector2.ZERO
var line := ""
var life := 4.0
var t := 0.0
var stop_at := -1.0  # seconds until she stops (and acts), -1 = keep running
var resume_after := 1.6
var action: Callable = Callable()
var acted := false


func _process(delta: float) -> void:
	t += delta
	if stop_at >= 0.0 and t >= stop_at and t < stop_at + resume_after:
		if not acted:
			acted = true
			if action.is_valid():
				action.call()
	else:
		position += vel * delta
	if t > life:
		queue_free()
	queue_redraw()


func _draw() -> void:
	var tex := G.tex(tex_path)
	var bob := absf(sin(t * 14.0)) * 4.0 if (stop_at < 0.0 or t < stop_at or t > stop_at + resume_after) else 0.0
	var flip := vel.x < 0.0
	draw_set_transform(Vector2(0, -bob), 0, Vector2(-1.0 if flip else 1.0, 1.0))
	if tex != null:
		draw_texture_rect(tex, Rect2(-40, -69, 80, 80), false)
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	if line != "":
		var f := ThemeDB.fallback_font
		var w := f.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x + 24.0
		var r := Rect2(-w / 2.0, -118, w, 32)
		draw_rect(r, Color(0.95, 0.92, 0.85, 0.95))
		draw_colored_polygon(PackedVector2Array([Vector2(-8, -86), Vector2(8, -86), Vector2(0, -74)]), Color(0.95, 0.92, 0.85, 0.95))
		draw_string(f, Vector2(-w / 2.0 + 12, -96), line, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("2a1414"))
