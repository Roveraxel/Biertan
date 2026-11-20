## Title screen, in-game HUD, dialogue box, death screen, story cards and ending, drawn immediate-mode.
## Title art uses a 1440x810 design space, story cards a centred 1280x720 one, the HUD plain screen pixels
## scaled by height/720. Autoloaded as Hud.
extends CanvasLayer

const ITEMS := ["Begin the Hunt", "Continue", "Bestiary", "Leave the Valley"]
const TEXT := Color("e8e2d2")
const MUTED := Color("9a9486")
const AMBER := Color("ffb347")
const BLOOD := Color("b31b22")
const UL := 0; const UC := 1; const UR := 2; const ML := 3; const MC := 4; const MR := 5

class Canvas extends Control:
	var hud
	func _draw() -> void: hud.draw()

var cv: Canvas
var font: Font
var toasts: Array = []        # [text, seconds left]
var banner_text := ""
var banner_sub := ""
var banner_t := 0.0
var t := 0.0
var msg := ""
var msg_t := 0.0
var play_time := 0.0
var menu_idx := 0
var has_save := false
var show_pointer := true
var last_state := -1
var photos := {}
var credits := {}
var pages: Array = []         # extra screens (map, journal, bestiary) that draw and take keys while open
var _fade: ColorRect
var _fade_tw: Tween
var _loading: Label
var _soft: Texture2D
var _moon: Texture2D
var _grad: Texture2D
var _menu_rects: Array[Rect2] = []

func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	font = ThemeDB.fallback_font
	cv = Canvas.new()
	cv.hud = self
	cv.set_anchors_preset(Control.PRESET_FULL_RECT)
	cv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(cv)
	var top := CanvasLayer.new()
	top.layer = 20
	add_child(top)
	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 0)
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(_fade)
	_loading = Label.new()
	_loading.set_anchors_preset(Control.PRESET_FULL_RECT)
	_loading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_loading.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_loading.add_theme_font_size_override("font_size", 26)
	_loading.add_theme_color_override("font_color", Color(0.85, 0.74, 0.5))
	_loading.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_loading.visible = false
	top.add_child(_loading)
	_soft = _soft_blob()
	_moon = _blood_moon()
	var g := Gradient.new()
	g.colors = PackedColorArray([Color(0.02, 0.02, 0.03, 0.88), Color(0.02, 0.02, 0.03, 0)])
	var gt := GradientTexture1D.new()
	gt.gradient = g
	_grad = gt
	var cj = JSON.parse_string(FileAccess.get_file_as_string("res://photos/credits.json")) if FileAccess.file_exists("res://photos/credits.json") else null
	if cj is Dictionary:
		for k in cj: credits[k] = "Photo: %s · %s · Wikimedia Commons" % [cj[k].get("artist", "?"), cj[k].get("license", "?")]
	has_save = G.has_save()
	if has_save: menu_idx = 1

static func _soft_blob() -> Texture2D:
	var n := 128
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	for y in n:
		for x in n:
			var r := clampf(Vector2((x + 0.5) / n * 2.0 - 1.0, (y + 0.5) / n * 2.0 - 1.0).length(), 0.0, 1.0)
			var a := 1.0 - r
			a = a * a * (3.0 - 2.0 * a)
			img.set_pixel(x, y, Color(1, 1, 1, a * a))
	return ImageTexture.create_from_image(img)

static func _blood_moon() -> Texture2D:
	var n := 192
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	var fn := FastNoiseLite.new()
	fn.seed = 1521
	fn.frequency = 0.018
	fn.fractal_octaves = 2
	for y in n:
		for x in n:
			var p := Vector2((x + 0.5) / n * 2.0 - 1.0, (y + 0.5) / n * 2.0 - 1.0)
			var r := p.length()
			if r >= 1.0:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
				continue
			var edge := smoothstep(1.0, 0.93, r)
			var limb := clampf(1.0 - r * r * 0.22, 0.78, 1.0)
			var m := fn.get_noise_2d(float(x), float(y)) * 0.5 + 0.5
			var maria := lerpf(0.87, 1.0, smoothstep(0.35, 0.68, m))
			var shade := limb * maria
			# luminous pale-rose / copper harvest moon, subtle enough to sit in the twilight sky
			var col := Color(0.92 * shade, 0.72 * shade, 0.66 * shade, edge * 0.58)
			img.set_pixel(x, y, col)
	return ImageTexture.create_from_image(img)

# ------------------------------------------------------------------ what the game calls

func toast(s: String) -> void:
	toasts.append([s, 4.5])
	if toasts.size() > 5: toasts.pop_front()

func banner(s: String, sub := "") -> void:
	banner_text = s; banner_sub = sub; banner_t = 3.6

## Fade the whole screen to black (1) or back (0); await it.
func fade_to(alpha: float, duration: float) -> void:
	if _fade_tw: _fade_tw.kill()
	if G.instant:
		_fade.color.a = alpha
		return
	_fade_tw = create_tween()
	_fade_tw.tween_property(_fade, "color:a", alpha, duration)
	# wait on a timer, not on the tween: a tween killed by a later fade never finishes, and whoever was
	# waiting on it (a level change holding G.transitioning) would hang for good
	await get_tree().create_timer(duration).timeout

## A line on the black screen while a level is built: big towns take seconds in a browser.
func loading(text: String) -> void:
	_loading.text = text
	_loading.visible = text != ""

func set_black(alpha: float) -> void:
	if _fade_tw: _fade_tw.kill()
	_fade.color.a = alpha

func open_map(travel: bool) -> void:
	if has_node("/root/HudMap"): get_node("/root/HudMap").open(travel)
	else: toast("The map is not drawn yet.")

# ------------------------------------------------------------------ timers and input

func _process(dt: float) -> void:
	t += dt
	msg_t = maxf(0.0, msg_t - dt)
	banner_t = maxf(0.0, banner_t - dt)
	for i in range(toasts.size() - 1, -1, -1):
		toasts[i][1] -= dt
		if toasts[i][1] <= 0.0: toasts.remove_at(i)
	if G.state != last_state:
		if G.state == G.State.TITLE:
			has_save = G.has_save()
			toasts.clear()
			banner_t = 0.0
		last_state = G.state
	if G.state != G.State.TITLE and G.state != G.State.BESTIARY: play_time += dt
	cv.queue_redraw()

func _input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
		if G.state == G.State.TITLE:
			for i in _menu_rects.size():
				if _menu_rects[i].has_point(ev.position):
					menu_idx = i
					activate(i)
		elif G.state == G.State.STORY and G.story_t > 1.5: G.close_story()
		elif G.state == G.State.ENDING and G.ending_t > 4.0: G.leave_ending()
		for p in pages: p.click(ev.position)
		return
	if ev is InputEventMouseMotion and G.state == G.State.TITLE:
		for i in _menu_rects.size():
			if _menu_rects[i].has_point(ev.position): menu_idx = i
		return
	if not (ev is InputEventKey) or not ev.pressed or ev.echo: return
	var k: int = ev.keycode
	var next := k in [KEY_ENTER, KEY_KP_ENTER, KEY_E, KEY_SPACE]
	var down := k in [KEY_DOWN, KEY_S]; var up := k in [KEY_UP, KEY_W]
	for p in pages:
		if p.key(k, next): return
	match G.state:
		G.State.TITLE:
			if down: menu_idx = (menu_idx + 1) % ITEMS.size()
			if up: menu_idx = (menu_idx + ITEMS.size() - 1) % ITEMS.size()
			if next: activate(menu_idx)
		G.State.PLAY:
			if k == KEY_T:
				show_pointer = not show_pointer
				toast("Quest arrow on  (T)" if show_pointer else "Quest arrow off: follow the objective, or press T")
		G.State.DEAD:
			if next: G.respawn()
		G.State.DIALOGUE:
			if Engine.get_process_frames() <= G.dlg_frame: return
			if G.choosing_now():
				var nc := G.dlg_choices.size()
				if down: G.dlg_sel = (G.dlg_sel + 1) % nc
				if up: G.dlg_sel = (G.dlg_sel + nc - 1) % nc
				if k >= KEY_1 and k <= KEY_9 and k - KEY_1 < nc: G.dlg_sel = k - KEY_1
				if k in [KEY_ENTER, KEY_KP_ENTER, KEY_E]: G.advance_dialogue()
			elif next: G.advance_dialogue()
		G.State.STORY:
			if G.story_t > 1.5: G.close_story()
		G.State.ENDING:
			if G.ending_t > 4.0: G.leave_ending()

func activate(i: int) -> void:
	var enabled := has_save if i == 1 else true
	if not enabled:
		msg = "%s is not yet part of this tale." % ITEMS[i]; msg_t = 2.5
		return
	match i:
		0: play_time = 0.0; G.start_game()
		1: play_time = 0.0; G.continue_game()
		2:
			if has_node("/root/HudMap"): get_node("/root/HudMap").open_bestiary()
			else: msg = "The bestiary is still being written."; msg_t = 2.5
		3:
			if OS.has_feature("web"): msg = "Close the tab to leave the valley."; msg_t = 2.5
			else: get_tree().quit()

# ------------------------------------------------------------------ drawing helpers

## Text with a dark outline inside a rect.
func txt(r: Rect2, s: String, size: float, c: Color, anchor := UL, wrap := false) -> void:
	if s == "" or c.a <= 0.0: return
	var fs := maxi(6, roundi(size))
	var h_align: HorizontalAlignment = [HORIZONTAL_ALIGNMENT_LEFT, HORIZONTAL_ALIGNMENT_CENTER, HORIZONTAL_ALIGNMENT_RIGHT][anchor % 3]
	var asc := font.get_ascent(fs)
	var y := r.position.y + asc
	if anchor >= 3: y = r.position.y + (r.size.y - font.get_height(fs)) / 2.0 + asc
	var at := Vector2(r.position.x, y)
	var o := maxi(2, roundi(size / 12.0))
	var oc := Color(0, 0, 0, c.a * 0.85)
	if wrap:
		cv.draw_multiline_string_outline(font, at, s, h_align, r.size.x, fs, -1, o, oc)
		cv.draw_multiline_string(font, at, s, h_align, r.size.x, fs, -1, c)
	else:
		cv.draw_string_outline(font, at, s, h_align, r.size.x, fs, o, oc)
		cv.draw_string(font, at, s, h_align, r.size.x, fs, c)

func box(r: Rect2, c: Color) -> void:
	cv.draw_rect(r, c)

func frame(r: Rect2, c: Color, w: float) -> void:
	cv.draw_rect(r.grow(-w / 2.0), c, false, w)

func disc(c: Vector2, r: float, col: Color) -> void:
	cv.draw_circle(c, r, col)

func soft(c: Vector2, rx: float, ry: float, col: Color) -> void:
	cv.draw_texture_rect(_soft, Rect2(c.x - rx, c.y - ry, rx * 2.0, ry * 2.0), false, col)

func bar(r: Rect2, frac: float, col: Color, k: float) -> void:
	var g := 2.0 * k
	box(r.grow(g), Color(0, 0, 0, 0.75))
	box(r, Color(0.12, 0.1, 0.1, 0.9))
	box(Rect2(r.position, Vector2(r.size.x * clampf(frac, 0.0, 1.0), r.size.y)), col)
	frame(r.grow(g), Color(AMBER.r * 0.55, AMBER.g * 0.55, AMBER.b * 0.55, 1.0), 1.5 * k)

func photo(photo_id: String) -> Texture2D:
	if not photos.has(photo_id): photos[photo_id] = Mats.tex("res://photos/%s.jpg" % photo_id)
	return photos[photo_id]

## Draw a texture filling a rect, cropped to it (or fitted inside it).
func image(tex: Texture2D, r: Rect2, crop := true, mod := Color.WHITE) -> void:
	var ts := tex.get_size()
	var ta := ts.x / ts.y; var ra := r.size.x / r.size.y
	if crop:
		var src := Rect2(Vector2.ZERO, ts)
		if ta > ra: src = Rect2((ts.x - ts.y * ra) / 2.0, 0, ts.y * ra, ts.y)
		else: src = Rect2(0, (ts.y - ts.x / ra) / 2.0, ts.x, ts.x / ra)
		cv.draw_texture_rect_region(tex, r, src, mod)
	else:
		var dst := r
		if ta > ra: dst = Rect2(r.position.x, r.position.y + (r.size.y - r.size.x / ta) / 2.0, r.size.x, r.size.x / ta)
		else: dst = Rect2(r.position.x + (r.size.x - r.size.y * ta) / 2.0, r.position.y, r.size.y * ta, r.size.y)
		cv.draw_texture_rect(tex, dst, false, mod)

# ------------------------------------------------------------------ draw

func draw() -> void:
	for p in pages:
		if p.covers():
			p.draw()
			return
	match G.state:
		G.State.TITLE: _draw_title()
		G.State.STORY: _draw_story()
		G.State.ENDING: _draw_ending(G.ending_t)
		_:
			if is_instance_valid(G.player): _draw_hud(G.player)
	for p in pages: p.draw()

func _draw_title() -> void:
	var sz := cv.size; var W := sz.x; var H := sz.y; var s := W / 1440.0
	var oy := (H - 810.0 * s) / 2.0   # letterbox when the window is taller than 16:9
	box(Rect2(0, 0, W, H), Color(0.02, 0.02, 0.03))
	var D := func(x: float, y: float, w: float, h: float) -> Rect2: return Rect2(x * s, oy + y * s, w * s, h * s)
	# the photo fills the whole window (cropped) with a slow breathing drift
	var tp := photo("title_biertan")
	var pa := tp.get_size().x / tp.get_size().y if tp else 16.0 / 9.0
	var drift := 1.018 + 0.015 * sin(t * 0.14)
	var cam_r := Rect2((1.0 - drift) * 0.5 * W, (1.0 - drift) * 0.5 * H, W * drift, H * drift)
	if tp: image(tp, cam_r, true, Color(0.95, 0.92, 0.96))
	# where the cropped photo actually lands, so the moon and lit windows stay on the photo in any window shape
	var tw := cam_r.size.x if W / H > pa else cam_r.size.y * pa
	var th := tw / pa; var tx := cam_r.position.x + (cam_r.size.x - tw) / 2.0; var ty := cam_r.position.y + (cam_r.size.y - th) / 2.0; var ps := tw / 1440.0
	var PV := func(x: float, y: float) -> Vector2: return Vector2(tx + x * ps, ty + y * ps)
	# warm dusk rim behind the fortified church towers
	soft(PV.call(1030, 520), 420 * ps, 260 * ps, Color(AMBER.r, AMBER.g * 0.55, BLOOD.b * 0.4, 0.14))
	# luminous harvest/blood moon behind thin night clouds
	var mc: Vector2 = PV.call(1150, 150)
	soft(mc, 260 * ps, 260 * ps, Color(0.75, 0.35, 0.28, 0.18))
	var mr := 50.0 * ps
	cv.draw_texture_rect(_moon, Rect2(mc.x - mr, mc.y - mr, mr * 2.0, mr * 2.0), false)
	# faint, diffused candlelight inside the tall nave lancet windows (no hard rectangles)
	var flp := 0.14 + 0.04 * sin(t * 3.2)
	for wp in [Vector2(778, 650), Vector2(832, 650)]:
		soft(PV.call(wp.x, wp.y), 14 * ps, 28 * ps, Color(AMBER.r, AMBER.g * 0.8, AMBER.b * 0.5, flp))
	# drifting mist
	for m in 2:
		var my := 520.0 if m == 0 else 600.0
		var mx := 720.0 + sin(t * (0.16 if m == 0 else 0.12) + (0.0 if m == 0 else 1.7)) * 80.0
		soft(PV.call(mx, my + 120.0), 820.0 * ps, 140.0 * ps, Color(0.59, 0.63, 0.69, 0.10))
	# rising ember motes across the valley
	for e in 14:
		var seed_e := float(e) * 1.731
		var phase := fmod(t * (0.045 + 0.015 * sin(seed_e * 3.1)) + seed_e * 0.29, 1.0)
		var ex := fmod(seed_e * 0.37, 1.0) * W + sin(t * 0.9 + seed_e * 5.0) * 28.0 * s
		var ey := H * (1.05 - phase * 1.1)
		var ea := sin(phase * PI) * (0.35 + 0.25 * sin(t * 3.5 + seed_e))
		var ec := AMBER if e % 3 != 0 else BLOOD.lightened(0.2)
		soft(Vector2(ex, ey), 7.0 * s, 7.0 * s, Color(ec.r, ec.g, ec.b, ea * 0.45))
		disc(Vector2(ex, ey), (1.6 if e % 2 == 0 else 1.1) * s, Color(ec.r, ec.g, ec.b, ea))
	# atmospheric left & bottom vignette for readable typography
	cv.draw_texture_rect(_grad, Rect2(0, 0, 820 * s, H), false)
	box(Rect2(0, H - 90 * s, W, 90 * s), Color(0.02, 0.02, 0.03, 0.42))
	txt(D.call(96, 224, 900, 30), "Anno MDXXI · Siebenbürgen", 20 * s, AMBER.lerp(MUTED, 0.45))
	txt(D.call(88, 248, 1000, 150), "Biertan", 132 * s, TEXT)
	txt(D.call(96, 394, 900, 40), "A Hunter’s Ballad of Transylvania", 28 * s, MUTED)
	# hairline rule + crimson diamond ornament above the menu
	var rule_y := oy + 442.0 * s
	box(Rect2(96 * s, rule_y, 380 * s, maxf(1.0, 1.5 * s)), Color(AMBER.r, AMBER.g, AMBER.b, 0.32))
	var oc := Vector2(96 * s, rule_y + 0.5 * s); var od := 4.5 * s
	cv.draw_colored_polygon(PackedVector2Array([oc + Vector2(0, -od), oc + Vector2(od, 0), oc + Vector2(0, od), oc + Vector2(-od, 0)]), BLOOD)
	_menu_rects.clear()
	for i in ITEMS.size():
		var r: Rect2 = D.call(88, 466 + i * 58, 460, 50)
		_menu_rects.append(r)
		var enabled := has_save if i == 1 else true
		var sel := i == menu_idx
		var col := TEXT if sel else MUTED
		if not enabled: col.a = 0.45
		if sel:
			box(Rect2(r.position.x, r.position.y + 4 * s, r.size.x, r.size.y - 8 * s), Color(BLOOD.r * 0.42, BLOOD.g * 0.15, BLOOD.b * 0.15, 0.32))
			box(Rect2(r.position.x, r.position.y + 4 * s, 3.0 * s, r.size.y - 8 * s), BLOOD)
			var c := Vector2(r.position.x + 20 * s, r.position.y + r.size.y / 2.0)
			var d := 7.8 * s
			cv.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -d), c + Vector2(d, 0), c + Vector2(0, d), c + Vector2(-d, 0)]), BLOOD)
		txt(Rect2(r.position.x + (42 + (6.0 if sel else 0.0)) * s, r.position.y + 5 * s, r.size.x, r.size.y), ITEMS[i], 32 * s, col)
	txt(D.call(96, 770, 900, 26), "Salt for the dead. Silver for what walks.", 18 * s, MUTED.darkened(0.3))
	txt(D.call(644, 772, 700, 24), "WASD move · Mouse attack · Space dodge · E interact · Q tincture · T quest arrow", 15 * s, MUTED.darkened(0.35), UR)
	if msg_t > 0.0: txt(D.call(96, 738, 900, 28), msg, 20 * s, Color(AMBER.r, AMBER.g, AMBER.b, minf(1.0, msg_t)))

func _draw_hud(p: Player) -> void:
	var W := cv.size.x; var H := cv.size.y; var k := H / 720.0
	var R := func(x: float, y: float, w: float, h: float) -> Rect2: return Rect2(x * k, y * k, w * k, h * k)
	var full := Rect2(0, 0, W, H)
	if p.hurt_flash > 0.0: box(full, Color(0.7, 0.05, 0.05, p.hurt_flash * 0.8))
	if G.current == "hollow" and p.madness > p.max_hp:
		var mk := (p.madness - p.max_hp) / p.max_hp
		box(full, Color(0.3, 0.1, 0.4, maxf(0.0, 0.12 * mk + 0.05 * mk * sin(t * 5.0))))
	if p.vamp_t > 0.0: box(full, Color(0.4, 0, 0.05, 0.12))
	bar(R.call(24, 24, 250, 18), p.hp / p.max_hp, Color("b3372f"), k)
	txt(R.call(30, 24, 250, 18), "HEALTH  %d / %d" % [int(p.hp), int(p.max_hp)], 13 * k, TEXT, ML)
	bar(R.call(24, 45, 250, 6), p.stamina / p.max_stamina, Color("8a7038") if p.sprint_exhausted else Color("d8a84a"), k)
	var sub: Rect2 = R.call(24, 56, 250, 8)
	var sub_label: Rect2 = R.call(284, 52, 400, 16)
	if G.current in ["forest", "hills", "vineyard"]:
		bar(sub, G.dusk, Color("5a6aa8").lerp(Color("e8a94a"), 1.0 - G.dusk), k)
		txt(sub_label, "DUSK" if G.dusk < 0.85 else ("NIGHT FALLS" if G.dusk < 1.0 else "MIDNIGHT"), 12 * k, TEXT if G.dusk < 0.85 else BLOOD, ML)
	elif G.current == "hollow":
		var cap := p.max_hp * 2.0
		bar(sub, p.madness / cap, Color("7a4aa8"), k)
		txt(sub_label, "MADNESS" if p.madness < cap * 0.75 else "THE WOOD WHISPERS", 12 * k, Color("b08ad8"), ML)
	elif G.current == "church":
		if p.vamp_t > 0.0:
			bar(sub, p.vamp_t / 18.0, Color("8a0a14"), k)
			txt(sub_label, "VAMPIRE  (tinctures burn)", 12 * k, BLOOD, ML)
		else:
			bar(sub, p.blood / 5.0, Color("8a0a14"), k)
			txt(sub_label, "BLOOD CURSE", 12 * k, Color("d07070"), ML)
	elif Mats.is_village(G.current):
		txt(R.call(24, 53, 300, 16), "SAFE HAVEN", 12 * k, AMBER, ML)
	if p.haste_t > 0.0: txt(R.call(284, 24, 200, 18), "SWIFT %ds" % int(p.haste_t), 12 * k, Color(0.7, 0.9, 0.6), ML)
	var inv := "Coins %d      Tinctures %d  (Q)" % [p.coins, p.potions]
	if p.salt_unlocked: inv += "      Salt %d  (R)" % p.salt
	txt(R.call(24, 76, 800, 20), inv, 14 * k, AMBER)
	# the current objective, readable: a larger line on a dark strip
	var ql := _short_objective(Quests.objective())
	if ql != "":
		var qw := font.get_string_size(ql, HORIZONTAL_ALIGNMENT_LEFT, -1, roundi(18 * k)).x + 28.0 * k
		box(Rect2(14 * k, 96 * k, qw, 30 * k), Color(0.02, 0.02, 0.03, 0.62))
		box(Rect2(14 * k, 96 * k, 3 * k, 30 * k), Color(AMBER.r, AMBER.g, AMBER.b, 0.9))
		txt(R.call(26, 100, 1200, 24), ql, 18 * k, TEXT)
	if show_pointer and G.state == G.State.PLAY:
		var tg := Quests.target()
		if not tg.is_empty(): _draw_pointer(p, tg[0], tg[1], k)
	for i in toasts.size():
		txt(Rect2(W - 784 * k, (28 + i * 26) * k, 760 * k, 24 * k), toasts[i][0], 15 * k, Color(TEXT.r, TEXT.g, TEXT.b, minf(1.0, toasts[i][1])), UR)
	if banner_t > 0.0:
		var a := minf(1.0, banner_t) * minf(1.0, (3.6 - banner_t) * 3.0)
		txt(Rect2(0, 112 * k, W, 50 * k), banner_text, 44 * k, Color(TEXT.r, TEXT.g, TEXT.b, a), MC)
		txt(Rect2(0, 164 * k, W, 30 * k), banner_sub, 18 * k, Color(MUTED.r, MUTED.g, MUTED.b, a), MC)
	var bs = G.boss
	if bs != null and is_instance_valid(bs) and bs.max_hp > 0.0:
		var r := Rect2(W / 2.0 - 280 * k, 60 * k, 560 * k, 14 * k)
		bar(r, bs.hp / bs.max_hp, Color("b3372f"), k)
		box(Rect2(r.position.x + r.size.x * 0.33 - k, r.position.y, 2 * k, r.size.y), Color.BLACK)
		box(Rect2(r.position.x + r.size.x * 0.66 - k, r.position.y, 2 * k, r.size.y), Color.BLACK)
		txt(Rect2(0, 34 * k, W, 22 * k), bs.hud_name(), 18 * k, TEXT, MC)
		var hint: String = bs.hud_hint()
		if hint != "": txt(Rect2(0, 82 * k, W, 22 * k), hint, 14 * k, AMBER, MC)
	if G.state == G.State.PLAY:
		var near := Interact.nearest(p.pos)
		if near: txt(Rect2(0, H - 92 * k, W, 30 * k), near.prompt_text(), 20 * k, AMBER, MC)
	if G.state == G.State.DIALOGUE and G.dlg_idx < G.dlg_lines.size():
		var r := Rect2(150 * k, H - 210 * k, W - 300 * k, 170 * k)
		box(r, Color(0.03, 0.03, 0.05, 0.92))
		frame(r, Color(AMBER.r * 0.7, AMBER.g * 0.7, AMBER.b * 0.7, 1.0), 2.0 * k)
		txt(Rect2(r.position.x + 24 * k, r.position.y + 14 * k, r.size.x - 48 * k, 26 * k), G.dlg_speaker, 20 * k, AMBER)
		txt(Rect2(r.position.x + 24 * k, r.position.y + 48 * k, r.size.x - 48 * k, r.size.y - 70 * k), G.dlg_lines[G.dlg_idx], 19 * k, TEXT, UL, true)
		if G.choosing_now():
			var n := G.dlg_choices.size()
			for i in n:
				var cr := Rect2(r.position.x + 24 * k, r.position.y - (n - i) * 30 * k - 8 * k, r.size.x - 48 * k, 28 * k)
				box(cr, Color(0.04, 0.04, 0.06, 0.92 if i == G.dlg_sel else 0.75))
				if i == G.dlg_sel: frame(cr, AMBER, 1.5 * k)
				txt(Rect2(cr.position.x + 12 * k, cr.position.y + 4 * k, cr.size.x - 24 * k, 22 * k), "%d.  %s" % [i + 1, G.dlg_choices[i]], 17 * k, AMBER if i == G.dlg_sel else TEXT)
			txt(Rect2(r.end.x - 324 * k, r.end.y - 28 * k, 300 * k, 20 * k), "↑ ↓ choose   E / Enter  answer", 14 * k, MUTED, MR)
		else:
			txt(Rect2(r.end.x - 224 * k, r.end.y - 28 * k, 200 * k, 20 * k), "%d/%d   E / Enter  >" % [G.dlg_idx + 1, G.dlg_lines.size()], 14 * k, MUTED, MR)
	if G.state == G.State.DEAD:
		box(full, Color(0.1, 0, 0, 0.6))
		txt(Rect2(0, H / 2.0 - 50 * k, W, 64 * k), "YOU HAVE FALLEN", 56 * k, BLOOD, MC)
		txt(Rect2(0, H / 2.0 + 20 * k, W, 30 * k), "Press E to rise again in " + G.home_name(), 20 * k, MUTED, MC)
	if play_time < 25.0 and G.state != G.State.DEAD:
		txt(Rect2(24 * k, H - 40 * k, W, 20 * k), "WASD move · Mouse aim + click attack · Space dodge · E interact · Q tincture · L journal · M map", 14 * k, Color(MUTED.r, MUTED.g, MUTED.b, clampf(25.0 - play_time, 0.0, 1.0)))

## The quest pointer: an arrow beside the hunter turning toward where the job sends him next, with the
## place's name and how far it is. T turns it off for players who would rather find their way.
func _draw_pointer(p: Player, at: Vector2, label: String, k: float) -> void:
	var d := at - p.pos
	var metres := d.length() * Fx.S
	if metres < 2.5 or Fx.cam == null: return
	var c := cv.size / 2.0
	var world := Fx.to3(p.pos, 0.7)
	if not Fx.cam.is_position_behind(world): c = Fx.cam.unproject_position(world)
	var dir := d.normalized()
	var pos := c + dir * 92.0 * k
	var side := dir.orthogonal()
	for o in [[Vector2(1.5, 1.5) * k, Color(0, 0, 0, 0.6)], [Vector2.ZERO, AMBER]]:
		var q: Vector2 = pos + o[0]
		cv.draw_colored_polygon(PackedVector2Array([q + dir * 13.0 * k, q - dir * 13.0 * k + side * 11.0 * k, q - dir * 13.0 * k - side * 11.0 * k]), o[1])
	txt(Rect2(pos.x - 160 * k, pos.y + (18.0 if dir.y > 0.3 else -38.0) * k, 320 * k, 20 * k), "%s · %d m" % [label, roundi(metres)], 13 * k, AMBER, MC)

func _draw_story() -> void:
	var W := cv.size.x; var H := cv.size.y
	box(Rect2(0, 0, W, H), Color(0.02, 0.02, 0.03))
	if not G.STORIES.has(G.story_id): return
	var card: Dictionary = G.STORIES[G.story_id].duplicate()
	var spoken: Array = Narration.LINES.get(G.story_id, [])
	if not spoken.is_empty():
		card.lore = spoken[0]
	var s := minf(W / 1280.0, H / 720.0); var ox := (W - 1280.0 * s) / 2.0; var oy := (H - 720.0 * s) / 2.0
	var D := func(x: float, y: float, w: float, h: float) -> Rect2: return Rect2(ox + x * s, oy + y * s, w * s, h * s)
	var e := maxf(G.story_t, 0.0)
	var own: bool = G.story_id == "biertan"
	var tex := photo("biertan_story" if own else G.story_id)
	var again := Color(MUTED.r, MUTED.g, MUTED.b, 0.5 + 0.5 * sin(t * 3.0))
	var panels: Array = card.get("panels", [])
	if not panels.is_empty():
		var pi := mini(G.story_panel, panels.size() - 1)
		var pn: Dictionary = panels[pi]
		var pc := card.duplicate()
		pc.lore = spoken[pi] if pi < spoken.size() else pn.text
		pc.fact = "%d / %d" % [G.story_panel + 1, panels.size()]
		var pa := _story_art(pn.art)
		if pa:
			_draw_folk_story(pc, pa, D, s, e)
			return
	var art := _story_art(G.story_id)
	if art:
		_draw_folk_story(card, art, D, s, e)
		return
	if tex == null:
		# a card with no photograph (the prologue): the words alone, in the middle of the page
		var ea := clampf(e - 0.3, 0.0, 1.0)
		txt(D.call(240, 150, 800, 60), card.title, 46 * s, Color(TEXT.r, TEXT.g, TEXT.b, ea), MC)
		box(D.call(540, 222, 200, 2), Color(AMBER.r, AMBER.g, AMBER.b, ea * 0.7))
		txt(D.call(240, 250, 800, 220), card.lore, 20 * s, Color(TEXT.r, TEXT.g, TEXT.b, clampf(e - 0.8, 0.0, 1.0)), UC, true)
		txt(D.call(290, 480, 700, 140), card.fact, 15 * s, Color(AMBER.r, AMBER.g, AMBER.b, clampf(e - 1.6, 0.0, 1.0) * 0.85), UC, true)
		if e > 1.5: txt(D.call(0, 666, 1280, 24), "Press any key to continue", 15 * s, again, MC)
		return
	var fr: Rect2 = D.call(60, 90, 640, 480)
	box(D.call(52, 82, 656, 496), Color("3a2e20"))
	var mod := Color(1, 1, 1, clampf(e, 0.0, 1.0))
	if tex.get_size().x / tex.get_size().y < 1.1:
		box(fr, Color("14110e"))
		image(tex, fr, false, mod)
	else: image(tex, fr, true, mod)
	if not own and credits.has(G.story_id): txt(D.call(60, 584, 640, 20), credits[G.story_id], 12 * s, Color(MUTED.r, MUTED.g, MUTED.b, 0.6))
	var a := clampf(e - 0.5, 0.0, 1.0)
	txt(D.call(750, 100, 480, 56), card.title, 44 * s, Color(TEXT.r, TEXT.g, TEXT.b, a))
	box(D.call(752, 166, 248, 2), Color(AMBER.r, AMBER.g, AMBER.b, a * 0.7))
	txt(D.call(750, 190, 470, 230), card.lore, 19 * s, Color(TEXT.r, TEXT.g, TEXT.b, clampf(e - 1.0, 0.0, 1.0)), UL, true)
	txt(D.call(750, 424, 470, 150), card.fact, 15 * s, Color(AMBER.r, AMBER.g, AMBER.b, clampf(e - 2.0, 0.0, 1.0) * 0.85), UL, true)
	if e > 1.5: txt(D.call(0, 666, 1280, 24), "Press any key to continue", 15 * s, again, MC)

# ------------------------------------------------------------------ folk story cards
# Ink, folk red and parchment, after Romanian folk illustration: an embroidery band top and bottom, a red sun (or a
# dark moon at night) behind the drawing, the title in spaced red capitals.
const INK := Color("1b1714")
const FOLK_RED := Color("b01e23")
const PARCH := Color("e9dfc9")
var _arts := {}
var _parch: Texture2D

func _story_art(card_id: String) -> Texture2D:
	if not _arts.has(card_id):
		var path := "res://sprites/Story/%s.png" % card_id
		_arts[card_id] = load(path) if ResourceLoader.exists(path) else null
	return _arts[card_id]

## Old paper: warm cream with soft blotches and a darker edge, made once.
func _parchment() -> Texture2D:
	if _parch: return _parch
	var img := Image.create(320, 180, false, Image.FORMAT_RGB8)
	var n := FastNoiseLite.new(); n.frequency = 0.035; n.fractal_octaves = 4; n.seed = 1521
	var fine := FastNoiseLite.new(); fine.frequency = 0.5; fine.seed = 77
	for y in 180:
		for x in 320:
			var v := n.get_noise_2d(x, y) * 0.06 + fine.get_noise_2d(x, y) * 0.025
			var d := Vector2((x - 160.0) / 160.0, (y - 90.0) / 90.0).length()
			v -= maxf(0.0, d - 0.7) * 0.22   # the edges have browned
			img.set_pixel(x, y, Color(PARCH.r + v, PARCH.g + v * 1.05, PARCH.b + v * 1.2))
	_parch = ImageTexture.create_from_image(img)
	return _parch

## One row of embroidery: red diamonds with an ink heart, small crosses between, ink rules either side.
func _embroidery(y: float, x0: float, x1: float, h: float, a: float) -> void:
	var red := Color(FOLK_RED.r, FOLK_RED.g, FOLK_RED.b, a); var ink := Color(INK.r, INK.g, INK.b, a)
	cv.draw_rect(Rect2(x0, y, x1 - x0, h * 0.08), ink)
	cv.draw_rect(Rect2(x0, y + h * 0.92, x1 - x0, h * 0.08), ink)
	var cell := h * 1.1
	var x := x0 + cell / 2.0
	var i := 0
	while x < x1:
		var c := Vector2(x, y + h / 2.0)
		if i % 2 == 0:
			var r := h * 0.36
			cv.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -r), c + Vector2(r, 0), c + Vector2(0, r), c + Vector2(-r, 0)]), red)
			var q := r * 0.42
			cv.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -q), c + Vector2(q, 0), c + Vector2(0, q), c + Vector2(-q, 0)]), ink)
			for k in 4:   # the little hooks at the points, as stitched
				var dir := Vector2.from_angle(k * PI / 2.0)
				cv.draw_rect(Rect2(c + dir * r * 1.2 - Vector2.ONE * h * 0.05, Vector2.ONE * h * 0.1), ink)
		else:
			var w := h * 0.07; var l := h * 0.22
			cv.draw_rect(Rect2(c.x - w / 2.0, c.y - l, w, l * 2.0), red)
			cv.draw_rect(Rect2(c.x - l, c.y - w / 2.0, l * 2.0, w), red)
		x += cell / 2.0 + h * 0.25
		i += 1

func _draw_folk_story(card: Dictionary, art: Texture2D, D: Callable, s: float, e: float) -> void:
	var W := cv.size.x; var H := cv.size.y
	cv.draw_texture_rect(_parchment(), Rect2(0, 0, W, H), false)
	var a := clampf(e * 1.5, 0.0, 1.0)
	_embroidery(D.call(0, 22, 0, 0).position.y, 0, W, 34 * s, a)
	_embroidery(D.call(0, 664, 0, 0).position.y, 0, W, 34 * s, a)
	# the sun rises behind the drawing (a dark crescent moon for the night cards)
	var night: bool = card.get("night", false)
	var sc: Vector2 = D.call(360, 300, 0, 0).position - Vector2(0, 16.0 * s * clampf(e / 20.0, 0.0, 1.0))   # the sun keeps rising
	var rr := 250.0 * s * clampf(e * 1.2, 0.0, 1.0)
	if night:
		cv.draw_circle(sc, rr, Color(INK.r, INK.g, INK.b, 0.85 * a))
		cv.draw_circle(sc + Vector2(rr * 0.35, -rr * 0.12), rr * 0.92, Color(PARCH.r, PARCH.g, PARCH.b, a))
	else:
		cv.draw_circle(sc, rr, Color(FOLK_RED.r, FOLK_RED.g, FOLK_RED.b, 0.92 * a))
	# the drawing, pixel for pixel, standing on the lower band
	var sz := art.get_size()
	# slow camera movement over the drawing (a few percent of zoom and a drift up), so the card breathes
	var k := minf(590.0 * s / sz.y, 620.0 * s / sz.x) * (1.0 + 0.04 * clampf(e / 20.0, 0.0, 1.0))
	var drift := -14.0 * s * clampf(e / 20.0, 0.0, 1.0)
	var pan := 0.0
	if card.get("night", false):   # the night scenes move more: a slow push in and a drift across, like a camera
		k *= 1.0 + 0.1 * clampf(e / 12.0, 0.0, 1.0)
		pan = sin(e * 0.25) * 22.0 * s
	var dr := Rect2(sc.x - sz.x * k / 2.0 + pan, D.call(0, 652, 0, 0).position.y - sz.y * k + drift, sz.x * k, sz.y * k)
	if card.get("sway", false):   # drunk: the picture rocks like the deck of a boat
		var piv := dr.get_center()
		cv.draw_set_transform(piv, sin(t * 0.9) * 0.04, Vector2.ONE * (1.0 + sin(t * 1.3) * 0.015))
		cv.draw_texture_rect(art, Rect2(dr.position - piv, dr.size), false, Color(1, 1, 1, clampf(e - 0.3, 0.0, 1.0)))
		cv.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	else:
		cv.draw_texture_rect(art, dr, false, Color(1, 1, 1, clampf(e - 0.3, 0.0, 1.0)))
	# the words, in ink, the title in spaced red capitals
	var ta := clampf(e - 0.6, 0.0, 1.0)
	var spaced := " ".join(PackedStringArray(Array(card.title.split("")))).replace("    ", "   ") + "  ·"
	var tfs := 40.0 * s
	while tfs > 14.0 * s and font.get_string_size(spaced, HORIZONTAL_ALIGNMENT_LEFT, -1, int(tfs)).x > 560.0 * s: tfs -= 2.0 * s   # long act titles shrink to fit
	txt(D.call(700, 96, 560, 60), spaced, tfs, Color(FOLK_RED.r, FOLK_RED.g, FOLK_RED.b, ta))
	txt(D.call(702, 160, 520, 220), card.lore, 19 * s, Color(INK.r, INK.g, INK.b, clampf(e - 1.0, 0.0, 1.0)), UL, true)
	cv.draw_rect(D.call(702, 432, 60, 2), Color(FOLK_RED.r, FOLK_RED.g, FOLK_RED.b, clampf(e - 1.8, 0.0, 1.0)))
	txt(D.call(702, 446, 520, 160), card.fact, 15 * s, Color(0.42, 0.13, 0.12, clampf(e - 2.0, 0.0, 1.0)), UL, true)
	if e > 1.5: txt(D.call(700, 612, 540, 24), "Press any key to continue", 14 * s, Color(INK.r, INK.g, INK.b, 0.35 + 0.3 * sin(t * 3.0)))

const ENDING := [
	["THE BELLS OF SIGHIȘOARA", 52, 0], ["", 18, 1],
	["The Clock Tower rang first, and every bell on the road answered it, as far as Biertan.", 20, 1],
	["In Viscri the dogs barked. In Criț, Floarea danced at her wedding with healed hands.", 20, 1],
	["In Saschiz the children slept in their own beds. In Șapartoc, Ana's lantern went out at last.", 20, 1],
	["In Apold the dead complained about the colivă. In Criș nobody touched the rye.", 20, 1],
	["In Mălâncrav a pair of trousers is still talked about. In Richiș, two old brothers play the nai.", 20, 1],
	["In Biertan nineteen bolts hang open, and in the marriage prison a man is learning to spin.", 20, 1],
	["And every year, on the Thursday before Easter, the snowdrops come up along the road in a line.", 20, 1],
	["", 18, 1], ["A wedding for the dead. Bread for the stranger. Every pot on its face on a Tuesday.", 22, 2], ["", 18, 1],
	["BIERTAN · A Hunter's Ballad of Transylvania", 16, 3],
	["Maps © OpenStreetMap contributors (ODbL) · Textures: Poly Haven (CC0) · Sounds: Kenney (CC0)", 14, 4],
	["Music by Kevin MacLeod (incompetech.com), licensed under CC BY 4.0", 14, 4],
]

func _draw_ending(e: float) -> void:
	var W := cv.size.x; var H := cv.size.y; var k := H / 720.0
	box(Rect2(0, 0, W, H), Color(0.02, 0.02, 0.03))
	var tones := [TEXT, MUTED, AMBER, MUTED.darkened(0.3), MUTED.darkened(0.4)]
	var total := 0.0
	for l in ENDING: total += (l[1] + 18) * k
	var y := maxf(H * 0.06, (H - 70 * k - total) * 0.5)
	for i in ENDING.size():
		var l: Array = ENDING[i]
		var c: Color = tones[l[2]]
		c.a = clampf(e - i * 0.6, 0.0, 1.0)
		txt(Rect2(0, y, W, (l[1] + 14) * k), l[0], l[1] * k, c, MC)
		y += (l[1] + 18) * k
	if e > 4.0: txt(Rect2(0, H - 56 * k, W, 30 * k), "Press any key to return", 16 * k, Color(MUTED.r, MUTED.g, MUTED.b, 0.5 + 0.5 * sin(t * 3.0)), MC)


## The objective strip shows the first sentence only, keeping any count like 3/5; the journal has the rest.
func _short_objective(q: String) -> String:
	var out := q
	var i := out.find(". ")
	if i > 0: out = out.substr(0, i + 1)
	if out.length() > 70:
		var cut := out.substr(0, 66)
		out = cut.substr(0, cut.rfind(" ")) + "..."
	var re := RegEx.create_from_string("\\(?\\d+ ?/ ?\\d+\\)?")
	var m := re.search(q)
	if m and not out.contains(m.get_string()): out += "  " + m.get_string()
	return out
