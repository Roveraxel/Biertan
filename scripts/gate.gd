class_name Gate
extends StaticBody2D
## A portcullis sealed by a blood ward. Opens when the ward is broken.

var rect := Rect2()
var opened := false
var lift := 0.0
var cs: CollisionShape2D


func setup(r: Rect2) -> void:
	rect = r
	position = Vector2(r.position.x + r.size.x / 2.0, r.end.y)
	collision_layer = 1
	collision_mask = 0
	cs = CollisionShape2D.new()
	var sh := RectangleShape2D.new()
	sh.size = r.size
	cs.shape = sh
	cs.position = Vector2(0, -r.size.y / 2.0)
	add_child(cs)


func open() -> void:
	opened = true
	cs.set_deferred("disabled", true)
	G.sfx("ignite", -4.0, 0.6)


func _process(delta: float) -> void:
	if opened and lift < 1.0:
		lift = minf(1.0, lift + delta * 0.8)
		queue_redraw()


func _draw() -> void:
	var w := rect.size.x
	var h := 60.0 * (1.0 - lift)
	if h <= 1.0:
		return
	var col := Color(0.18, 0.16, 0.15)
	var x := -w / 2.0 + 6.0
	while x < w / 2.0:
		draw_line(Vector2(x, -rect.size.y), Vector2(x, -rect.size.y - h), col, 4.0)
		x += 14.0
	for i in 4:
		var y := -rect.size.y - h * (i + 0.5) / 4.0
		draw_line(Vector2(-w / 2.0, y), Vector2(w / 2.0, y), col, 3.0)
	if not opened:
		draw_circle(Vector2(0, -rect.size.y - h / 2.0), 9, Color(0.7, 0.05, 0.1, 0.8))
