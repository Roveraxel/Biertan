class_name Block
extends StaticBody2D
## Solid rectangular structure (walls, houses, towers). Origin is bottom-centre
## of the footprint so y-sorting works; the drawn top is lifted by `h` for a 3/4 view.

var rect := Rect2()
var style := "wall"
var h := 18.0


func setup(r: Rect2, s: String, hh: float) -> void:
	rect = r
	style = s
	h = hh
	position = Vector2(r.position.x + r.size.x / 2.0, r.end.y)
	collision_layer = 1
	collision_mask = 0
	var cs := CollisionShape2D.new()
	var sh := RectangleShape2D.new()
	sh.size = r.size
	cs.shape = sh
	cs.position = Vector2(0, -r.size.y / 2.0)
	add_child(cs)


func _draw() -> void:
	if style == "hidden":
		return
	var w := rect.size.x
	var d := rect.size.y
	var top := Color("8d877a")
	var face := Color("5d584f")
	var windows := false
	match style:
		"wall":
			top = Color("a8a292"); face = Color("6b665b")
		"house":
			top = Color("8a3a2a"); face = Color("d8d2c0"); windows = true
		"church":
			top = Color("6e2f25"); face = Color("e0d9c4"); windows = true
		"tower":
			top = Color("7a2e22"); face = Color("cfc8b2")
		"ruin":
			top = Color("5d584f"); face = Color("3a3731")
		"stone":
			top = Color("8d877a"); face = Color("5d584f")
		"rock":
			top = Color("4a4540"); face = Color("2c2926")
	draw_rect(Rect2(-w / 2.0, -h, w, h), face)
	draw_rect(Rect2(-w / 2.0, -d - h, w, d), top)
	draw_rect(Rect2(-w / 2.0, -d - h, w, d), Color(0, 0, 0, 0.35), false, 2.0)
	draw_line(Vector2(-w / 2.0, -h), Vector2(w / 2.0, -h), Color(0, 0, 0, 0.35), 2.0)
	if style == "wall" and w > d:
		var x := -w / 2.0 + 10.0
		while x < w / 2.0 - 6.0:
			draw_rect(Rect2(x, -d - h - 5.0, 12, 6), top.darkened(0.1))
			x += 24.0
	if style == "house" or style == "church":
		draw_line(Vector2(-w / 2.0, -d / 2.0 - h), Vector2(w / 2.0, -d / 2.0 - h), top.darkened(0.3), 3.0)
	if style == "tower":
		draw_rect(Rect2(-w / 2.0 + 10, -d - h + 10, w - 20, d - 20), top.darkened(0.25))
		draw_line(Vector2(0, -d - h + 14), Vector2(0, -d - h + 40), G.AMBER.darkened(0.2), 3.0)
		draw_line(Vector2(-8, -d - h + 24), Vector2(8, -d - h + 24), G.AMBER.darkened(0.2), 3.0)
	if style == "rock":
		var r := RandomNumberGenerator.new()
		r.seed = int(position.x * 7.0 + position.y * 13.0)
		for i in 5:
			var p := Vector2(r.randf_range(-w / 2.0 + 6, w / 2.0 - 6), r.randf_range(-d - h + 6, -h - 4))
			draw_line(p, p + Vector2(r.randf_range(-14, 14), r.randf_range(-6, 6)), Color(0.85, 0.87, 0.9, 0.35), 2.0)
		draw_rect(Rect2(-w / 2.0, -h, w, 4), Color(0, 0, 0, 0.3))
	if windows and h > 20.0:
		var n := int(w / 60.0)
		for i in n:
			var wx := -w / 2.0 + (i + 0.5) * w / n - 4.0
			draw_rect(Rect2(wx, -h + 8.0, 8, h * 0.45), G.AMBER)
