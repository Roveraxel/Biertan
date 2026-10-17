class_name Hud
extends Control
## Title screen (ported from the welcome-screen design) and in-game HUD.

const ITEMS := ["Begin the Hunt", "Continue", "Bestiary", "Settings", "Leave the Valley"]
var ENABLED := [true, false, true, false, true]
var best_idx := 0
var best_scroll := 0.0

var main
var toasts: Array = []
var banner_text := ""
var banner_sub := ""
var banner_t := 0.0
var t := 0.0
var menu_idx := 0
var font: Font
var msg := ""
var msg_t := 0.0
var play_time := 0.0
var stars := [
	Vector2(1320, 70), Vector2(1240, 140), Vector2(1390, 190), Vector2(880, 90), Vector2(940, 170),
	Vector2(760, 60), Vector2(1000, 50), Vector2(1180, 40), Vector2(640, 150), Vector2(560, 80),
	Vector2(1420, 320), Vector2(700, 260), Vector2(420, 120), Vector2(300, 60), Vector2(200, 180),
]


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	font = ThemeDB.fallback_font
	ENABLED[1] = FileAccess.file_exists("user://biertan_save.json")
	if ENABLED[1]:
		menu_idx = 1


func _process(delta: float) -> void:
	t += delta
	msg_t = maxf(0.0, msg_t - delta)
	banner_t = maxf(0.0, banner_t - delta)
	if main != null and main.state != "title":
		play_time += delta
	for i in range(toasts.size() - 1, -1, -1):
		toasts[i][1] -= delta
		if toasts[i][1] <= 0.0:
			toasts.remove_at(i)
	queue_redraw()


# ------------------------------------------------------------- title input

func menu_rect(i: int) -> Rect2:
	return Rect2(88, 462 + i * 56, 520, 52)


func title_input(event: InputEvent) -> void:
	var s := size.x / 1440.0
	if event is InputEventMouseMotion:
		var p: Vector2 = event.position / s
		for i in ITEMS.size():
			if menu_rect(i).has_point(p):
				menu_idx = i
	elif (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT) or (event is InputEventScreenTouch and event.pressed):
		var p: Vector2 = event.position / s
		for i in ITEMS.size():
			if menu_rect(i).has_point(p):
				menu_idx = i
				activate(i)
	elif event is InputEventKey and event.pressed:
		if event.keycode == KEY_DOWN or event.keycode == KEY_S:
			menu_idx = (menu_idx + 1) % ITEMS.size()
		elif event.keycode == KEY_UP or event.keycode == KEY_W:
			menu_idx = (menu_idx + ITEMS.size() - 1) % ITEMS.size()
		elif event.keycode == KEY_ENTER or event.keycode == KEY_SPACE or event.keycode == KEY_E:
			activate(menu_idx)


func activate(i: int) -> void:
	if not ENABLED[i]:
		msg = "%s is not yet part of this tale." % ITEMS[i]
		msg_t = 2.5
		return
	if i == 0:
		play_time = 0.0
		main.start_game()
	elif i == 1:
		play_time = 0.0
		main.continue_game()
	elif i == 2:
		main.state = "bestiary"
		best_idx = 0
	elif i == 4:
		if OS.has_feature("web"):
			msg = "Close the tab to leave the valley."
			msg_t = 2.5
		else:
			get_tree().quit()


# ------------------------------------------------------------- helpers

func txt(pos: Vector2, s: String, fs: int, col: Color, align := HORIZONTAL_ALIGNMENT_LEFT, w := -1.0) -> void:
	draw_string_outline(font, pos, s, align, w, fs, maxi(2, fs / 6), Color(0, 0, 0, col.a * 0.85))
	draw_string(font, pos, s, align, w, fs, col)


func bar(r: Rect2, frac: float, col: Color) -> void:
	draw_rect(r.grow(2), Color(0, 0, 0, 0.75))
	draw_rect(r, Color(0.12, 0.1, 0.1, 0.9))
	draw_rect(Rect2(r.position, Vector2(r.size.x * clampf(frac, 0.0, 1.0), r.size.y)), col)
	draw_rect(r.grow(2), G.AMBER.darkened(0.45), false, 1.5)


# ------------------------------------------------------------- draw

func _draw() -> void:
	if main == null:
		return
	if main.state == "title":
		draw_title()
	elif main.state == "ending":
		draw_ending()
	elif main.state == "story":
		draw_story()
	elif main.state == "bestiary":
		draw_bestiary()
	else:
		draw_hud()


func pine(x: float, y: float, sc: float, col: Color) -> void:
	var pts := PackedVector2Array([
		Vector2(0, 0), Vector2(-14, 40), Vector2(-6, 40), Vector2(-22, 80), Vector2(-8, 80), Vector2(-30, 125),
		Vector2(-4, 125), Vector2(-4, 140), Vector2(4, 140), Vector2(4, 125), Vector2(30, 125), Vector2(8, 80),
		Vector2(22, 80), Vector2(6, 40), Vector2(14, 40),
	])
	for i in pts.size():
		pts[i] = pts[i] * sc + Vector2(x, y)
	draw_colored_polygon(pts, col)


func draw_title() -> void:
	var s := size.x / 1440.0
	var design := Transform2D(0.0, Vector2(s, s), 0.0, Vector2.ZERO)
	draw_set_transform_matrix(design)
	var photo: Texture2D = G.tex("res://assets/art/title_biertan.jpg") if ResourceLoader.exists("res://assets/art/title_biertan.jpg") else null
	if photo != null:
		# Biertan at night, from a photo of the real village
		draw_texture_rect(photo, Rect2(0, 0, 1440, 810), false)
		for i in 8:
			draw_circle(Vector2(1150, 150), 300 - i * 32, Color(G.BLOOD, 0.045))
		draw_circle(Vector2(1150, 150), 84, Color(G.BLOOD, 0.9))
		for c in [[Vector2(1124, 128), 16.0], [Vector2(1172, 178), 12.0], [Vector2(1180, 120), 7.0]]:
			draw_circle(c[0], c[1], Color(0, 0, 0, 0.12))
		var flp := 0.55 + 0.25 * sin(t * 4.0)
		for r in [Rect2(774, 640, 8, 20), Rect2(828, 640, 8, 20), Rect2(1240, 600, 6, 14), Rect2(1335, 470, 6, 10)]:
			draw_rect(r, Color(G.AMBER, flp))
	else:
		draw_title_bg()
	var pc := Color("050508")
	# mist
	for m in [[520.0, 0.16, 0.0], [600.0, 0.12, 1.7]]:
		var mx: float = 720.0 + sin(t * m[1] + m[2]) * 80.0
		draw_set_transform_matrix(Transform2D(0.0, Vector2(s * 1.0, s * 0.17), 0.0, Vector2(mx * s, (m[0] + 120.0) * s)))
		draw_circle(Vector2.ZERO, 820, Color(0.59, 0.63, 0.69, 0.07))
	draw_set_transform_matrix(design)
	# bats
	for i in 3:
		var bx := 1000.0 + sin(t * 0.5 + i * 2.1) * 220.0
		var by := 270.0 + i * 70.0 + sin(t * 0.8 + i) * 50.0
		var fl2 := 0.3 + 0.7 * absf(sin(t * 10.0 + i))
		draw_colored_polygon(PackedVector2Array([Vector2(bx, by), Vector2(bx - 16, by - 8 * fl2), Vector2(bx - 28, by + 2), Vector2(bx - 8, by + 4), Vector2(bx + 8, by + 4), Vector2(bx + 28, by + 2), Vector2(bx + 16, by - 8 * fl2)]), pc)
	draw_polygon(
		PackedVector2Array([Vector2(0, 0), Vector2(760, 0), Vector2(760, 810), Vector2(0, 810)]),
		PackedColorArray([Color(0.02, 0.02, 0.03, 0.88), Color(0.02, 0.02, 0.03, 0.0), Color(0.02, 0.02, 0.03, 0.0), Color(0.02, 0.02, 0.03, 0.88)]))
	txt(Vector2(96, 250), "Anno MDXXI · Siebenbürgen", 20, G.MUTED.darkened(0.15))
	draw_string_outline(font, Vector2(92, 372), "Biertan", HORIZONTAL_ALIGNMENT_LEFT, -1, 132, 10, Color(0, 0, 0, 0.8))
	draw_string(font, Vector2(92, 372), "Biertan", HORIZONTAL_ALIGNMENT_LEFT, -1, 132, G.TEXT)
	txt(Vector2(96, 424), "A Hunter’s Ballad of Transylvania", 28, G.MUTED)
	for i in ITEMS.size():
		var r := menu_rect(i)
		var sel := i == menu_idx
		var col := G.TEXT if sel else G.MUTED
		if not ENABLED[i]:
			col.a = 0.45
		var off := 6.0 if sel else 0.0
		if sel:
			var py := r.position.y + r.size.y / 2.0
			draw_colored_polygon(PackedVector2Array([Vector2(r.position.x + 8, py), Vector2(r.position.x + 16, py - 7), Vector2(r.position.x + 24, py), Vector2(r.position.x + 16, py + 7)]), G.BLOOD)
		txt(Vector2(r.position.x + 40 + off, r.position.y + 38), ITEMS[i], 32, col)
	txt(Vector2(96, 790), "Salt for the dead. Silver for what walks.", 18, G.MUTED.darkened(0.3))
	txt(Vector2(1344, 790), "Tap to begin · Left thumb moves · Strike auto-aims" if G.touch_mode else "WASD move · Mouse attack · Space dodge · E interact · Q tincture", 15, G.MUTED.darkened(0.35), HORIZONTAL_ALIGNMENT_RIGHT, 700)
	if msg_t > 0.0:
		txt(Vector2(96, 760), msg, 20, Color(G.AMBER, minf(1.0, msg_t)))
	draw_set_transform_matrix(Transform2D.IDENTITY)


func draw_hud() -> void:
	var p: Player = main.player
	var k := 1.3 if G.touch_mode else 1.0
	draw_set_transform_matrix(Transform2D(0.0, Vector2(k, k), 0.0, Vector2.ZERO))
	var sz := size / k
	if p.hurt_flash > 0.0:
		draw_rect(Rect2(Vector2.ZERO, sz), Color(0.7, 0.05, 0.05, p.hurt_flash * 0.8))
	if main.current == "hollow" and p.madness > p.max_hp:
		var mk: float = (p.madness - p.max_hp) / p.max_hp
		draw_rect(Rect2(Vector2.ZERO, sz), Color(0.3, 0.1, 0.4, 0.12 * mk + 0.05 * mk * sin(t * 5.0)))
	if p.vamp_t > 0.0:
		draw_rect(Rect2(Vector2.ZERO, sz), Color(0.4, 0.0, 0.05, 0.12))
	bar(Rect2(24, 24, 250, 18), p.hp / p.max_hp, Color("b3372f"))
	txt(Vector2(30, 38), "HEALTH  %d / %d" % [int(p.hp), int(p.max_hp)], 13, G.TEXT)
	if main.current in ["forest", "hills", "vineyard"]:
		bar(Rect2(24, 54, 250, 8), G.dusk, Color("5a6aa8").lerp(Color("e8a94a"), 1.0 - G.dusk))
		var dl := "DUSK" if G.dusk < 0.85 else ("NIGHT FALLS" if G.dusk < 1.0 else "MIDNIGHT")
		txt(Vector2(284, 62), dl, 12, G.TEXT if G.dusk < 0.85 else G.BLOOD)
	elif main.current == "hollow":
		var cap: float = p.max_hp * 2.0
		bar(Rect2(24, 54, 250, 8), p.madness / cap, Color("7a4aa8"))
		txt(Vector2(284, 62), "MADNESS" if p.madness < cap * 0.75 else "THE WOOD WHISPERS", 12, Color("b08ad8"))
	elif main.current == "church":
		if p.vamp_t > 0.0:
			bar(Rect2(24, 54, 250, 8), p.vamp_t / 18.0, Color("8a0a14"))
			txt(Vector2(284, 62), "VAMPIRE  (tinctures burn)", 12, G.BLOOD)
		else:
			bar(Rect2(24, 54, 250, 8), p.blood / 5.0, Color("8a0a14"))
			txt(Vector2(284, 62), "BLOOD CURSE", 12, Color("d07070"))
	elif main.current in ["hub", "richis", "mosna", "biertan"]:
		txt(Vector2(24, 62), "SAFE HAVEN", 12, G.AMBER)
	if p.haste_t > 0.0:
		txt(Vector2(284, 38), "SWIFT %ds" % int(p.haste_t), 12, Color(0.7, 0.9, 0.6))
	var inv := "Coins %d      Tinctures %d%s" % [p.coins, p.potions, "" if G.touch_mode else "  (Q)"]
	if p.salt_unlocked:
		inv += "      Salt %d%s" % [p.salt, "" if G.touch_mode else "  (R)"]
	txt(Vector2(24, 90), inv, 14, G.AMBER)
	var q := ""
	match main.quest:
		0: q = "Speak with Frau Anna at the inn."
		1: q = "Quest: Where the Sheep Went. Slay the beast of the Wolf Forest."
		2: q = "Return to Frau Anna with the Silver Thread."
		3: q = "Level 1 complete. Take the east gate to Richiș."
	if main.visited_richis:
		match main.quest2:
			0: q = "Speak with the pastor of Richiș."
			1: q = "Quest: The Singing Children. Cross the Hollow Hills and the Salt Caves." if not main.met_vasile else "Quest: The Singing Children. Find Muma Pădurii's Hollow beyond the Salt Caves."
			2: q = "Return to the pastor of Richiș."
			3: q = "Level 2 complete. Take Richiș's east gate to Moșna."
	if main.visited_mosna:
		match main.quest3:
			0: q = "Speak with Meister Konrad, the bell-founder."
			1: q = "Quest: The Road to Biertan. Slay the Balaur in the drowned quarry."
			2: q = "Return to Meister Konrad in Moșna."
			3: q = "Level 3 complete. Take Moșna's east gate to Biertan."
	if main.visited_biertan:
		match main.quest4:
			0: q = "Speak with the sexton at the Marriage Prison."
			1: q = "Quest: The Bells of Biertan. Break the blood wards and destroy Strigoi Vlad."
			2: q = "The bells of Biertan ring again."
	txt(Vector2(24, 112), q, 14, G.MUTED)
	for i in toasts.size():
		var a: float = minf(1.0, toasts[i][1])
		txt(Vector2(sz.x - 24, (84 if G.touch_mode else 40) + i * 26), toasts[i][0], 15, Color(G.TEXT, a), HORIZONTAL_ALIGNMENT_RIGHT, 760)
	if banner_t > 0.0:
		var a := minf(1.0, banner_t) * minf(1.0, (3.6 - banner_t) * 3.0)
		txt(Vector2(0, 150), banner_text, 44, Color(G.TEXT, a), HORIZONTAL_ALIGNMENT_CENTER, sz.x)
		txt(Vector2(0, 190), banner_sub, 18, Color(G.MUTED, a), HORIZONTAL_ALIGNMENT_CENTER, sz.x)
	var bs = main.boss
	if bs != null and is_instance_valid(bs):
		var r := Rect2(sz.x / 2.0 - 280, 60, 560, 14)
		bar(r, bs.hp / bs.max_hp, Color("b3372f"))
		draw_line(Vector2(r.position.x + r.size.x * 0.33, r.position.y), Vector2(r.position.x + r.size.x * 0.33, r.end.y), Color.BLACK, 2.0)
		draw_line(Vector2(r.position.x + r.size.x * 0.66, r.position.y), Vector2(r.position.x + r.size.x * 0.66, r.end.y), Color.BLACK, 2.0)
		txt(Vector2(0, 52), bs.hud_name(), 18, G.TEXT, HORIZONTAL_ALIGNMENT_CENTER, sz.x)
		var hint_s: String = bs.hud_hint()
		if G.touch_mode:
			hint_s = hint_s.replace("(R)", "(SALT)")
		if hint_s != "":
			txt(Vector2(0, 98), hint_s, 14, G.AMBER, HORIZONTAL_ALIGNMENT_CENTER, sz.x)
	if main.state == "play" and main.hover != null:
		var pt: String = main.hover.prompt_text()
		if G.touch_mode:
			pt = pt.replace("E   ", "")
		txt(Vector2(0, sz.y - 70), pt, 20, G.AMBER, HORIZONTAL_ALIGNMENT_CENTER, sz.x)
	if main.state == "dialogue":
		var r := Rect2(150, sz.y - 210, sz.x - 300, 170)
		draw_rect(r, Color(0.03, 0.03, 0.05, 0.92))
		draw_rect(r, G.AMBER.darkened(0.3), false, 2.0)
		txt(Vector2(r.position.x + 24, r.position.y + 34), main.dlg_speaker, 20, G.AMBER)
		draw_multiline_string(font, Vector2(r.position.x + 24, r.position.y + 68), main.dlg_lines[main.dlg_idx], HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 48, 19, -1, G.TEXT)
		txt(Vector2(r.end.x - 24, r.end.y - 14), ("tap  >" if G.touch_mode else "E / click  >"), 14, G.MUTED, HORIZONTAL_ALIGNMENT_RIGHT, 200)
	if main.state == "dead":
		draw_rect(Rect2(Vector2.ZERO, sz), Color(0.1, 0, 0, 0.6))
		txt(Vector2(0, sz.y / 2.0), "YOU HAVE FALLEN", 56, G.BLOOD, HORIZONTAL_ALIGNMENT_CENTER, sz.x)
		txt(Vector2(0, sz.y / 2.0 + 44), ("Tap" if G.touch_mode else "Press E") + " to rise again in " + main.home_name(), 20, G.MUTED, HORIZONTAL_ALIGNMENT_CENTER, sz.x)
	if play_time < 25.0 and main.state != "dead":
		var hint := "Left thumb: move · Strike auto-aims · tap USE near people" if G.touch_mode else "WASD move · Mouse aim + click attack · Space dodge · E interact · Q tincture"
		txt(Vector2(24, sz.y - 24), hint, 14, Color(G.MUTED, clampf(25.0 - play_time, 0.0, 1.0)))


func draw_ending() -> void:
	var sz := size
	draw_rect(Rect2(Vector2.ZERO, sz), Color(0.02, 0.02, 0.03))
	var e: float = main.ending_t
	var lines := [
		["THE BELLS OF BIERTAN", 52, G.TEXT],
		["", 18, G.MUTED],
		["At dawn the great bell rang over the valley, and the Iele stopped their dancing.", 20, G.MUTED],
		["In Saschiz, Frau Anna's sheep came home. In Richiș, the children sang in church, and only there.", 20, G.MUTED],
		["In Moșna, the carters took the Biertan road. In the vineyards, the dead lay still.", 20, G.MUTED],
		["And in the Marriage Prison, Andreas and Sofia asked the council for one more week.", 20, G.MUTED],
		["", 18, G.MUTED],
		["Salt for the dead. Silver for what walks.", 22, G.AMBER],
		["", 18, G.MUTED],
		["BIERTAN · A Hunter's Ballad of Transylvania", 16, G.MUTED.darkened(0.3)],
		["Made with Godot · art and sound generated in code", 14, G.MUTED.darkened(0.4)],
	]
	var y := sz.y * 0.22
	for i in lines.size():
		var a := clampf(e - i * 0.6, 0.0, 1.0)
		var l: Array = lines[i]
		txt(Vector2(0, y), l[0], l[1], Color(l[2], a), HORIZONTAL_ALIGNMENT_CENTER, sz.x)
		y += l[1] + 18
	if e > 4.0:
		var a := 0.5 + 0.5 * sin(t * 3.0)
		txt(Vector2(0, sz.y - 40), "Tap to return" if G.touch_mode else "Press any key to return", 16, Color(G.MUTED, a), HORIZONTAL_ALIGNMENT_CENTER, sz.x)


var _credits: Dictionary = {}


func photo_credit(id: String) -> String:
	if _credits.is_empty() and FileAccess.file_exists("res://assets/photos/credits.json"):
		var d = JSON.parse_string(FileAccess.get_file_as_string("res://assets/photos/credits.json"))
		if typeof(d) == TYPE_DICTIONARY:
			_credits = d
	if not _credits.has(id):
		return ""
	var c: Dictionary = _credits[id]
	return "Photo: %s · %s · Wikimedia Commons" % [c.get("artist", "?"), c.get("license", "")]


func draw_story() -> void:
	var sz := size
	var id: String = main.story_id
	var st: Dictionary = main.STORIES.get(id, {})
	var e: float = maxf(main.story_t, 0.0) if main.story_t > -1.0 else 9.0
	draw_rect(Rect2(Vector2.ZERO, sz), Color(0.02, 0.02, 0.03))
	var s := minf(sz.x / 1280.0, sz.y / 720.0)
	draw_set_transform(Vector2((sz.x - 1280.0 * s) / 2.0, (sz.y - 720.0 * s) / 2.0), 0, Vector2(s, s))
	var frame := Rect2(60, 90, 640, 480)
	var path := "res://assets/photos/%s.jpg" % id
	var own := id == "biertan" and ResourceLoader.exists("res://assets/art/biertan_story.jpg")
	if own:
		path = "res://assets/art/biertan_story.jpg"
	var tex: Texture2D = G.tex(path) if ResourceLoader.exists(path) else null
	draw_rect(frame.grow(8), Color("3a2e20"))
	if tex != null:
		var ts := tex.get_size()
		var fa := Color(1, 1, 1, clampf(e, 0.0, 1.0))
		if ts.x / ts.y < 1.1:
			# portrait photo: show it whole, centred on a dark mat
			draw_rect(frame, Color("14110e"))
			var kc := minf(frame.size.x / ts.x, frame.size.y / ts.y)
			var dsz := ts * kc
			draw_texture_rect(tex, Rect2(frame.get_center() - dsz / 2.0, dsz), false, fa)
		else:
			var k := maxf(frame.size.x / ts.x, frame.size.y / ts.y)
			var src := Rect2((ts - frame.size / k) / 2.0, frame.size / k)
			draw_texture_rect_region(tex, frame, src, fa)
	else:
		draw_rect(frame, Color("1a2a3a"))
		draw_circle(frame.position + Vector2(470, 120), 60, Color("e8c070"))
		for i in 4:
			draw_circle(frame.position + Vector2(80 + i * 170, 520), 220, Color(0.2 + i * 0.05, 0.35, 0.18))
		draw_rect(Rect2(frame.position + Vector2(250, 220), Vector2(140, 120)), Color("d8d2c0"))
		draw_colored_polygon(PackedVector2Array([frame.position + Vector2(240, 220), frame.position + Vector2(400, 220), frame.position + Vector2(320, 150)]), Color("8a3a2a"))
		draw_rect(Rect2(frame.position + Vector2(380, 140), Vector2(40, 200)), Color("cfc8b2"))
	draw_rect(frame, Color(0, 0, 0, 0.0), false)
	var credit := "" if own else photo_credit(id)
	if credit != "" and tex != null:
		txt(Vector2(frame.position.x, frame.end.y + 30), credit, 12, Color(G.MUTED, 0.6), HORIZONTAL_ALIGNMENT_LEFT, 640)
	var a := clampf(e - 0.5, 0.0, 1.0)
	txt(Vector2(750, 150), st.get("title", ""), 44, Color(G.TEXT, a))
	draw_line(Vector2(752, 168), Vector2(1000, 168), Color(G.AMBER, a * 0.7), 2.0)
	draw_multiline_string(font, Vector2(750, 210), st.get("lore", ""), HORIZONTAL_ALIGNMENT_LEFT, 470, 19, -1, Color(G.TEXT, clampf(e - 1.0, 0.0, 1.0)))
	draw_multiline_string(font, Vector2(750, 440), st.get("fact", ""), HORIZONTAL_ALIGNMENT_LEFT, 470, 15, -1, Color(G.AMBER, clampf(e - 2.0, 0.0, 1.0) * 0.85))
	if e > 1.5:
		txt(Vector2(0, 680), "Tap to continue" if G.touch_mode else "Press any key to continue", 15, Color(G.MUTED, 0.5 + 0.5 * sin(t * 3.0)), HORIZONTAL_ALIGNMENT_CENTER, 1280)
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)


# ------------------------------------------------------------- bestiary

const PROMO := Rect2(470, 22, 620, 62)
const PROMO_URL := "https://www.viatransilvanica.com"


func best_rect(i: int) -> Rect2:
	return Rect2(60, 120 + i * 30 - best_scroll, 330, 28)


func bestiary_input(event: InputEvent) -> void:
	var n := Bestiary.ENTRIES.size()
	var s := minf(size.x / 1280.0, size.y / 720.0)
	var off := Vector2((size.x - 1280.0 * s) / 2.0, (size.y - 720.0 * s) / 2.0)
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_DOWN, KEY_S:
				best_idx = (best_idx + 1) % n
			KEY_UP, KEY_W:
				best_idx = (best_idx + n - 1) % n
			KEY_ESCAPE, KEY_BACKSPACE, KEY_Q:
				main.state = "title"
	elif (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT) or (event is InputEventScreenTouch and event.pressed):
		var p: Vector2 = (event.position - off) / s
		if Rect2(1110, 30, 140, 46).has_point(p):
			main.state = "title"
			return
		if PROMO.has_point(p):
			OS.shell_open(PROMO_URL)
			return
		for i in n:
			if best_rect(i).has_point(p) and p.y > 100 and p.y < 700:
				best_idx = i
	elif event is InputEventMouseButton and event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_DOWN, MOUSE_BUTTON_WHEEL_UP]:
		best_idx = clampi(best_idx + (1 if event.button_index == MOUSE_BUTTON_WHEEL_DOWN else -1), 0, n - 1)
	elif event is InputEventScreenDrag:
		best_scroll = clampf(best_scroll - event.relative.y / s, 0.0, maxf(0.0, n * 30.0 - 560.0))


func draw_bestiary() -> void:
	var sz := size
	draw_rect(Rect2(Vector2.ZERO, sz), Color("0a0a10"))
	var s := minf(sz.x / 1280.0, sz.y / 720.0)
	draw_set_transform(Vector2((sz.x - 1280.0 * s) / 2.0, (sz.y - 720.0 * s) / 2.0), 0, Vector2(s, s))
	var entries: Array = Bestiary.ENTRIES
	var target := clampf(best_idx * 30.0 - 260.0, 0.0, maxf(0.0, entries.size() * 30.0 - 560.0))
	best_scroll = lerpf(best_scroll, target, 0.2)
	txt(Vector2(60, 70), "BESTIARY", 36, G.TEXT)
	txt(Vector2(60, 96), "of the road to Biertan", 15, G.MUTED.darkened(0.2))
	var last_kind := ""
	for i in entries.size():
		var r := best_rect(i)
		if r.position.y < 100 or r.end.y > 700:
			continue
		var e: Dictionary = entries[i]
		var sel := i == best_idx
		if sel:
			draw_rect(r, Color(G.BLOOD, 0.35))
		var col := G.TEXT if sel else G.MUTED
		txt(Vector2(r.position.x + 12, r.position.y + 20), e["name"], 16, col)
		txt(Vector2(r.end.x - 8, r.position.y + 20), e["kind"], 11, Color(G.AMBER, 0.6), HORIZONTAL_ALIGNMENT_RIGHT, 100)
	var cur: Dictionary = entries[best_idx]
	var panel := Rect2(430, 100, 800, 590)
	draw_rect(panel, Color(0.05, 0.05, 0.08))
	draw_rect(panel, Color(G.AMBER, 0.3), false, 2.0)
	var img: String = cur["img"]
	var tp := "res://assets/sprites/%s.svg" % img
	if img != "" and ResourceLoader.exists(tp):
		var tex := G.tex(tp)
		var ts := tex.get_size()
		var k := minf(220.0 / ts.x, 200.0 / ts.y)
		draw_texture_rect(tex, Rect2(Vector2(460, 130), ts * k), false)
	if cur["kind"] == "Trail":
		draw_rect(Rect2(520, 150, 70, 150), Color("8d877a"))
		draw_colored_polygon(PackedVector2Array([Vector2(520, 150), Vector2(555, 120), Vector2(590, 150)]), Color("8d877a"))
		draw_rect(Rect2(520, 290, 70, 12), Color("5d584f"))
		txt(Vector2(520, 210), "VT", 30, Color("2a3a6a"), HORIZONTAL_ALIGNMENT_CENTER, 70)
		draw_line(Vector2(535, 230), Vector2(575, 230), Color("c9a24a"), 3.0)
	txt(Vector2(700, 160), cur["name"], 30, G.TEXT)
	txt(Vector2(700, 192), cur["ro"], 17, G.AMBER)
	txt(Vector2(700, 220), cur["kind"].to_upper(), 12, G.MUTED.darkened(0.2))
	draw_multiline_string(font, Vector2(460, 370), cur["lore"], HORIZONTAL_ALIGNMENT_LEFT, 740, 17, -1, G.TEXT)
	draw_line(Vector2(460, 600), Vector2(1200, 600), Color(G.AMBER, 0.25), 1.0)
	draw_multiline_string(font, Vector2(460, 628), cur["tip"], HORIZONTAL_ALIGNMENT_LEFT, 640, 15, -1, Color(G.AMBER, 0.9))
	# Via Transilvanica promo
	var pr := PROMO
	draw_rect(pr, Color(0.12, 0.2, 0.12, 0.85))
	draw_rect(pr, Color(0.55, 0.8, 0.45, 0.6 + 0.2 * sin(t * 2.0)), false, 2.0)
	txt(Vector2(pr.position.x + 16, pr.position.y + 26), "Hunt the creatures of Biertan yourself?", 17, G.TEXT)
	txt(Vector2(pr.position.x + 16, pr.position.y + 50), "Plan your hunt on the Via Transilvanica  ·  viatransilvanica.com  >", 14, Color(0.7, 0.9, 0.6))
	draw_rect(Rect2(1110, 30, 140, 46), Color(G.BLOOD, 0.4))
	txt(Vector2(1110, 60), "BACK", 18, G.TEXT, HORIZONTAL_ALIGNMENT_CENTER, 140)
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)


func draw_title_bg() -> void:
	for i in 28:
		var k := i / 27.0
		var c := Color("090b12").lerp(Color("141420"), k / 0.55) if k < 0.55 else Color("141420").lerp(Color("3b1618"), (k - 0.55) / 0.45)
		draw_rect(Rect2(0, i * 30, 1440, 31), c)
	for i in 9:
		draw_circle(Vector2(1110, 310), 360 - i * 38, Color(G.BLOOD, 0.05))
	for i in stars.size():
		var a := 0.45 + 0.25 * sin(t * 1.3 + i * 1.7)
		draw_circle(stars[i], 1.4, Color(0.81, 0.84, 0.88, a))
	draw_circle(Vector2(1110, 310), 118, Color(G.BLOOD, 0.92))
	for c in [[Vector2(1075, 280), 22.0], [Vector2(1142, 352), 16.0], [Vector2(1100, 372), 9.0], [Vector2(1152, 268), 10.0]]:
		draw_circle(c[0], c[1], Color(0, 0, 0, 0.12))
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, 560), Vector2(90, 520), Vector2(180, 548), Vector2(290, 490), Vector2(400, 540), Vector2(520, 500),
		Vector2(640, 545), Vector2(760, 505), Vector2(880, 540), Vector2(1000, 520), Vector2(1120, 548), Vector2(1240, 505),
		Vector2(1360, 535), Vector2(1440, 515), Vector2(1440, 810), Vector2(0, 810),
	]), Color("1a1822"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, 640), Vector2(120, 600), Vector2(240, 640), Vector2(380, 585), Vector2(520, 635), Vector2(660, 600),
		Vector2(800, 640), Vector2(900, 610), Vector2(900, 810), Vector2(0, 810),
	]), Color("131119"))
	# Biertan: an oval hill ringed by walls, the tall steep-roofed hall church,
	# towers with pyramid roofs, vineyard terraces behind, village roofs below
	var far := Color("100f17")
	draw_colored_polygon(PackedVector2Array([Vector2(760, 600), Vector2(880, 470), Vector2(1010, 420), Vector2(1160, 400),
		Vector2(1290, 360), Vector2(1440, 330), Vector2(1440, 640), Vector2(760, 640)]), far)
	for i in 7:
		var y0 := 420.0 + i * 30.0
		draw_line(Vector2(900 + i * 12, y0 + 30), Vector2(1440, y0 - 60 + i * 6), Color(0.2, 0.18, 0.22, 0.35), 2.0)
	var sil := Color("08080d")
	var wallc := Color("0d0c13")
	var c := Vector2(1080, 600)
	# the hill
	var hill := PackedVector2Array()
	for i in 33:
		var ang := PI + PI * i / 32.0
		hill.append(c + Vector2(cos(ang) * 300.0, sin(ang) * 70.0))
	hill.append(Vector2(1380, 660))
	hill.append(Vector2(780, 660))
	draw_colored_polygon(hill, sil)
	# back ring wall
	for i in 32:
		var a0 := PI + PI * i / 32.0
		var p0 := c + Vector2(cos(a0) * 260.0, sin(a0) * 56.0 - 10.0)
		draw_rect(Rect2(p0.x - 9, p0.y - 18, 18, 20), wallc)
	# church: long nave, enormous steep roof, apse with its own roof
	draw_rect(Rect2(985, 470, 190, 80), sil)
	draw_colored_polygon(PackedVector2Array([Vector2(972, 474), Vector2(1080, 318), Vector2(1188, 474)]), sil)
	draw_colored_polygon(PackedVector2Array([Vector2(1040, 548), Vector2(1040, 500), Vector2(1080, 488), Vector2(1120, 500), Vector2(1120, 548)]), sil)
	draw_colored_polygon(PackedVector2Array([Vector2(1032, 504), Vector2(1080, 420), Vector2(1128, 504)]), sil)
	draw_line(Vector2(1080, 318), Vector2(1080, 290), sil, 3.0)
	# towers with pyramid roofs around the ring
	for tw in [[900.0, 520.0, 34.0, 80.0], [1250.0, 528.0, 32.0, 74.0], [1175.0, 470.0, 30.0, 70.0], [960.0, 556.0, 30.0, 60.0], [1310.0, 560.0, 26.0, 52.0]]:
		var tx: float = tw[0]
		var ty: float = tw[1]
		var tw_: float = tw[2]
		var th: float = tw[3]
		draw_rect(Rect2(tx - tw_ / 2.0, ty, tw_, 600.0 - ty), sil)
		draw_colored_polygon(PackedVector2Array([Vector2(tx - tw_ / 2.0 - 5, ty + 2), Vector2(tx, ty - th), Vector2(tx + tw_ / 2.0 + 5, ty + 2)]), sil)
	# front ring wall with arcades
	for i in 33:
		var a1 := PI * i / 32.0
		var p1 := c + Vector2(cos(a1) * 270.0, sin(a1) * 46.0 - 4.0)
		draw_rect(Rect2(p1.x - 10, p1.y - 22, 20, 26), wallc)
		if i % 3 == 1 and i > 3 and i < 29:
			draw_rect(Rect2(p1.x - 4, p1.y - 14, 8, 12), Color(0.16, 0.1, 0.12))
	var fl := 0.8 + 0.2 * sin(t * 4.0)
	for r in [Rect2(1068, 512, 6, 14), Rect2(1088, 512, 6, 14), Rect2(1050, 520, 5, 12), Rect2(1112, 520, 5, 12), Rect2(897, 540, 6, 10), Rect2(1247, 548, 6, 10), Rect2(1172, 490, 6, 10)]:
		draw_rect(r, Color(G.AMBER, fl))
	# village roofs at the foot of the hill
	for hh in [[790.0, 640.0], [840.0, 660.0], [905.0, 668.0], [1250.0, 668.0], [1320.0, 656.0], [1385.0, 640.0], [990.0, 690.0], [1150.0, 692.0]]:
		var hx: float = hh[0]
		var hy: float = hh[1]
		draw_rect(Rect2(hx - 22, hy - 14, 44, 18), Color("0a090f"))
		draw_colored_polygon(PackedVector2Array([Vector2(hx - 26, hy - 12), Vector2(hx, hy - 34), Vector2(hx + 26, hy - 12)]), Color("0a090f"))
		draw_rect(Rect2(hx - 4, hy - 8, 6, 7), Color(G.AMBER, 0.6 * fl))
	draw_colored_polygon(PackedVector2Array([
		Vector2(520, 810), Vector2(520, 730), Vector2(660, 710), Vector2(800, 690), Vector2(905, 700), Vector2(1050, 712),
		Vector2(1200, 706), Vector2(1300, 690), Vector2(1440, 700), Vector2(1440, 810),
	]), Color("0c0b11"))
	var pc := Color("050508")
	for p in [[30, 564, 1.9], [120, 648, 1.3], [210, 536, 2.1], [300, 676, 1.1], [560, 704, 0.9], [640, 690, 1.0], [720, 636, 1.4], [1430, 640, 1.4]]:
		pine(p[0], p[1], p[2], pc)
	draw_rect(Rect2(0, 780, 1440, 30), pc)
