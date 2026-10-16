class_name TouchUI
extends Control
## On-screen controls for phones and tablets: floating thumbstick on the left,
## action buttons on the right. Feeds the same input actions as the keyboard.

const STICK_R := 85.0

var main
var stick_id := -1
var stick_origin := Vector2.ZERO
var stick_vec := Vector2.ZERO
var fingers := {}  # finger index -> button id
var font: Font


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	font = ThemeDB.fallback_font


func vp() -> Vector2:
	return get_viewport_rect().size


func buttons() -> Array:
	var s := vp()
	var arr := [
		{"id": "attack", "c": Vector2(s.x - 130, s.y - 130), "r": 76.0, "label": "STRIKE"},
		{"id": "dodge", "c": Vector2(s.x - 290, s.y - 70), "r": 50.0, "label": "DODGE"},
		{"id": "potion", "c": Vector2(s.x - 60, s.y - 290), "r": 44.0, "label": "DRINK"},
	]
	if main.player.salt_unlocked:
		arr.append({"id": "salt", "c": Vector2(s.x - 170, s.y - 300), "r": 44.0, "label": "SALT"})
	if main.hover != null:
		arr.append({"id": "interact", "c": Vector2(s.x - 280, s.y - 220), "r": 58.0, "label": "USE"})
	arr.append({"id": "full", "c": Vector2(s.x - 40, 40), "r": 24.0, "label": ""})
	return arr


func press(index: int, pos: Vector2) -> bool:
	for b in buttons():
		if pos.distance_to(b.c) <= b.r * 1.2:
			if b.id == "full":
				fingers[index] = "full"
				return true
			if main.state != "play":
				return false
			fingers[index] = b.id
			fire(b.id, true)
			return true
	if main.state != "play":
		return false
	if pos.x < vp().x * 0.5 and stick_id == -1:
		stick_id = index
		stick_origin = pos
		stick_vec = Vector2.ZERO
		return true
	return false


func release(index: int) -> void:
	if fingers.has(index):
		var id: String = fingers[index]
		fingers.erase(index)
		if id == "full":
			toggle_fullscreen()
		else:
			fire(id, false)
	if index == stick_id:
		stick_id = -1
		stick_vec = Vector2.ZERO
		apply_stick()


func drag(index: int, pos: Vector2) -> void:
	if index != stick_id:
		return
	var v := pos - stick_origin
	if v.length() > STICK_R:
		stick_origin = pos - v.normalized() * STICK_R
		v = pos - stick_origin
	stick_vec = v / STICK_R
	apply_stick()


func fire(action: String, down: bool) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = down
	ev.strength = 1.0 if down else 0.0
	Input.parse_input_event(ev)


func apply_stick() -> void:
	var v := stick_vec if stick_vec.length() > 0.18 else Vector2.ZERO
	_axis("move_left", maxf(-v.x, 0.0))
	_axis("move_right", maxf(v.x, 0.0))
	_axis("move_up", maxf(-v.y, 0.0))
	_axis("move_down", maxf(v.y, 0.0))


func _axis(action: String, s: float) -> void:
	if s > 0.0:
		Input.action_press(action, s)
	else:
		Input.action_release(action)


func toggle_fullscreen() -> void:
	var m := DisplayServer.window_get_mode()
	if m == DisplayServer.WINDOW_MODE_FULLSCREEN or m == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		G.touch_mode = true
		if event.pressed:
			if press(event.index, event.position):
				get_viewport().set_input_as_handled()
		else:
			release(event.index)
	elif event is InputEventScreenDrag:
		drag(event.index, event.position)


func _process(_delta: float) -> void:
	if main != null and main.state != "play":
		for idx in fingers.keys():
			if fingers[idx] != "full":
				fire(fingers[idx], false)
				fingers.erase(idx)
		if stick_id != -1:
			stick_id = -1
			stick_vec = Vector2.ZERO
			apply_stick()
	queue_redraw()


func _draw() -> void:
	if not G.touch_mode or main == null:
		return
	var s := vp()
	var down: Array = fingers.values()
	for b in buttons():
		if b.id == "full":
			var c: Vector2 = b.c
			draw_circle(c, b.r, Color(0.03, 0.03, 0.05, 0.55))
			for sx in [-1.0, 1.0]:
				for sy in [-1.0, 1.0]:
					var p := c + Vector2(sx * 9.0, sy * 9.0)
					draw_line(p, p - Vector2(sx * 6.0, 0), G.TEXT, 2.0)
					draw_line(p, p - Vector2(0, sy * 6.0), G.TEXT, 2.0)
			continue
		if main.state != "play":
			continue
		var on: bool = down.has(b.id)
		var c2: Vector2 = b.c
		draw_circle(c2, b.r, Color(0.04, 0.04, 0.07, 0.78 if on else 0.5))
		draw_arc(c2, b.r, 0, TAU, 40, Color(G.AMBER, 1.0 if on else 0.7), 3.0)
		var label: String = b.label
		if b.id == "potion":
			label = "DRINK x%d" % main.player.potions
		elif b.id == "salt":
			label = "SALT x%d" % main.player.salt
		draw_string_outline(font, c2 + Vector2(-b.r, 7), label, HORIZONTAL_ALIGNMENT_CENTER, b.r * 2.0, 17 if b.r > 50 else 14, 4, Color(0, 0, 0, 0.9))
		draw_string(font, c2 + Vector2(-b.r, 7), label, HORIZONTAL_ALIGNMENT_CENTER, b.r * 2.0, 17 if b.r > 50 else 14, G.TEXT)
	if main.state != "play":
		return
	var o := stick_origin if stick_id != -1 else Vector2(170, s.y - 140)
	draw_circle(o, STICK_R, Color(0.04, 0.04, 0.07, 0.35 if stick_id != -1 else 0.2))
	draw_arc(o, STICK_R, 0, TAU, 48, Color(G.AMBER, 0.6 if stick_id != -1 else 0.3), 3.0)
	draw_circle(o + stick_vec * STICK_R, 34.0, Color(G.AMBER, 0.55 if stick_id != -1 else 0.25))
