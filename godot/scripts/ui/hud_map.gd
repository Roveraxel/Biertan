## The sheet Lorena drew: the road map (travel from a troiță), the journal on its back, and the bestiary.
## Autoloaded as HudMap; registers itself with the HUD as a page that draws and takes keys while open.
extends Node

const ROUTE := [   # name, level, lat, lon
	["Sighișoara", "sighisoara", 46.2202, 24.7934], ["Viscri", "viscri", 46.0567, 25.0974], ["Criț", "crit", 46.1212, 25.0202],
	["Saschiz", "saschiz", 46.1941, 24.9619], ["Șapartoc", "sapartoc", 46.1721, 24.8564], ["Apold", "apold", 46.1274, 24.8204],
	["Criș", "cris", 46.1436, 24.6938], ["Mălâncrav", "malancrav", 46.1112, 24.6484], ["Richiș", "richisvillage", 46.0979, 24.4818],
	["Biertan", "biertanfort", 46.1363, 24.5210]]
const QUESTS := [   # title, started flag, done flag, token, token flag
	["The Stolen Bacon", "sig_job", "sig_deal", "a bent tin button", "token_tin_button"],
	["The Silent Dogs", "vis_job", "vis_done", "the cellar key", "token_cellar_key"],
	["The Friday Curse", "cr_job", "cr_done", "the ribbon from the shrine", "token_ribbon"],
	["The Missing Children", "sx_job", "sx_done", "a stone from the fortress", "token_fort_stone"],
	["The Three Churches", "sp_job", "sp_done", "Ana's lantern", "token_ana_lantern"],
	["Sâmedru's Fire", "ap_job", "ap_done", "a candle lit from Sâmedru's fire", "token_samedru_candle"],
	["Muma Pădurii and the Feast", "cs_job", "cs_done", "a twig from Muma's oak", "token_muma_twig"],
	["The Morning After", "ml_job", "ml_done", "the church tower key", "token_tower_key"],
	["The Brothers and the Iele", "rc_job", "rc_done", "a ring of dried flowers", "token_flower_ring"],
	["The Locked Door", "bt_arrive", "bt_done", "", ""]]
const INK := Color("3a2616"); const SOFT := Color("5a4028"); const RED := Color("7a160e")
const BELOW := [1, 5, 7, 8, 9]   # villages labelled under their dot

var sel := 0
var at_troita := false
var journal := false
var local := false   # the sheet shows the village the hunter is in, not the road
var open_frame := 0
var best_idx := 0
var best_scroll := 0.0
var entries: Array = []
var _s := 1.0; var _o := Vector2.ZERO

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	entries = JSON.parse_string(FileAccess.get_file_as_string("res://data/bestiary.json"))
	Hud.pages.append(self)

func covers() -> bool: return G.state == G.State.BESTIARY

func _here() -> void:
	sel = 0
	for i in ROUTE.size():
		if ROUTE[i][1] == G.current: sel = i
	G.state = G.State.MAP
	open_frame = Engine.get_process_frames()   # the key that opened the sheet must not also choose a road
	Audio.sfx("blip", -10.0, 0.8)

func open(travel: bool) -> void:
	if G.state != G.State.PLAY: return
	if not G.side_has("map_unlocked"):
		Hud.toast("A troiță at the crossroads. Without a map, you don't know where its roads go." if travel else "You have no map yet.")
		return
	at_troita = travel; journal = false; local = false
	_here()

## The village he is standing in, sketched: streets, houses, the church, who is where.
func open_local() -> void:
	if G.state != G.State.PLAY or not is_instance_valid(G.level): return
	if G.level.blocks.size() < 6:   # a forest or a cellar: the road map instead
		open(false)
		return
	local = true; journal = false; at_troita = false
	_here()

func open_journal() -> void:
	if G.state != G.State.PLAY: return
	journal = true; at_troita = false; local = false
	_here()

func open_bestiary() -> void:
	best_idx = 0
	G.state = G.State.BESTIARY

static func reached(i: int) -> bool: return G.side_has("seen_" + ROUTE[i][1])

# ------------------------------------------------------------------ keys

func key(k: int, next: bool) -> bool:
	match G.state:
		G.State.PLAY:
			if k == KEY_M: open_local()
			elif k == KEY_L: open_journal()
			else: return false
			return true
		G.State.BESTIARY:
			var n := entries.size()
			if k in [KEY_DOWN, KEY_S]: best_idx = (best_idx + 1) % n
			if k in [KEY_UP, KEY_W]: best_idx = (best_idx + n - 1) % n
			if k in [KEY_ESCAPE, KEY_BACKSPACE, KEY_Q]: G.state = G.State.TITLE
			return true
		G.State.MAP:
			if local:
				if k in [KEY_ESCAPE, KEY_Q, KEY_M]: G.state = G.State.PLAY
				elif k == KEY_TAB:
					if G.side_has("map_unlocked"): local = false; Audio.sfx("blip", -12.0, 1.1)
					else: Hud.msg = "You have no road map yet."; Hud.msg_t = 2.0
				elif k == KEY_L: local = false; journal = true
				return true
			if k in [KEY_ESCAPE, KEY_Q] or (k == KEY_M and not journal) or (k == KEY_L and journal):
				G.state = G.State.PLAY
			elif k == KEY_TAB or (k == KEY_L and not journal) or (k == KEY_M and journal):
				if journal and not G.side_has("map_unlocked"): Hud.msg = "You have no map yet."; Hud.msg_t = 2.0
				else:
					journal = not journal
					Audio.sfx("blip", -12.0, 1.1)
			elif k in [KEY_RIGHT, KEY_D, KEY_DOWN, KEY_S]: sel = (sel + 1) % ROUTE.size()
			elif k in [KEY_LEFT, KEY_A, KEY_UP, KEY_W]: sel = (sel + ROUTE.size() - 1) % ROUTE.size()
			elif next and not journal and Engine.get_process_frames() > open_frame: _travel()
			return true
	return false

func click(at: Vector2) -> void:
	if G.state == G.State.BESTIARY:
		for i in entries.size():
			var y := 120.0 + i * 30.0 - best_scroll
			if y >= 100.0 and y + 28.0 <= 700.0 and D(60, y, 330, 28).has_point(at): best_idx = i
	elif G.state == G.State.MAP and not journal and not local:
		for i in ROUTE.size():
			if _pt(i).distance_to(at) < 22.0 * _s:
				if sel == i: _travel()
				sel = i

func _travel() -> void:
	var dest: Array = ROUTE[sel]
	if not at_troita: Hud.msg = "Find a troiță at a crossroads to travel."; Hud.msg_t = 2.5
	elif dest[1] == G.current: G.state = G.State.PLAY
	elif not reached(sel): Hud.msg = "You have not been to %s yet." % dest[0]; Hud.msg_t = 2.5
	else:
		G.state = G.State.PLAY
		Loader.goto_level(dest[1])

# ------------------------------------------------------------------ drawing

func D(x: float, y: float, w: float, h: float) -> Rect2:
	return Rect2(_o.x + x * _s, _o.y + y * _s, w * _s, h * _s)

## Ink on parchment: no outline.
func ink(r: Rect2, s: String, size: float, c: Color, anchor := 0, wrap := false) -> void:
	if s == "": return
	var fs := maxi(6, roundi(size)); var f: Font = Hud.font
	var al: HorizontalAlignment = [HORIZONTAL_ALIGNMENT_LEFT, HORIZONTAL_ALIGNMENT_CENTER, HORIZONTAL_ALIGNMENT_RIGHT][anchor % 3]
	var y := r.position.y + f.get_ascent(fs)
	if anchor >= 3: y = r.position.y + (r.size.y - f.get_height(fs)) / 2.0 + f.get_ascent(fs)
	if wrap: Hud.cv.draw_multiline_string(f, Vector2(r.position.x, y), s, al, r.size.x, fs, -1, c)
	else: Hud.cv.draw_string(f, Vector2(r.position.x, y), s, al, r.size.x, fs, c)

func draw() -> void:
	if G.state != G.State.MAP and G.state != G.State.BESTIARY: return
	var sz: Vector2 = Hud.cv.size
	_s = minf(sz.x / 1280.0, sz.y / 720.0)
	_o = (sz - Vector2(1280, 720) * _s) / 2.0
	if G.state == G.State.BESTIARY:
		_bestiary(sz)
		return
	var s := _s
	Hud.box(Rect2(Vector2.ZERO, sz), Color(0, 0, 0, 0.6))
	var sheet := D(150, 60, 980, 600)
	Hud.box(Rect2(sheet.position + Vector2(8, 10) * s, sheet.size), Color(0, 0, 0, 0.5))
	Hud.box(sheet, Color("c9b286"))
	Hud.box(D(162, 72, 956, 576), Color("d6c298"))
	for i in 9: Hud.disc(sheet.position + Vector2(90 + i * 107, 90 + (i * 53) % 420) * s, (60 + (i * 37) % 50) * s, Color(0.55, 0.42, 0.25, 0.07))
	Hud.frame(D(170, 80, 940, 560), Color("6a4a2a"), 2.0 * s)
	if local: _local()
	elif journal: _journal()
	else: _map()
	if Hud.msg_t > 0.0: ink(D(190, 574, 900, 22), Hud.msg, 15 * s, RED, 1)

func _pt(i: int) -> Vector2:
	var kx := cos(deg_to_rad(46.15))
	var sc := minf(860.0 / ((25.13 - 24.45) * kx), 420.0 / (46.24 - 46.04))
	return _o + Vector2(210.0 + (ROUTE[i][3] - 24.45) * kx * sc, 180.0 + (46.24 - ROUTE[i][2]) * sc) * _s

func _map() -> void:
	var s := _s
	ink(D(190, 92, 600, 34), "The road to Biertan", 26 * s, INK)
	ink(D(190, 124, 600, 20), "drawn for you by Lorena · Terra Saxonum, along the Via Transilvanica", 13 * s, SOFT)
	for i in ROUTE.size() - 1:   # the road, dotted, from village to village
		var a := _pt(i); var b := _pt(i + 1)
		var n := maxi(2, roundi(a.distance_to(b) / (9.0 * s)))
		var walked: bool = reached(i + 1) or (reached(i) and ROUTE[i + 1][1] == G.current)
		for k in range(0, n, 2): Hud.disc(a.lerp(b, (k + 0.5) / n), 1.8 * s, INK if walked else Color(0.35, 0.24, 0.14, 0.45))
	for i in ROUTE.size():
		var p := _pt(i)
		var here: bool = ROUTE[i][1] == G.current; var chosen: bool = i == sel
		if chosen: Hud.disc(p, 15.0 * s, Color(0.7, 0.15, 0.1, 0.35))
		Hud.disc(p, 8.0 * s, INK)
		Hud.disc(p, 6.0 * s, Color("8a2a1a") if reached(i) else Color("d6c298"))
		if ROUTE[i][0] == "Biertan": ink(Rect2(p.x - 14 * s, p.y - 34 * s, 28 * s, 24 * s), "†", 20 * s, INK, 4)
		var below := i in BELOW
		ink(Rect2(p.x - 90 * s, p.y + (10.0 if below else -30.0) * s, 180 * s, 20 * s), ROUTE[i][0], (17 if chosen else 15) * s, RED if chosen else INK, 4)
		if here: ink(Rect2(p.x - 90 * s, p.y + (28.0 if below else -48.0) * s, 180 * s, 18 * s), "you are here", 12 * s, RED, 4)
	var cp := D(1040, 150, 0, 0).position   # the compass
	ink(Rect2(cp.x - 20 * s, cp.y - 34 * s, 40 * s, 20 * s), "N", 16 * s, INK, 4)
	Hud.box(Rect2(cp.x - s, cp.y - 14 * s, 2 * s, 28 * s), INK)
	Hud.box(Rect2(cp.x - 14 * s, cp.y - s, 28 * s, 2 * s), INK)
	var d: Array = ROUTE[sel]
	var what: String = "You are here." if d[1] == G.current else ("You have not been there yet." if not reached(sel) else ("Enter: take the road there." if at_troita else "Stand at a troiță to travel there."))
	ink(D(190, 600, 700, 24), "%s. %s" % [d[0], what], 16 * s, INK)
	ink(D(800, 600, 300, 24), "A D  choose   ·   Tab  journal   ·   M  close", 13 * s, SOFT, 2)

## [word, colour] for how a village's job stands.
func _status(i: int) -> Array:
	var q: Array = QUESTS[i]
	if G.side_has(q[2]): return ["done", Color("2e5a2a")]
	if G.side_has(q[1]): return ["unfinished", Color("8a2a1a")]
	if reached(i): return ["not started", INK]
	return ["—", Color("6a553a")]

func _journal() -> void:
	var s := _s
	ink(D(190, 92, 600, 34), "Journal", 26 * s, INK)
	ink(D(190, 124, 600, 20), "what each village asked of you, and what it gave you to carry to Biertan", 13 * s, SOFT)
	for i in ROUTE.size():   # the left page: the villages, in the order of the road
		var y := 160.0 + i * 40.0
		var chosen := i == sel
		if chosen: Hud.box(D(186, y - 4, 400, 34), Color(0.55, 0.2, 0.1, 0.12))
		var st := _status(i)
		ink(D(198, y, 240, 26), ROUTE[i][0], (18 if chosen else 16) * s, RED if chosen else INK, 3)
		if ROUTE[i][1] == G.current: ink(D(330, y, 120, 26), "you are here", 12 * s, RED, 3)
		ink(D(420, y, 150, 26), st[0], 14 * s, st[1], 5)
		if QUESTS[i][4] != "" and G.side_has(QUESTS[i][4]): Hud.disc(D(580, y + 13, 0, 0).position, 4.5 * s, Color("b07a20"))
	Hud.box(D(618, 160, 2, 400), Color(0.35, 0.24, 0.14, 0.35))
	var r: Array = ROUTE[sel]; var q: Array = QUESTS[sel]   # the right page: the chosen village
	ink(D(650, 160, 440, 34), r[0], 24 * s, INK)
	var body := "You have not been there yet."
	if reached(sel) or G.side_has(q[1]):
		ink(D(650, 198, 440, 26), q[0], 18 * s, RED)
		var st: String = _status(sel)[0]
		if st == "done": body = "Done."
		elif st == "not started": body = "Somebody here needs help. Ask around."
		elif r[1] == G.current and Quests.objective() != "": body = Quests.objective()
		else: body = "Unfinished. Go back to %s to see it through." % r[0]
	ink(D(650, 236, 440, 90), body, 15 * s, INK, 0, true)
	if q[3] != "":
		var got := G.side_has(q[4])
		ink(D(650, 330, 440, 22), "Token: " + q[3] if got else "Token: —", 15 * s, Color("7a5210") if got else SOFT)
	var have := 0; var all := 0
	for e in QUESTS:
		if e[4] != "":
			all += 1
			if G.side_has(e[4]): have += 1
	ink(D(190, 600, 600, 24), "Tokens for the door of Biertan: %d of %d so far." % [have, all], 16 * s, INK)
	ink(D(800, 600, 300, 24), "W S  choose   ·   Tab  map   ·   L  close", 13 * s, SOFT, 2)

func _bestiary(sz: Vector2) -> void:
	var s := _s; var A: Color = Hud.AMBER; var T: Color = Hud.TEXT; var M: Color = Hud.MUTED
	Hud.box(Rect2(Vector2.ZERO, sz), Color("0a0a10"))
	var target := clampf(best_idx * 30.0 - 260.0, 0.0, maxf(0.0, entries.size() * 30.0 - 560.0))
	best_scroll = lerpf(best_scroll, target, 0.2)
	Hud.txt(D(60, 38, 400, 44), "BESTIARY", 36 * s, T)
	Hud.txt(D(60, 82, 400, 20), "of the road to Biertan", 15 * s, M)
	for i in entries.size():
		var y := 120.0 + i * 30.0 - best_scroll
		if y < 100.0 or y + 28.0 > 700.0: continue
		var chosen := i == best_idx
		if chosen: Hud.box(D(60, y, 330, 28), Color(Hud.BLOOD.r, Hud.BLOOD.g, Hud.BLOOD.b, 0.35))
		Hud.txt(D(72, y + 4, 240, 22), entries[i].name, 16 * s, T if chosen else M)
		Hud.txt(D(290, y + 7, 92, 20), entries[i].kind, 11 * s, Color(A.r, A.g, A.b, 0.6), 2)
	var cur: Dictionary = entries[best_idx]
	var panel := D(430, 100, 800, 590)
	Hud.box(panel, Color(0.05, 0.05, 0.08))
	Hud.frame(panel, Color(A.r, A.g, A.b, 0.3), 2.0 * s)
	if cur.img != "" and ResourceLoader.exists("res://sprites/%s.png" % cur.img):
		var tex: Texture2D = load("res://sprites/%s.png" % cur.img)
		var kk := minf(220.0 / tex.get_width(), 200.0 / tex.get_height())
		Hud.cv.draw_texture_rect(tex, D(460, 130, tex.get_width() * kk, tex.get_height() * kk), false)
	if cur.kind == "Trail":   # a Via Transilvanica milestone
		Hud.box(D(520, 150, 70, 150), Color("8d877a"))
		Hud.box(D(520, 290, 70, 12), Color("5d584f"))
		Hud.txt(D(520, 186, 70, 34), "VT", 30 * s, Color("2a3a6a"), 4)
		Hud.box(D(535, 229, 40, 3), Color("c9a24a"))
	Hud.txt(D(700, 124, 520, 40), cur.name, 30 * s, T)
	Hud.txt(D(700, 172, 520, 24), cur.ro, 17 * s, A)
	Hud.txt(D(700, 206, 520, 18), cur.kind.to_upper(), 12 * s, M)
	Hud.txt(D(460, 350, 740, 240), cur.lore, 17 * s, T, 0, true)
	Hud.box(D(460, 600, 740, 1), Color(A.r, A.g, A.b, 0.25))
	Hud.txt(D(460, 610, 640, 70), cur.tip, 15 * s, Color(A.r, A.g, A.b, 0.9), 0, true)
	Hud.txt(D(60, 694, 400, 20), "W S  choose   ·   Esc  back", 12 * s, M)

# ------------------------------------------------------------------ the village sheet

var _lk := 1.0; var _lo := Vector2.ZERO

func _lp(p: Vector2) -> Vector2: return _lo + p * _lk

## The block's four corners on the map (its front edge is b.c, turned by b.angle).
func _corners(b: Dictionary) -> PackedVector2Array:
	var r := deg_to_rad(b.angle)
	var up := Vector2(-sin(r), -cos(r)); var al := Vector2(cos(r), -sin(r))
	var hw: float = b.size.x / 2.0; var dp: float = b.size.y
	var c: Vector2 = b.c
	return PackedVector2Array([_lp(c - al * hw), _lp(c + al * hw), _lp(c + al * hw + up * dp), _lp(c - al * hw + up * dp)])

func _local() -> void:
	var s := _s
	var L: Level = G.level
	ink(D(190, 92, 600, 34), L.title.capitalize() if L.title == L.title.to_upper() else L.title, 26 * s, INK)
	ink(D(190, 124, 700, 20), L.subtitle, 13 * s, SOFT)
	var area := D(190, 150, 900, 440)
	var view := Rect2(Vector2.ZERO, L.size)
	# frame the built part of the place, not the woods round it
	var lo := Vector2(INF, INF); var hi := -lo
	for b in L.blocks:
		if b.style in ["hidden"]: continue
		lo = lo.min(b.c); hi = hi.max(b.c)
	if lo.x < INF: view = Rect2(lo - Vector2(500, 500), hi - lo + Vector2(1000, 1000)).intersection(view)
	_lk = minf(area.size.x / view.size.x, area.size.y / view.size.y)
	_lo = area.position + (area.size - view.size * _lk) / 2.0 - view.position * _lk
	var cv: CanvasItem = Hud.cv
	var road_c := Color(0.55, 0.4, 0.22, 0.55)
	for r in L.roads: _clipped_line(r.pts, area, road_c, maxf(2.0, r.width * _lk))
	for c in L.curtains: _clipped_line(c.pts, area, Color(0.3, 0.2, 0.12, 0.8), maxf(1.0, c.thick * _lk * 0.8))
	for b in L.blocks:
		if b.style in ["hidden", "vine"] or not area.has_point(_lp(b.c)): continue
		var col := Color(0.42, 0.3, 0.18, 0.75)
		match b.style:
			"church", "clocktower": col = Color(0.48, 0.12, 0.08, 0.85)
			"tower": col = Color(0.35, 0.22, 0.12, 0.9)
			"wall", "stone", "ruin", "rock": col = Color(0.3, 0.22, 0.14, 0.6)
		cv.draw_colored_polygon(_corners(b), col)
	# people and places worth walking to
	var t := Time.get_ticks_msec() / 1000.0
	for p in L.props:
		if not is_instance_valid(p) or not area.has_point(_lp(p.pos)): continue
		var q := _lp(p.pos)
		var marked: bool = Events.marker_for(p.id)
		if p.kind == "troita":
			Hud.box(Rect2(q.x - 1.5 * s, q.y - 7 * s, 3 * s, 14 * s), INK); Hud.box(Rect2(q.x - 5 * s, q.y - 3 * s, 10 * s, 3 * s), INK)
		elif p.kind == "npc" and p.display != "":
			Hud.disc(q, 4.0 * s, RED if marked else Color("2e4a5a"))
			ink(Rect2(q.x - 80 * s, q.y + 4 * s, 160 * s, 14 * s), p.display.get_slice(" · ", 0), 11 * s, RED if marked else SOFT, 1)
		elif marked:
			Hud.disc(q, 5.0 * s, RED)
			if p.display != "": ink(Rect2(q.x - 80 * s, q.y + 5 * s, 160 * s, 14 * s), p.display, 11 * s, RED, 1)
	if is_instance_valid(G.player):
		var pp := _lp(G.player.pos)
		Hud.disc(pp, (7.0 + sin(t * 5.0) * 1.5) * s, Color(0.75, 0.12, 0.08, 0.35))
		Hud.disc(pp, 4.5 * s, RED)
		ink(Rect2(pp.x - 60 * s, pp.y - 24 * s, 120 * s, 16 * s), "you", 12 * s, RED, 1)
	ink(D(800, 600, 300, 24), "Tab  road map   ·   L  journal   ·   M  close", 13 * s, SOFT, 2)

## A road or wall on the sheet, drawn only inside the sheet's frame.
func _clipped_line(pts: Array, area: Rect2, col: Color, w: float) -> void:
	for i in pts.size() - 1:
		var a := _lp(pts[i]); var b := _lp(pts[i + 1])
		if not area.has_point(a) and not area.has_point(b): continue
		if not area.has_point(a): a = _clip_to(b, a, area)
		if not area.has_point(b): b = _clip_to(a, b, area)
		Hud.cv.draw_line(a, b, col, w, true)

func _clip_to(inside: Vector2, outside: Vector2, area: Rect2) -> Vector2:
	var lo := 0.0; var hi := 1.0
	for k in 12:
		var m := (lo + hi) / 2.0
		if area.has_point(inside.lerp(outside, m)): lo = m
		else: hi = m
	return inside.lerp(outside, lo)
