import sys
R='/home/claude/bg/'
def ed(p, pairs):
    s=open(R+p).read()
    for a,b in pairs:
        assert a in s, (p, a[:60])
        s=s.replace(a,b,1)
    open(R+p,'w').write(s)

# --- fades can't stall a level change; loading line
ed('scripts/ui/game_hud.gd', [
("var _fade_tw: Tween\n","var _fade_tw: Tween\nvar _loading: Label\n"),
("	top.add_child(_fade)\n","""	top.add_child(_fade)
	_loading = Label.new()
	_loading.set_anchors_preset(Control.PRESET_FULL_RECT)
	_loading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_loading.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_loading.add_theme_font_size_override("font_size", 26)
	_loading.add_theme_color_override("font_color", Color(0.85, 0.74, 0.5))
	_loading.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_loading.visible = false
	top.add_child(_loading)
"""),
("""	_fade_tw.tween_property(_fade, "color:a", alpha, duration)
	await _fade_tw.finished
""","""	_fade_tw.tween_property(_fade, "color:a", alpha, duration)
	# wait on a timer, not on the tween: a tween killed by a later fade never finishes, and whoever was
	# waiting on it (a level change holding G.transitioning) would hang for good
	await get_tree().create_timer(duration).timeout
"""),
("func set_black(alpha: float) -> void:","""## A line on the black screen while a level is built: big towns take seconds in a browser.
func loading(text: String) -> void:
	_loading.text = text
	_loading.visible = text != ""

func set_black(alpha: float) -> void:"""),
])
ed('scripts/core/level_loader.gd', [
("""	unload()
	await get_tree().process_frame   # let the old level go
	enter(level_id, at)
""","""	unload()
	Hud.loading("On the road...")
	await get_tree().process_frame   # let the old level go
	await get_tree().process_frame   # and let the line reach the screen before the build blocks it
	enter(level_id, at)
	Hud.loading("")
"""),
])
# --- dash keys; ?then= for transition tests
ed('scripts/core/main.gd', [
("func _ready() -> void:\n","func _ready() -> void:\n	_bind_keys()\n"),
("		if at != null: _hold_at(at)\n","""		if at != null: _hold_at(at)
		if OS.has_feature("web"):   # ?then=<id> walks on to a second level after a few seconds: tests a real transition
			var nx = JavaScriptBridge.eval("new URLSearchParams(window.location.search).get('then') || ''")
			if nx is String and nx != "":
				await get_tree().create_timer(4.0).timeout
				G.state = G.State.PLAY
				Loader.goto_level(nx)
"""),
])
s=open(R+'scripts/core/main.gd').read()
s+='''

## Dash on Space, Shift and the right mouse button; keys also match by position, so a held modifier or a
## German/Romanian layout never blocks one.
func _bind_keys() -> void:
	var shift := InputEventKey.new(); shift.keycode = KEY_SHIFT
	InputMap.action_add_event("dodge", shift)
	var rmb := InputEventMouseButton.new(); rmb.button_index = MOUSE_BUTTON_RIGHT
	InputMap.action_add_event("dodge", rmb)
	for a in InputMap.get_actions():
		if str(a).begins_with("ui_"): continue
		for e in InputMap.action_get_events(a):
			if e is InputEventKey and e.physical_keycode == 0 and e.keycode != KEY_SHIFT:
				var p := InputEventKey.new(); p.physical_keycode = e.keycode
				InputMap.action_add_event(a, p)
'''
open(R+'scripts/core/main.gd','w').write(s)

# --- pathfinding, prop lookup
ed('scripts/core/level_base.gd', [
("func is_free(at: Vector2, radius: float) -> bool:","func is_free(at: Vector2, radius: float, ignore: Node = null) -> bool:"),
("		if is_instance_valid(p) and at.distance_to(p.pos) < 12.0 + radius: return false","		if is_instance_valid(p) and p != ignore and p.visible and at.distance_to(p.pos) < 12.0 + radius: return false"),
("## Nothing solid within `radius` of the spot","""func prop_by_id(pid: String) -> Prop:
	for p in props:
		if is_instance_valid(p) and p.id == pid: return p
	return null

## A walkable route round walls, houses and trees (A* on a 20 px grid over the box spanning both ends).
## Returns the waypoints after `from`, ending at `to`; the straight line if there is no route.
func find_path(from: Vector2, to: Vector2, radius := 8.0, ignore: Node = null, margin := 360.0) -> Array[Vector2]:
	const CELL := 20.0
	var box := Rect2(from, Vector2.ZERO).expand(to).grow(margin)
	var g := AStarGrid2D.new()
	g.region = Rect2i(0, 0, int(box.size.x / CELL) + 1, int(box.size.y / CELL) + 1)
	g.cell_size = Vector2.ONE
	g.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	g.update()
	# stamp each obstacle on the cells it covers (no per-cell scan over every block)
	var stamp := func(c: Vector2, half: Vector2, test: Callable) -> void:
		var lo := Vector2i(((c - half - Vector2.ONE * radius - box.position) / CELL).floor())
		var hi := Vector2i(((c + half + Vector2.ONE * radius - box.position) / CELL).ceil())
		for x in range(maxi(lo.x, 0), mini(hi.x, g.region.size.x - 1) + 1):
			for y in range(maxi(lo.y, 0), mini(hi.y, g.region.size.y - 1) + 1):
				if test.call(box.position + Vector2(x, y) * CELL): g.set_point_solid(Vector2i(x, y))
	for b in blocks:
		if not b.solid: continue
		var r := deg_to_rad(b.angle)
		var up := Vector2(-sin(r), -cos(r)); var rt := Vector2(cos(r), -sin(r))
		var mid: Vector2 = b.c + up * b.size.y / 2.0
		var ext: float = (b.size.x + b.size.y) / 2.0
		if not box.grow(ext).has_point(mid): continue
		stamp.call(mid, Vector2(ext, ext), func(q: Vector2) -> bool:
			var rel: Vector2 = q - mid
			return absf(rel.dot(rt)) < b.size.x / 2.0 + radius and absf(rel.dot(up)) < b.size.y / 2.0 + radius)
	for t in trees:
		var tr: float = 11.0 * t.sc
		if box.grow(tr).has_point(t.p): stamp.call(t.p, Vector2(tr, tr), func(q: Vector2) -> bool: return q.distance_to(t.p) < tr + radius)
	for d in decors:
		if is_instance_valid(d) and d.radius > 0.0 and box.grow(d.radius).has_point(d.pos):
			stamp.call(d.pos, Vector2(d.radius, d.radius), func(q: Vector2) -> bool: return q.distance_to(d.pos) < d.radius + radius)
	for p in props:
		if is_instance_valid(p) and p != ignore and p.visible and box.has_point(p.pos):
			stamp.call(p.pos, Vector2(12, 12), func(q: Vector2) -> bool: return q.distance_to(p.pos) < 12.0 + radius)
	for w in walls:
		stamp.call(w.c, w.size / 2.0, func(q: Vector2) -> bool: return Rect2(w.c - w.size / 2.0, w.size).grow(radius).has_point(q))
	var a := Vector2i(((from - box.position) / CELL).round()); var b := Vector2i(((to - box.position) / CELL).round())
	for e in [a, b]:   # someone standing beside a stall must still be able to step away from it
		for dx in range(-1, 2):
			for dy in range(-1, 2):
				if g.is_in_boundsv(e + Vector2i(dx, dy)): g.set_point_solid(e + Vector2i(dx, dy), false)
	var out: Array[Vector2] = []
	var ids := g.get_id_path(a, b, true)
	if ids.size() < 2: out.append(to); return out
	var prev_d := Vector2i.ZERO
	for i in range(1, ids.size()):   # keep only the corners
		var dd: Vector2i = ids[i] - ids[i - 1]
		if i > 1 and dd != prev_d: out.append(box.position + Vector2(ids[i - 1]) * CELL)
		prev_d = dd
	out.append(to)
	return out

## Nothing solid within `radius` of the spot"""),
])

# --- villagers walk and follow
ed('scripts/actors/prop.gd', [
("var facing := Vector2(0, 1)   # where a villager looks when the hunter is not near\n","""var facing := Vector2(0, 1)   # where a villager looks when the hunter is not near
var walk_path: Array[Vector2] = []   # waypoints a villager is walking through
var walk_speed := 85.0
var walk_done: Callable
var following := false               # trots after the hunter (a freed child)
"""),
("""func _process(dt: float) -> void:
	t += dt
""","""## Walk through the points (from Level.find_path), then call `done`.
func walk(points: Array, speed := 85.0, done := Callable()) -> void:
	walk_path.clear()
	for q in points: walk_path.append(q)
	walk_speed = speed; walk_done = done

func follow(on: bool) -> void:
	following = on
	set_solid(not on and kind in SOLID)   # a follower must never wedge the hunter in a doorway

func _move(dt: float) -> void:
	if not walk_path.is_empty():
		var to: Vector2 = walk_path[0] - pos
		var st := walk_speed * dt
		if to.length() <= st:
			pos = walk_path.pop_front()
			if walk_path.is_empty():
				if to != Vector2.ZERO: facing = to.normalized()
				if walk_done.is_valid(): walk_done.call()
		else:
			pos += to.normalized() * st
		return
	if not following or not is_instance_valid(G.player) or not is_instance_valid(G.level): return
	var to: Vector2 = G.player.pos - pos
	var d := to.length()
	if d > 700.0:   # lost him (a door, a fall): catch up out of sight
		pos = G.player.pos - G.player.facing * 40.0
		return
	if d < 46.0: return
	var sp: float = clampf(d * 2.2, 60.0, 230.0) * dt
	var dir := to / d
	for a in [0.0, 0.6, -0.6, 1.2, -1.2, 1.8, -1.8]:
		var step: Vector2 = dir.rotated(a) * sp
		if G.level.is_free(pos + step, 7.0, self):
			pos += step
			return

func _process(dt: float) -> void:
	t += dt
	_move(dt)
"""),
])
ed('scripts/levels/sighisoara.gd', [
("	butcher.pos = butcher_at_tower\n","	butcher.walk(find_path(butcher.pos, butcher_at_tower, 8.0, butcher), 70.0)\n"),
])
# --- Matei follows you out and runs home
ed('scripts/quests/vis_quest.gd', [
("""				], func(): mark("vis_matei"); Hud.toast("Matei is free."))""","""				], func():
					mark("vis_matei"); Hud.toast("Matei is free. He is right behind you.")
					var m = G.level.prop_by_id("matei")
					if m: m.follow(true))"""),
('"Matei is home. His mother has not let go of him since.",','"(Matei is off down the street before anyone can stop him, shouting for his mother. Every dog in the village runs with him.)",'),
("""			mark("vis_done"); mark("map_unlocked"); mark("token_cellar_key")
""","""			mark("vis_done"); mark("map_unlocked"); mark("token_cellar_key")
			var m = G.level.prop_by_id("matei")
			if m:
				m.follow(false)
				var home: Vector2 = G.level.church_lane() if G.level.has_method("church_lane") else m.pos + Vector2(-500, 300)
				m.walk(G.level.find_path(m.pos, home, 8.0, m), 150.0, func(): m.retire())
"""),
])
ed('scripts/levels/crypt.gd', [
("""	add_prop("npc", "matei", "Matei", Vector2(1500, 1200), "E   Speak with Matei", Color("6a5a40"))
""","""	var matei := add_prop("npc", "matei", "Matei", Vector2(1500, 1200), "E   Speak with Matei", Color("6a5a40"))
	if G.side_has("vis_matei") and not G.side_has("vis_done"): matei.follow(true)
"""),
])
ed('scripts/levels/viscri.gd', [
("func _quest_things() -> void:","""var _lane := Vector2.ZERO
## Where Matei runs home to: down the main street.
func church_lane() -> Vector2: return _lane

func _quest_things() -> void:"""),
("	var street := func(t: float, side: float) -> Vector2: return sa.lerp(sb, t) + nw * side\n","	var street := func(t: float, side: float) -> Vector2: return sa.lerp(sb, t) + nw * side\n	_lane = street.call(0.25, 0.0)\n"),
("	add_torch(lorena + Vector2(0, -40), 220.0, Color(1, 0.6, 0.3), 0.7)\n","""	add_torch(lorena + Vector2(0, -40), 220.0, Color(1, 0.6, 0.3), 0.7)
	if G.side_has("vis_matei") and not done:   # the boy came up out of the cellar with you
		var m := add_prop("npc", "matei", "Matei", _free(spawn + Vector2(-40, 30), 30.0), "E   Speak with Matei", Color("6a5a40"))
		m.follow(true)
"""),
])
print("p1 ok")
