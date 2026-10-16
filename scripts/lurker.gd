class_name Lurker
extends Node2D
## A pair of red eyes that watches the player from the dark, follows at a
## distance, blinks, and slips away when approached.

var player: Node2D
var t := 0.0
var life := 7.0
var fade := 0.0
var blink_t := 2.0
var closed := 0.0
var fleeing := false
var light: PointLight2D


func _ready() -> void:
	add_to_group("lurkers")
	player = get_tree().get_first_node_in_group("player")
	life = randf_range(5.0, 9.0)
	blink_t = randf_range(1.2, 3.0)
	light = G.make_light(80.0, Color(1.0, 0.1, 0.06), 1.7)
	light.position = Vector2(0, -40)
	add_child(light)


func _process(delta: float) -> void:
	t += delta
	if player == null or not is_instance_valid(player):
		queue_free()
		return
	var to := player.global_position - global_position
	var d := to.length()
	if not fleeing:
		if d > 390.0:
			global_position += to.normalized() * 95.0 * delta
		if d < 150.0 or life <= 0.0:
			fleeing = true
	life -= delta
	if fleeing:
		fade -= delta * 3.5
		if fade <= 0.0:
			queue_free()
			return
	else:
		fade = move_toward(fade, 1.0, delta * 1.4)
	blink_t -= delta
	if blink_t <= 0.0:
		closed = 0.16
		blink_t = randf_range(1.5, 3.5)
	closed = maxf(0.0, closed - delta)
	light.energy = 1.7 * (0.0 if closed > 0.0 else fade)
	queue_redraw()


func _draw() -> void:
	if player == null or not is_instance_valid(player):
		return
	var vis := 0.0 if closed > 0.0 else fade
	if vis <= 0.01:
		return
	var look := (player.global_position - global_position).normalized() * 1.6
	for side in [-1.0, 1.0]:
		var c := Vector2(side * 9.0, -40.0) + look
		draw_circle(c, 7.0, Color(1.0, 0.1, 0.06, 0.28 * vis))
		var pts := PackedVector2Array([
			c + Vector2(-5.0 * side, 1.5), c + Vector2(0.0, -3.2), c + Vector2(5.0 * side, -1.0), c + Vector2(0.5 * side, 2.4),
		])
		draw_colored_polygon(pts, Color(1.0, 0.16, 0.1, vis))
		draw_line(c + Vector2(0, -2.2), c + Vector2(0, 1.6), Color(0.15, 0.0, 0.0, vis), 1.4)
