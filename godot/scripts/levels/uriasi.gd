## Cetatea Uriașilor, the Giants' Fortress on the wooded hill above Saschiz: a broken ring wall, boulders stacked
## like a child's blocks, and the giant with three children in his apron.
extends Level

const MID := Vector2(2200, 1700)
const SAFE := [Vector2(1250, 2750), Vector2(1450, 2850), Vector2(1650, 2780)]
const KIDS := ["Paul", "Ioana", "Andrei"]

var giant: Giant
var kids: Array = [null, null, null]
var freed := [false, false, false]
var exit_prop: Prop
var homecoming := false   # after the fight: the children come back to sit by him

## Inside the broken ring wall of the hill fortress.
func inside_ring(p: Vector2) -> bool:
	var d := p - MID
	return d.x * d.x / (1440.0 * 1440.0) + d.y * d.y / (990.0 * 990.0) < 1.0

func build() -> void:
	title = "CETATEA URIAȘILOR"
	subtitle = "The Giants' Fortress above Saschiz"
	size = Vector2(4400, 3600)
	spawn = Vector2(2200, 3300)
	ground = Color("2a3022")
	tile = ""
	quest = SxQuest.new()
	rng = NetRandom.new(1347)
	var beaten := G.side_has("sx_giant")
	scatter(Rect2(Vector2.ZERO, size), 400, [Color("343a28"), Color("2a2e22"), Color("403c2e")])
	add_path([Vector2(2200, 3600), Vector2(2150, 3200), Vector2(2200, 2800)], 110.0)
	# the broken ring wall: an oval on the hilltop, open at the south gate and where it has fallen
	var run := []
	for i in 73:
		var a := i * 360.0 / 72.0
		var gap := (a > 78.0 and a < 102.0) or (a > 205.0 and a < 222.0) or (a > 318.0 and a < 330.0)   # the gate (south), two breaches
		if gap:
			if run.size() > 1: add_curtain(run, 46.0, 40.0, "ring")
			run = []
			continue
		run.append(MID + Vector2(cos(deg_to_rad(a)) * 1500.0, sin(deg_to_rad(a)) * 1050.0))
	if run.size() > 1: add_curtain(run, 46.0, 40.0, "ring")
	add_block_rotated(MID + Vector2(-1500, -80), Vector2(260, 260), 0.0, "tower", 120.0)
	add_block_rotated(MID + Vector2(1480, 120), Vector2(240, 240), 0.0, "tower", 110.0)
	add_block_rotated(MID + Vector2(300, -1060), Vector2(280, 220), 0.0, "tower", 130.0)
	# the woods outside the wall
	var x := 60.0
	while x < size.x:
		var y := 60.0
		while y < size.y:
			var p := Vector2(x + (rng.f() - 0.5) * 120.0, y + (rng.f() - 0.5) * 120.0)
			y += 170.0
			var d := p - MID
			if d.x * d.x / (1650.0 * 1650.0) + d.y * d.y / (1200.0 * 1200.0) < 1.0 or (absf(p.x - 2200.0) < 200.0 and p.y > 2600.0): continue
			if rng.f() < 0.3: continue
			add_tree(p, rng.f() < 0.35)
		x += 170.0
	add_wall(Vector2(size.x / 2.0, -20), Vector2(size.x, 40))
	add_wall(Vector2(size.x / 2.0, size.y + 20), Vector2(size.x, 40))
	add_wall(Vector2(-20, size.y / 2.0), Vector2(40, size.y))
	add_wall(Vector2(size.x + 20, size.y / 2.0), Vector2(40, size.y))
	# the giant's toys: boulders stacked into little towers
	for o in [Vector2(-700, -300), Vector2(650, -450), Vector2(-400, 520), Vector2(800, 380)]:
		for k in 3: add_block(Rect2(MID.x + o.x - 40 + k * 6, MID.y + o.y - 40 - k * 70, 80, 70), "stone", 40.0 + k * 30.0)
	exit_prop = add_prop("task", "exit", "Down to Saschiz", Vector2(2200, 3480), "")
	add_trigger(Rect2(1900, 3540, 600, 60), func(): quest.use(exit_prop))
	add_torch(MID, 420.0, Color(0.75, 0.8, 1), 0.3)
	if beaten:
		add_prop("npc", "giant", "Uriașul", MID + Vector2(0, -60), "E   Speak with the giant", Color("6a6a60"))
		return
	for i in 3: kids[i] = add_prop("npc", "kid%d" % (i + 1), KIDS[i], MID + Vector2(-50 + i * 50, 40), "E   Speak", Color("6a5a40"))
	giant = spawn_enemy("giant", MID, Giant)
	spots["giant"] = MID
	giant.child_freed.connect(_freed)
	giant.sat_down.connect(_on_sat)
	G.boss = giant

func _process(dt: float) -> void:
	super(dt)
	if not is_instance_valid(giant): return
	for i in 3:
		if not is_instance_valid(kids[i]): continue
		if homecoming: continue
		if freed[i]: kids[i].pos = kids[i].pos.move_toward(SAFE[i], 220.0 * dt)
		else: kids[i].pos = giant.pos + Vector2(-40 + i * 40, -30)

func _freed(n: int) -> void:
	var i := n - 1
	if i < 0 or i > 2 or freed[i]: return
	freed[i] = true
	Audio.sfx("blip", -4.0, 1.4)
	Hud.banner("THE LAST CHILD" if n == 3 else "A CHILD SLIPS FREE", ["Paul tumbles out of the apron and runs for the gate.", "Ioana wriggles out and runs, clutching her clay horse.", "Andrei climbs down the giant's knee."][i])

func _on_sat() -> void:
	G.side_add("sx_giant")
	G.boss = null
	Hud.banner("THE GIANT SITS DOWN", "The rot on his back is broken. He looks at his hands as if he has never seen them.")
	# the giant himself stays sitting where he is; this is only the spot to speak to him from
	var p := add_prop("npc", "giant", "Uriașul", giant.pos + Vector2(0, 90), "E   Speak with the giant", Color("6a6a60"))
	if p.fig: p.fig.visible = false
	p.set_solid(false)
	Enemy.all.erase(giant)
	_after_fight()

## The rot leaves him in black puffs, he sinks down to sit, and the children he took come back and sit by his knees.
func _after_fight() -> void:
	giant.face = Vector2(0, 1)
	for k in 5:
		var a := k * 1.3
		Fx.ring(giant.pos + Vector2(cos(a) * 30.0, -20.0 + sin(a) * 20.0), Color(0.06, 0.05, 0.07), 90.0 + k * 30.0, 0.9)
		Audio.sfx("hit", -14.0, 0.4)
		await get_tree().create_timer(0.35).timeout
		if not is_instance_valid(giant): return
	Fx.shake(6.0)
	await get_tree().create_timer(1.6).timeout
	if not is_instance_valid(giant): return
	homecoming = true
	for i in 3:
		if not is_instance_valid(kids[i]): continue
		var seat: Vector2 = giant.pos + Vector2(-90 + i * 90, 95 + (i % 2) * 20)
		kids[i].walk([seat], 120.0, func(): kids[i].facing = Vector2(0, -1))
	Hud.toast("The children come back, slowly, and sit by his knees.")
