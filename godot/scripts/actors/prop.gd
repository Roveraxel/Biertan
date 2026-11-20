## An interactable thing in the world: a villager, coin sack, torn fleece, signpost, lost ewe, haiduc treasure,
## wayside cross, or an unseen spot where a clue or a task waits. What using one does lives in Events.
class_name Prop
extends Node3D

const SOLID := ["npc", "sign", "sack", "ewe", "cross", "greenman", "bones"]
## Villagers who wear a face already drawn: id -> [figure (or fallbacks), height in metres]
const FIGURES := {
	"road_vlad": ["npc_vlad", 1.25], "road_magda": ["npc_magda", 1.2], "bvlad": ["npc_vlad", 1.25], "bmagda": ["npc_magda", 1.2],
	"baron": ["vampire", 1.3], "servant": ["thrall", 1.2], "bsexton": ["npc_sexton", 1.25], "market1": ["npc_anna", 1.2],
	"market2": ["npc_hans", 1.25], "solomonar": ["npc_hermit", 1.35], "finpriest": ["npc_priest", 1.25], "vybaba": ["npc_anna", 1.15],
	"vyw1": ["npc_sofia", 1.2], "vyw2": ["npc_katharina", 1.2], "vyw3": ["npc_ileana", 1.2], "market3": ["npc_andreas", 1.25],
	"azorel": ["npc_azorel", 1.1], "distiller": ["npc_vasile", 1.25], "millwife": ["npc_katharina", 1.2],
	"hamkeeper": ["npc_veta", 1.15], "storeman": ["npc_konrad", 1.25], "fortkid": ["npc_child", 0.95],
	"vsmith": ["npc_horia", 1.3], "child": ["npc_child", 1.0], "matei": ["npc_matei", 1.05],
	"kid1": ["npc_child", 0.95], "kid2": ["npc_ioana", 0.95], "kid3": ["npc_child", 0.95],
	"ilinca": ["npc_ilinca", 1.2], "ana": ["npc_ana_ghost", 1.2], "dumitru": ["npc_dumitru", 1.25],
	"granny": ["npc_veta", 1.15], "baker": ["npc_anna", 1.2], "costache": ["npc_costache", 1.25],
	"pubcostache": ["npc_costache", 1.25], "pubghost": ["shade", 1.25], "traveller": ["npc_priest", 1.12],
	"giant": ["uriasul", 2.6], "watchsexton": ["npc_sexton", 1.25], "hatthief": ["spiridus", 0.8], "mob": ["npc_konrad", 1.25], "vbutcher": ["npc_hans", 1.25],
	"goosewife": ["npc_katharina", 1.2], "caretaker": ["npc_andreas", 1.25], "vineri": ["npc_sfanta_vineri", 1.3],
	"gerda": ["npc_sofia", 1.18], "rada": ["npc_rozalia", 1.12], "baba_ana": ["npc_veta", 1.15], "baba_safta": [["npc_safta", "npc_rozalia"], 1.12], "baba_veta": ["npc_anna", 1.15],
	"mother": [["npc_floarea_mother", "npc_sofia"], 1.18], "captain": ["spiridus_cap", 0.95], "oakman": ["npc_vasile", 1.25],
	"henwoman": ["npc_floarea", 1.2], "goose1": ["npc_hans", 1.25], "goose2": ["npc_horia", 1.25],
	"farmer": ["npc_konrad", 1.25], "towerkid": ["npc_child", 1.0], "muma": ["npc_muma", 1.3],
	"feaster": ["npc_sofia", 1.2], "ieledancer": ["iele", 1.12], "spouse1": ["npc_hans", 1.25],
	"spouse2": ["npc_katharina", 1.2], "ally_fox": ["ally_fox", 0.9], "ally_deer": ["ally_deer", 1.4],
	"ally_owl": ["ally_owl", 0.8], "mbear": ["snare_bear", 2.1], "msexton": ["npc_sexton", 1.25],
	"orchard": [["npc_orchard", "npc_horia"], 1.25], "mbaker": ["npc_anna", 1.2], "mchild": ["npc_child", 1.0],
	"kidsa": ["npc_child", 1.0], "kidsb": ["npc_child", 1.0], "mgranny": ["npc_veta", 1.15], "brawl1": ["npc_konrad", 1.25],
}

var kind := "npc"
var id := ""
var display := ""
var prompt := ""
var col := Color("a05030")
var used := false
var regrow := 0.0
var facing := Vector2(0, 1)   # where a villager looks when the hunter is not near
var walk_path: Array[Vector2] = []   # waypoints a villager is walking through
var walk_speed := 85.0
var walk_done: Callable
var following := false               # trots after the hunter (a freed child)
var _chase: Array[Vector2] = []
var _chase_goal := Vector2.INF
var _chase_t := 0.0

var fig: PixelFigure
var board: Board
var label: Label3D
var mark: Label3D
var body: StaticBody3D
var glow: OmniLight3D
var t := 0.0
var _last := Vector2.ZERO
var _vel := Vector2.ZERO
var _has_last := false
var _flames: Array[Sprite3D] = []
var _ember: Sprite3D
var _glint: Sprite3D
var _hole: Sprite3D
var _purse: Node3D

var pos: Vector2:
	get: return Vector2(position.x, position.z) / Fx.S
	set(v): position = Fx.to3(v)

func setup() -> void:
	add_to_group("interact")
	if kind in SOLID: set_solid(true)
	match kind:
		"npc": _setup_npc()
		"sack":
			_board()
			board.part("circle", Vector2(0, 8), Vector2(20, 20), Color("8a6a3a"))
			board.part("circle", Vector2(0, 16), Vector2(10, 10), Color("8a6a3a"), 1)
			board.part("white", Vector2(0, 19), Vector2(8, 3), Color("c9a24a"), 2)
		"fleece":
			_board()
			board.part("circle", Vector2(0, 4), Vector2(24, 24), Color("cfc6b3"))
			board.part("circle", Vector2(8, 2), Vector2(14, 14), Color(0.6, 0.12, 0.12, 0.6), 1)
			board.part("circle", Vector2(-6, 6), Vector2(12, 12), Color("e8e0cc"), 1)
		"ewe":
			_board()
			var dark := Color("2a2420")
			board.part("white", Vector2(-6.5, 1), Vector2(3, 6), dark)
			board.part("white", Vector2(7.5, 1), Vector2(3, 6), dark)
			board.part("circle", Vector2(0, 12), Vector2(26, 26), Color("e8e2d2"), 1)
			board.part("circle", Vector2(-8, 14), Vector2(18, 18), Color("f0eadc"), 2)
			board.part("circle", Vector2(8, 14), Vector2(18, 18), Color("f0eadc"), 2)
			board.part("circle", Vector2(14, 20), Vector2(12, 12), dark, 3)
		"treasure":
			_board()
			glow = Fx.add_light(self, pos, 160.0, Color(0.4, 0.6, 1.0), 0.0)
			for i in 3:
				var x := (i - 1) * 9.0
				_flames.append(board.part("circle", Vector2(x, 13), Vector2(12, 26), Color(0.35, 0.55, 1, 0.85), 1, true))
				_flames.append(board.part("circle", Vector2(x, 8), Vector2(6, 15), Color(0.8, 0.9, 1, 0.9), 2, true))
			_hole = board.part("circle", Vector2(0, 2), Vector2(24, 11), Color("1a1410"), -1)
		"cross":
			_board()
			var wood := Color("4a3320"); var gold := Color("c9a24a")
			board.part("white", Vector2(0, 32), Vector2(6, 64), wood)
			board.part("white", Vector2(0, 49), Vector2(36, 6), wood, 1)
			board.part("tri", Vector2(0, 68), Vector2(48, 16), Color("2e2217"), 2)
			board.part("circle", Vector2(0, 40), Vector2(10, 10), gold, 3)
			for i in 8:
				var a := i * PI / 4.0
				var ray := board.part("white", Vector2(0, 40) + Vector2(cos(a), sin(a)) * 8.0, Vector2(4, 1.5), gold, 3)
				ray.rotation.z = a
			_ember = board.part("circle", Vector2(0, 6), Vector2(6, 6), Color(1, 0.7, 0.3, 0.8), 3, true)
			glow = Fx.add_light(self, pos, 150.0, Color(1, 0.8, 0.5), 0.5)
		"clue", "task":
			# nothing to see but a soft glint while there is something left to learn here
			_board(false)
			_glint = board.part("circle", Vector2(0, 26), Vector2(12, 12), Color(1, 0.78, 0.4, 0), 5, true)
		"bell":
			_board()
			board.part("white", Vector2(0, 60), Vector2(6, 100), Color("8a7a5a"))
			board.part("circle", Vector2(0, 8), Vector2(14, 14), Color("b08a3a"), 1)
		"greenman":
			_board()
			board.part("white", Vector2(0, 30), Vector2(44, 52), Color("8d877a"))
			board.part("circle", Vector2(0, 32), Vector2(30, 30), Color("6a6458"), 1)
			for i in 7:
				var a := PI + i * PI / 6.0
				board.part("circle", Vector2(0, 32) + Vector2(cos(a), -sin(a)) * 17.0, Vector2(14, 14), Color("5a6a44"), 2)
			board.part("circle", Vector2(-5, 34), Vector2(4, 4), Color("1a1410"), 3)
			board.part("circle", Vector2(5, 34), Vector2(4, 4), Color("1a1410"), 3)
			board.part("white", Vector2(0, 24), Vector2(12, 2), Color("3a3a2a"), 3)
		"bones":
			_board()
			_purse = Node3D.new()
			board.add_child(_purse)
			board.part("circle", Vector2(0, 8), Vector2(20, 20), Color("8a6a3a"), 0, false, _purse)
			board.part("white", Vector2(0, 19), Vector2(8, 3), Color("c9a24a"), 1, false, _purse)
			var bone := board.part("white", Vector2(-7, 4), Vector2(22, 3), Color("d8d2c0"), 2)
			bone.rotation.z = deg_to_rad(10)
			board.part("circle", Vector2(12, 6), Vector2(12, 12), Color("d8d2c0"), 2)
			board.part("circle", Vector2(10, 7), Vector2(3, 3), Color("1a1410"), 3)
		"sign":
			_board()
			board.part("white", Vector2(0, 17), Vector2(4, 34), Color("4a3320"))
			board.part("white", Vector2(0, 32), Vector2(32, 16), Color("6b4a2e"), 1)
			board.part("white", Vector2(0, 34), Vector2(20, 2), Color("2a1c10"), 2)

func _board(with_shadow := true) -> void:
	board = Board.new()
	add_child(board)
	if with_shadow and kind != "spring":
		var sh := MeshInstance3D.new()
		var pm := PlaneMesh.new()
		pm.size = Vector2(30, 13) * Fx.S
		sh.mesh = pm
		sh.material_override = Mats.unlit(Color(0, 0, 0, 0.35), Fx.circle_tex())
		sh.position.y = 0.012
		add_child(sh)

func _setup_npc() -> void:
	if id.begins_with("shop_") and Shop.STALLS.has(id.substr(5)):
		fig = PixelFigure.make(Shop.STALLS[id.substr(5)].figure, 1.22)
	elif FIGURES.has(id):
		fig = PixelFigure.make(FIGURES[id][0], FIGURES[id][1])
	else:
		fig = PixelFigure.make("npc_" + id, 1.25)
	if fig: add_child(fig)
	else:
		# nobody has drawn this villager yet: a simple robed figure
		_board()
		board.part("circle", Vector2(0, 16), Vector2(24, 30), col)
		board.part("circle", Vector2(0, 32), Vector2(14, 14), Color("d9b48f"), 1)
	label = _label(display, 2.45, 30, Color("e8e0cc"))
	mark = _label("!", 2.95, 52, Fx.AMBER)
	mark.visible = false

func _label(s: String, h: float, font_px: int, c: Color) -> Label3D:
	var l := Label3D.new()
	l.text = s
	l.font_size = font_px
	l.pixel_size = 0.0075
	l.modulate = c
	l.outline_size = 8
	l.outline_modulate = Color(0, 0, 0, 0.8)
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.position.y = h
	add_child(l)
	return l

func set_solid(on: bool) -> void:
	if on and body == null:
		body = StaticBody3D.new()
		body.collision_layer = 1
		body.collision_mask = 0
		var cs := CollisionShape3D.new()
		var sh := CylinderShape3D.new()
		sh.radius = 12.0 * Fx.S
		sh.height = 4.0
		cs.shape = sh
		cs.position.y = 2.0
		body.add_child(cs)
		add_child(body)
	elif not on and body != null:
		body.queue_free()
		body = null

## Take the prop out of the world (a gate that has been shut, a clue that has been read).
func retire() -> void:
	used = true
	visible = false
	remove_from_group("interact")
	set_solid(false)

func can_interact() -> bool:
	if not visible: return false
	match kind:
		"crystal": return regrow <= 0.0
		"treasure": return not used and G.dusk >= 0.99
		"spring": return not G.side_has("spring")
		"ewe": return not used
		"sack", "cross", "bones": return not used
	return true

func prompt_text() -> String: return prompt
func interact() -> void: Events.prop_used(self)

## Walk through the points (from Level.find_path), then call `done`.
func walk(points: Array, speed := 85.0, done := Callable()) -> void:
	walk_path.clear()
	for q in points: walk_path.append(q)
	walk_speed = speed; walk_done = done

## One frame of running at a goal that may move (a dog after the hunter or a wolf), round fences and huts.
func steer_to(goal: Vector2, speed: float, dt: float, stop := 0.0) -> void:
	if pos.distance_to(goal) <= stop: return
	_chase_t -= dt
	if _chase_t <= 0.0 or _chase_goal.distance_to(goal) > 80.0 or _chase.is_empty():
		_chase = G.level.find_path(pos, goal, 9.0, self, 220.0)
		_chase_goal = goal; _chase_t = 0.6
	if _chase.is_empty(): return
	var to: Vector2 = _chase[0] - pos
	var st := speed * dt
	if to.length() <= st:
		pos = _chase.pop_front()
	else:
		pos += to.normalized() * st

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
	if d > 2400.0:   # lost him for good (a fall, a scripted jump): catch up out of sight
		pos = G.player.pos - G.player.facing * 40.0
		return
	if d < 46.0: return
	if d > 220.0:   # fallen behind: run after him round the walls, quicker the further he is
		steer_to(G.player.pos, clampf(d * 1.4, 260.0, 460.0), dt, 46.0)
		return
	var sp: float = clampf(d * 2.8, 120.0, 340.0) * dt
	var dir := to / d
	for a in [0.0, 0.6, -0.6, 1.2, -1.2, 1.8, -1.8]:
		var step: Vector2 = dir.rotated(a) * sp
		if G.level.is_free(pos + step, 7.0, self):
			pos += step
			return

func _process(dt: float) -> void:
	t += dt
	_move(dt)
	if regrow > 0.0: regrow = maxf(0.0, regrow - dt)
	if fig:
		var p := pos
		if _has_last and dt > 0.0:
			var v := (p - _last) / dt
			if v.length() > 1500.0: v = Vector2.ZERO   # a teleport
			_vel = _vel.lerp(v, 1.0 - exp(-dt * 10.0))
		_last = p; _has_last = true
		# a villager turns to look at the hunter when he comes near
		var look := facing
		if is_instance_valid(G.player):
			var to: Vector2 = G.player.pos - p
			if to.length() < 160.0: look = to.normalized()
		if _vel.length() > 25.0: look = _vel.normalized()   # walking: he looks where he is going
		fig.tick("move", _vel, look, dt)
		if mark:
			mark.visible = Events.marker_for(id)
			mark.position.y = 2.95 + sin(t * 4.0) * 0.04
	match kind:
		"sack", "ewe": board.visible = not used
		"cross":
			_ember.visible = not used
			board.set_color(_ember, Color(1, 0.7, 0.3, 0.6 + 0.3 * sin(t * 5.0)))
			Fx.set_light(glow, 0.25 if used else 0.5)
		"bones": _purse.visible = not used
		"treasure":
			var burning := can_interact()
			Fx.set_light(glow, 0.9 + 0.2 * sin(t * 7.0) if burning else 0.0)
			for i in _flames.size():
				var f := _flames[i]
				f.visible = burning
				var h := 26.0 + 8.0 * sin(t * 9.0 + (i / 2) * 2.0)
				var x := ((i / 2) - 1) * 9.0
				if i % 2 == 0:
					f.scale = Vector3(12 * Fx.S, h * Fx.S, 1); f.position = Vector3(x * Fx.S, h / 2.0 * Fx.S, f.position.z)
				else:
					f.scale = Vector3(6 * Fx.S, h * 0.6 * Fx.S, 1); f.position = Vector3(x * Fx.S, h * 0.3 * Fx.S, f.position.z)
			_hole.visible = used
	if _glint:
		var d := 9999.0
		if is_instance_valid(G.player): d = G.player.pos.distance_to(pos)
		var show: bool = visible and d < 320.0 and Quests.pending(self)
		var a := clampf((320.0 - d) / 160.0, 0.0, 1.0) * (0.55 + 0.35 * sin(t * 4.0)) if show else 0.0
		board.set_color(_glint, Color(1, 0.78, 0.4, a))
		_glint.position.y = (26.0 + sin(t * 2.0) * 3.0) * Fx.S
