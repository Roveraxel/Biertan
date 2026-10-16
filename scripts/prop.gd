class_name Prop
extends StaticBody2D
## Interactable world object: NPC, coin sack, torn fleece, signpost.

var main
var kind := "npc"
var id := ""
var display := ""
var col := Color("a05030")
var prompt := ""
var used := false
var t := 0.0


func _ready() -> void:
	add_to_group("interactable")
	collision_layer = 1
	collision_mask = 0
	var cs := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = 12.0
	cs.shape = c
	add_child(cs)


func can_interact() -> bool:
	return not (used and kind == "sack")


func interact() -> void:
	main.prop_used(self)


func prompt_text() -> String:
	return prompt


func _process(delta: float) -> void:
	t += delta
	queue_redraw()


func _draw() -> void:
	var f := ThemeDB.fallback_font
	draw_set_transform(Vector2(0, 2), 0, Vector2(1, 0.45))
	draw_circle(Vector2.ZERO, 15, Color(0, 0, 0, 0.35))
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	match kind:
		"npc":
			var bob := sin(t * 2.0 + position.x) * 1.0
			draw_circle(Vector2(0, -14 + bob), 12, col)
			draw_circle(Vector2(0, -16 + bob), 8, col.lightened(0.15))
			draw_circle(Vector2(0, -30 + bob), 8, Color("d9b48f"))
			draw_circle(Vector2(0, -34 + bob), 8, col.darkened(0.45))
			draw_circle(Vector2(0, -30 + bob), 5.5, Color("d9b48f"))
			draw_string_outline(f, Vector2(-110, -50), display, HORIZONTAL_ALIGNMENT_CENTER, 220, 13, 4, Color(0, 0, 0, 0.9))
			draw_string(f, Vector2(-110, -50), display, HORIZONTAL_ALIGNMENT_CENTER, 220, 13, G.TEXT)
			if main != null and main.marker_for(id):
				draw_string_outline(f, Vector2(-10, -66 + sin(t * 4.0) * 2.0), "!", HORIZONTAL_ALIGNMENT_CENTER, 20, 22, 5, Color(0, 0, 0, 0.9))
				draw_string(f, Vector2(-10, -66 + sin(t * 4.0) * 2.0), "!", HORIZONTAL_ALIGNMENT_CENTER, 20, 22, G.AMBER)
		"sack":
			if not used:
				draw_circle(Vector2(0, -8), 10, Color("8a6a3a"))
				draw_circle(Vector2(0, -16), 5, Color("8a6a3a"))
				draw_rect(Rect2(-4, -20, 8, 3), Color("c9a24a"))
		"fleece":
			draw_circle(Vector2(0, -4), 12, Color("cfc6b3"))
			draw_circle(Vector2(8, -2), 7, Color("9a2020", 0.6))
			draw_circle(Vector2(-6, -6), 6, Color("e8e0cc"))
		"sign":
			draw_rect(Rect2(-2, -34, 4, 34), Color("4a3320"))
			draw_rect(Rect2(-16, -40, 32, 16), Color("6b4a2e"))
			draw_line(Vector2(-10, -34), Vector2(10, -34), Color("2a1c10"), 2.0)
