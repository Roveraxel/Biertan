class_name Hud
extends Control
## Title screen (ported from the welcome-screen design) and in-game HUD.

const ITEMS := ["Begin the Hunt", "Continue", "Bestiary", "Settings", "Leave the Valley"]
const ENABLED := [true, false, false, false, true]

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
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
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
	# fortified church of Biertan (silhouette)
	var sil := Color("07070b")
	draw_rect(Rect2(860, 548, 380, 64), sil)
	draw_rect(Rect2(850, 520, 30, 80), sil)
	draw_colored_polygon(PackedVector2Array([Vector2(845, 522), Vector2(865, 490), Vector2(885, 522)]), sil)
	draw_rect(Rect2(1225, 525, 28, 80), sil)
	draw_colored_polygon(PackedVector2Array([Vector2(1220, 527), Vector2(1239, 498), Vector2(1258, 527)]), sil)
	draw_rect(Rect2(905, 516, 290, 70), sil)
	draw_rect(Rect2(893, 462, 42, 120), sil)
	draw_colored_polygon(PackedVector2Array([Vector2(886, 464), Vector2(914, 410), Vector2(942, 464)]), sil)
	draw_rect(Rect2(1167, 474, 42, 110), sil)
	draw_colored_polygon(PackedVector2Array([Vector2(1160, 476), Vector2(1188, 424), Vector2(1216, 476)]), sil)
	draw_rect(Rect2(985, 446, 108, 80), sil)
	draw_colored_polygon(PackedVector2Array([Vector2(972, 448), Vector2(1039, 386), Vector2(1106, 448)]), sil)
	draw_rect(Rect2(1086, 372, 46, 154), sil)
	draw_rect(Rect2(1082, 366, 54, 8), sil)
	draw_colored_polygon(PackedVector2Array([Vector2(1080, 368), Vector2(1109, 296), Vector2(1138, 368)]), sil)
	var fl := 0.8 + 0.2 * sin(t * 4.0)
	for r in [Rect2(1002, 468, 6, 16), Rect2(1030, 468, 6, 16), Rect2(1058, 468, 6, 16), Rect2(1105, 396, 7, 16), Rect2(1105, 440, 7, 12), Rect2(910, 486, 6, 14), Rect2(1184, 498, 6, 14), Rect2(960, 530, 4, 10), Rect2(1140, 532, 4, 10)]:
		draw_rect(r, Color(G.AMBER, fl))
	draw_colored_polygon(PackedVector2Array([
		Vector2(520, 810), Vector2(520, 720), Vector2(660, 690), Vector2(800, 640), Vector2(905, 604), Vector2(1050, 574),
		Vector2(1200, 602), Vector2(1300, 632), Vector2(1440, 668), Vector2(1440, 810),
	]), Color("0c0b11"))
	var pc := Color("050508")
	for p in [[30, 564, 1.9], [120, 648, 1.3], [210, 536, 2.1], [300, 676, 1.1], [560, 704, 0.9], [640, 690, 1.0], [720, 636, 1.4], [1250, 662, 1.2], [1330, 578, 1.8], [1400, 494, 2.4]]:
		pine(p[0], p[1], p[2], pc)
	draw_rect(Rect2(0, 780, 1440, 30), pc)
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
	txt(Vector2(1344, 790), "WASD move · Mouse attack · Space dodge · E interact · Q tincture", 15, G.MUTED.darkened(0.35), HORIZONTAL_ALIGNMENT_RIGHT, 700)
	if msg_t > 0.0:
		txt(Vector2(96, 760), msg, 20, Color(G.AMBER, minf(1.0, msg_t)))
	draw_set_transform_matrix(Transform2D.IDENTITY)


func draw_hud() -> void:
	var p: Player = main.player
	var sz := size
	if p.hurt_flash > 0.0:
		draw_rect(Rect2(Vector2.ZERO, sz), Color(0.7, 0.05, 0.05, p.hurt_flash * 0.8))
	bar(Rect2(24, 24, 250, 18), p.hp / p.max_hp, Color("b3372f"))
	txt(Vector2(30, 38), "HEALTH  %d / %d" % [int(p.hp), int(p.max_hp)], 13, G.TEXT)
	if main.current == "forest":
		bar(Rect2(24, 54, 250, 8), G.dusk, Color("5a6aa8").lerp(Color("e8a94a"), 1.0 - G.dusk))
		txt(Vector2(284, 62), "DUSK" if G.dusk < 0.85 else "NIGHT FALLS", 12, G.TEXT if G.dusk < 0.85 else G.BLOOD)
	elif main.current == "hub":
		txt(Vector2(24, 62), "SAFE HAVEN", 12, G.AMBER)
	txt(Vector2(24, 90), "Coins %d      Tinctures %d  (Q)" % [p.coins, p.potions], 14, G.AMBER)
	var q := ""
	match main.quest:
		0: q = "Speak with Frau Anna at the inn."
		1: q = "Quest: Where the Sheep Went. Slay the beast of the Wolf Forest."
		2: q = "Return to Frau Anna with the Silver Thread."
		3: q = "Level 1 complete. Richiș awaits."
	txt(Vector2(24, 112), q, 14, G.MUTED)
	for i in toasts.size():
		var a: float = minf(1.0, toasts[i][1])
		txt(Vector2(sz.x - 24, 40 + i * 26), toasts[i][0], 15, Color(G.TEXT, a), HORIZONTAL_ALIGNMENT_RIGHT, 760)
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
		txt(Vector2(0, 52), "THE VARCOLAC", 18, G.TEXT, HORIZONTAL_ALIGNMENT_CENTER, sz.x)
		if bs.phase >= 2 and not bs.vulnerable():
			txt(Vector2(0, 98), "Shrouded in shadow. Strike it only near a lit brazier.", 14, G.AMBER, HORIZONTAL_ALIGNMENT_CENTER, sz.x)
	if main.state == "play" and main.hover != null:
		txt(Vector2(0, sz.y - 70), main.hover.prompt_text(), 20, G.AMBER, HORIZONTAL_ALIGNMENT_CENTER, sz.x)
	if main.state == "dialogue":
		var r := Rect2(150, sz.y - 210, sz.x - 300, 170)
		draw_rect(r, Color(0.03, 0.03, 0.05, 0.92))
		draw_rect(r, G.AMBER.darkened(0.3), false, 2.0)
		txt(Vector2(r.position.x + 24, r.position.y + 34), main.dlg_speaker, 20, G.AMBER)
		draw_multiline_string(font, Vector2(r.position.x + 24, r.position.y + 68), main.dlg_lines[main.dlg_idx], HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 48, 19, -1, G.TEXT)
		txt(Vector2(r.end.x - 24, r.end.y - 14), "E / click  >", 14, G.MUTED, HORIZONTAL_ALIGNMENT_RIGHT, 200)
	if main.state == "dead":
		draw_rect(Rect2(Vector2.ZERO, sz), Color(0.1, 0, 0, 0.6))
		txt(Vector2(0, sz.y / 2.0), "YOU HAVE FALLEN", 56, G.BLOOD, HORIZONTAL_ALIGNMENT_CENTER, sz.x)
		txt(Vector2(0, sz.y / 2.0 + 44), "Press E to rise again in Saschiz", 20, G.MUTED, HORIZONTAL_ALIGNMENT_CENTER, sz.x)
	if play_time < 25.0 and main.state != "dead":
		txt(Vector2(24, sz.y - 24), "WASD move · Mouse aim + click attack · Space dodge · E interact · Q tincture", 14, Color(G.MUTED, clampf(25.0 - play_time, 0.0, 1.0)))
