## Every regular creature (wolf, pricolici, scarecrow, shade, iele, moroi, strigoi, fire skull, blood ward, bat,
## the spellbound and the hungry dead). Bosses extend this. All numbers are map pixels and pixels a second.
class_name Enemy
extends Actor

signal died(e: Enemy)
signal hurted(e: Enemy)       # after every blow that lands
signal fled(e: Enemy)
signal call_thralls(e: Enemy)

static var all: Array[Enemy] = []
static var fainted_ones: Array[Enemy] = []
static var _song_t := 0.0   # shared by all the Iele

## kind: [hp, speed, dmg, radius, coin, aggro, starting state]
const STATS := {
	"wolf": [18, 150, 7, 13, 3, 430], "pricolici": [46, 118, 14, 17, 9, 460],
	"scarecrow": [62, 62, 12, 16, 7, 170, "dormant"], "shade": [14, 128, 6, 12, 0, 700],
	"iele": [26, 170, 9, 12, 5, 330], "moroi": [60, 76, 14, 15, 8, 190, "dormant"],
	"strigoi": [52, 118, 12, 14, 9, 380], "skull": [8, 150, 14, 12, 0, 9999, "chase"],
	"ward": [90, 0, 0, 22, 15, 520], "spiridus": [10, 172, 5, 10, 1, 330],
	"spiridus_cap": [70, 92, 13, 16, 12, 360], "thrall": [24, 96, 8, 13, 2, 300],
	"rat": [5, 205, 3, 8, 0, 260], "dead": [9999, 135, 4, 14, 0, 0], "dead_big": [9999, 85, 8, 22, 0, 0],
	"costache": [45, 72, 3, 24, 5, 0], "vantoasa": [30, 150, 6, 13, 2, 9999, "chase"],
	"maiastra": [18, 260, 6, 10, 2, 9999, "chase"], "snarebear": [150, 128, 11, 30, 0, 0],
	"cow": [40, 45, 0, 18, 0, 0], "brawler": [14, 130, 3, 13, 0, 9999, "chase"],
	"sexton": [150, 88, 15, 16, 20, 420], "bat": [6, 235, 4, 8, 1, 380],
}
## kind: [figure (or fallbacks), height in metres]
const FIGURES := {
	"strigoi": ["strigoi", 1.35], "pricolici": ["pricolici", 1.5], "wolf": ["wolf", 1.0], "spiridus": ["spiridus", 0.62],
	"spiridus_cap": [["spiridus_cap", "spiridus"], 0.95], "moroi": ["moroi", 1.35], "iele": ["iele", 1.12],
	"shade": ["shade", 1.3], "thrall": ["thrall", 1.25], "giant": ["uriasul", 3.0], "varcolac": ["varcolac", 2.6], "cow": ["limousin_cow", 1.2],
	"dead": ["shade", 1.25], "dead_big": ["shade", 1.75], "costache": [["costache_sheet", "shade"], 1.5],
	"bull": ["limousin_bull", 2.7], "snarebear": ["snare_bear", 2.1], "vantoasa": [["vantoasa", "shade"], 1.25],
	"maiastra": [["maiastra", "spiridus"], 0.9], "iele_s": ["iele", 1.18], "vampire": [["vampire", "strigoi"], 1.55],
	"strigoi_mort": [["strigoi_mort", "strigoi"], 2.3], "warden": [["crypt_warden", "strigoi"], 1.9],
	"rat": ["rat", 0.55], "sexton": [["sexton", "npc_sexton"], 1.35],
}
const BRAWLERS := ["npc_konrad", "npc_vasile", "npc_hans", "npc_andreas"]
const FAINTS := ["thrall", "sexton", "brawler", "cow", "bull", "costache", "snarebear"]
const GRUMBLES := ["Where's my colivă?", "In my day the table was laid!", "Ungrateful lot.", "Not even a candle...", "Mmm. Plates.", "My own grandson!"]

var kind := "wolf"
var harmless := false
var _dead_hits := 0   # a blow only startles it (the stână's cows)
var hp := 20.0
var max_hp := 20.0
var speed := 140.0
var dmg := 8.0
var coin := 3
var aggro := 400.0
var state := "idle"
var t := 0.0
var atk_cd := 0.0
var flash := 0.0
var salted := 0.0
var orbit := 0.0
var strike_t := 0.0     # > 0 while a bite or strike just landed (drawn as the attack animation)
var face := Vector2.RIGHT
var knock := Vector2.ZERO
var lunge_dir := Vector2.ZERO
var home := Vector2.ZERO
var hit_done := false
var heavy := false      # too big for the hunter to shoulder aside: it shoves him instead
var fainted := false    # the spellbound never die: they keel over with stars round their heads
var flee_low := false   # Muma's wolves: beaten low, they break off and run for the trees
var rot_mark := false
var fleeing := false
var goal = null         # Vector2: where the hungry dead are headed
var slow_k := 1.0
var stun_t := 0.0
var player: Player
var _seed := randf()
var _rise_t := 0.0
var _last_strike := 0.0
var _star_t := 0.0
var _run_t := 0.0
var _gust_t := 0.0
var _gust_cd := 2.0
var _gust_dir := Vector2.ZERO
var _cow_t := 0.0
var _flee_t := 0.0
var _cow_goal := Vector2.ZERO
var _herd := Vector2.ZERO     # where the herder is driving a cow this moment
var _herd_t := 0.0
var _cow_v := Vector2.ZERO    # a cow's smoothed walk: it eases into turns instead of flicking about
var _called := false
var _bar: Node3D
var _bar_fill: Sprite3D

var boss_title := ""
## What the boss bar calls this one, and the line under it; bosses override both.
func hud_name() -> String: return boss_title if boss_title != "" else kind.to_upper()
func hud_hint() -> String: return ""

func _init() -> void:
	super()
	collision_layer = 4
	collision_mask = 1

func _enter_tree() -> void: all.append(self)
func _exit_tree() -> void:
	all.erase(self)
	fainted_ones.erase(self)

func at_goal() -> bool:
	return goal != null and pos.distance_to(goal) < 90.0

func setup(k: String) -> void:
	kind = k
	if STATS.has(k):
		var s: Array = STATS[k]
		hp = s[0]; speed = s[1]; dmg = s[2]; radius = s[3]; coin = s[4]; aggro = s[5]
		if s.size() > 6: state = s[6]
	if k in ["iele", "vantoasa", "maiastra", "bat"]: orbit = randf() * TAU
	max_hp = hp
	_make_figure()
	set_body_radius(radius * 0.95)

func _make_figure() -> void:
	if kind == "brawler":
		set_figure(BRAWLERS[absi(roundi((pos.x - pos.y) / 7.0)) % BRAWLERS.size()], 1.25)
	elif FIGURES.has(kind):
		set_figure(FIGURES[kind][0], FIGURES[kind][1])
	if fig:
		# a pixel figure is drawn wider than its old footprint: bodies keep a believable distance
		var b := 22.0 if kind == "pricolici" else (15.0 if kind == "wolf" else 18.0)
		if radius < b: radius = b
	_bar = Node3D.new()
	_bar.rotation.x = -deg_to_rad(Fx.PITCH)
	_bar.visible = false
	add_child(_bar)
	for i in 2:
		var s := Sprite3D.new()
		s.texture = Mats.tex("res://sprites/white.png")
		s.pixel_size = 0.25
		s.shaded = false
		s.no_depth_test = true
		s.render_priority = 3 + i
		s.modulate = Color(0, 0, 0, 0.7) if i == 0 else Color("b3372f")
		_bar.add_child(s)
		if i == 0: s.scale = Vector3(32 * Fx.S, 6 * Fx.S, 1)
		else: _bar_fill = s

## The chapter's difficulty: x multiplies health, y damage.
func apply_difficulty(m: Vector2) -> void:
	hp *= m.x; max_hp = hp; dmg *= m.y

## The unclean dead: burned by salt rings.
func undead() -> bool:
	return kind in ["iele", "moroi", "shade", "strigoi", "skull"]

# ------------------------------------------------------------------ frame

func _physics_process(dt: float) -> void:
	if fainted:
		vel = Vector2.ZERO
		flash = maxf(0.0, flash - dt)
		_star_t += dt
		if _star_t > 1.3:
			_star_t = 0.0
			Fx.text(pos, "* * *", Fx.AMBER, 34.0)
		return
	t += dt
	flash = maxf(0.0, flash - dt)
	atk_cd = maxf(0.0, atk_cd - dt)
	strike_t = maxf(0.0, strike_t - dt)
	player = G.player
	if not is_instance_valid(player) or player.hp <= 0.0:
		vel = Vector2.ZERO
		return
	var to := player.pos - pos
	var d := to.length()
	var mult: float = 1.0 + 0.4 * G.dusk
	salted = maxf(0.0, salted - dt)
	if not step(dt, to, d, mult):
		match state:
			"dormant", "idle":
				vel = knock
				if d < aggro:
					if kind in ["moroi", "strigoi"] and state == "dormant":
						state = "rise"; t = 0.0
						if kind == "moroi": Audio.sfx("moroi", -4.0, randf_range(0.85, 1.1))
						else: Audio.sfx("shriek", -8.0, randf_range(0.8, 0.95))
					else:
						state = "chase"
						Audio.vocal(self, true)
			"rise":
				vel = Vector2.ZERO
				if t > 0.8: state = "chase"
			"chase":
				var dir := to.normalized()
				face = dir
				if kind in ["pricolici", "spiridus_cap"] and d < 200.0 and atk_cd <= 0.0:
					state = "windup"; t = 0.0
				else:
					vel = dir * speed * mult + knock + separation()
					if d < radius + 26.0 and atk_cd <= 0.0:
						player.hurt(dmg * mult, dir)
						atk_cd = 1.0; strike_t = 0.45
						knock = -dir * 220.0   # bounce off so it can't sit inside the hunter
			"windup":
				vel = knock
				face = to.normalized()
				if t > 0.5:
					state = "lunge"; t = 0.0; lunge_dir = to.normalized(); hit_done = false; strike_t = 0.5
			"lunge":
				vel = lunge_dir * 470.0
				if not hit_done and d < radius + 24.0:
					player.hurt(dmg * mult, lunge_dir)
					hit_done = true
				if t > 0.3 or touching_wall:
					state = "chase"; atk_cd = 1.5
		knock = knock.move_toward(Vector2.ZERO, 900.0 * dt)
	if not is_inside_tree() or is_queued_for_deletion(): return
	_shoulder(d, to)
	slide()

## Bodies don't stand inside each other: a creature is shouldered aside by the hunter, a big one shoves him.
func _shoulder(d: float, to: Vector2) -> void:
	if fleeing or state in ["leap", "dormant"] or _shape.disabled or d < 0.1: return
	var overlap := radius * 0.95 + player.radius - d
	if overlap <= 0.0: return
	if heavy: player.pull += to / d * minf(overlap * 12.0, 400.0)
	else: vel -= to / d * minf(overlap * 12.0, 400.0)

## Kind-specific behaviour. True when this frame was fully handled.
func step(dt: float, to: Vector2, d: float, mult: float) -> bool:
	if fleeing: return _flee_step(dt, to)
	match kind:
		"skull": return _skull_step(dt, to, d)
		"ward": return _ward_step(d)
		"bat", "maiastra": return _bat_step(dt, to, d, mult)
		"vantoasa": return _vantoasa_step(dt, to, d, mult)
		"sexton": return _sexton_step(dt, to, d, mult)
		"cow": return _cow_step(dt, to)
		"dead", "dead_big", "costache": return _dead_step(dt, to, d)
		"strigoi":
			if _strigoi_step(to, d, mult):
				knock = knock.move_toward(Vector2.ZERO, 900.0 * dt)
				return true
		"iele":
			if _iele_step(dt, to, d, mult):
				knock = knock.move_toward(Vector2.ZERO, 900.0 * dt)
				return true
	return false

## Petrea's gust and the like: a hard push that does no harm.
func shove(v: Vector2) -> void:
	knock = v
	if stun_t < 0.4: stun_t = 0.4

func separation() -> Vector2:
	var push := Vector2.ZERO
	var p := pos
	for o in all:
		if o == self: continue
		var dv: Vector2 = p - o.pos
		var dl := dv.length()
		if dl < 32.0 and dl > 0.1: push += dv / dl * (32.0 - dl) * 5.0
	return push

# The vântoase, wind spirits called by Ilie's nai: they circle the hunter at a distance and every few seconds
# throw a gust that shoves him across the clearing.
func _vantoasa_step(dt: float, to: Vector2, d: float, mult: float) -> bool:
	orbit += dt * 1.6
	var tgt := player.pos + Vector2.from_angle(orbit) * 240.0
	vel = (tgt - pos).limit_length(speed * mult) + knock + separation()
	face = to.normalized()
	_gust_cd -= dt
	if _gust_cd <= 0.0 and d < 460.0:
		_gust_cd = randf_range(2.4, 3.4); _gust_t = 0.35; _gust_dir = to.normalized()
		Fx.ring(pos, Color(0.75, 0.8, 0.9, 0.7), 90.0, 0.3)
		Fx.text(pos, "WHOOSH", Color(0.8, 0.85, 0.95), 50.0)
		Audio.sfx_at("swing", pos, -6.0, 0.4)
	if _gust_t > 0.0:
		_gust_t -= dt
		if not player.wormwood: player.pull += _gust_dir * 760.0
		if d < radius + 40.0 and atk_cd <= 0.0:
			player.hurt(dmg * mult, _gust_dir)
			atk_cd = 1.0
	knock = knock.move_toward(Vector2.ZERO, 900.0 * dt)
	return true

func _start_flee() -> void:
	fleeing = true; _run_t = 0.0; state = "flee"
	set_solid(false)
	all.erase(self)
	if rot_mark:
		rot_mark = false
		Fx.ring(pos, Color(0.7, 0.15, 0.2), 90.0, 0.6)
		Fx.text(pos, "(it shakes itself)", Color(0.85, 0.8, 0.7), 46.0)
	else: Fx.text(pos, "yelp!", Color(0.85, 0.8, 0.7), 40.0)
	Audio.sfx_at("die_wolf", pos, -14.0, 1.4)
	fled.emit(self)

func _flee_step(dt: float, to: Vector2) -> bool:
	_run_t += dt
	var away := -to.normalized() if to.length_squared() > 1.0 else Vector2.RIGHT
	vel = away * speed * 1.15 + knock
	face = away
	knock = knock.move_toward(Vector2.ZERO, 900.0 * dt)
	if _run_t > 2.6: queue_free()
	return true

# Apold's hungry dead: they go for the food (or the graves) they were given a goal for, swipe at the hunter
# if he stands in the way, and cannot be hurt, only knocked stumbling back for a few seconds.
func _dead_step(dt: float, to: Vector2, d: float) -> bool:
	stun_t -= dt
	if stun_t > 0.0:
		vel = knock
		knock = knock.move_toward(Vector2.ZERO, 700.0 * dt)
		return true
	var target: Vector2 = goal if goal != null else player.pos
	var g := target - pos
	if d < radius + 60.0 and atk_cd <= 0.0 and dmg > 0.0:
		player.hurt(dmg, to.normalized())
		atk_cd = 1.4; strike_t = 0.4
	vel = (g.normalized() * speed * slow_k if g.length() > 60.0 else Vector2.ZERO) + separation()
	if vel.length_squared() > 1.0: face = vel.normalized()
	if randf() < dt * 0.08: Fx.text(pos, GRUMBLES[randi() % GRUMBLES.size()], Color(0.75, 0.8, 0.9), 50.0)
	return true

# A Limousin cow: grazes, ambles about her pasture, and trots off when somebody hits her.
func _cow_step(dt: float, to: Vector2) -> bool:
	if home == Vector2.ZERO: home = pos
	_flee_t -= dt; _cow_t -= dt; _herd_t -= dt
	var want := Vector2.ZERO
	if _herd_t > 0.0:
		want = _herd
	elif _flee_t > 0.0:
		want = -to.normalized() * 150.0
	else:
		if _cow_t <= 0.0:
			_cow_t = randf_range(3.5, 7.0)
			_cow_goal = pos if randf() < 0.5 else home + Vector2.from_angle(randf() * TAU) * sqrt(randf()) * 300.0
		var g := _cow_goal - pos
		if g.length() > 24.0: want = g.normalized() * speed
		else: _cow_goal = pos
	_cow_v = _cow_v.lerp(want, 1.0 - exp(-4.0 * dt))
	vel = _cow_v + knock * 0.5
	# it turns its head slowly, and only while it is really walking
	if _cow_v.length() > 30.0:
		face = Vector2.from_angle(lerp_angle(face.angle(), _cow_v.angle(), 1.0 - exp(-3.0 * dt)))
	knock = knock.move_toward(Vector2.ZERO, 900.0 * dt)
	# pressed against a fence: give up on that goal rather than grind against it
	if want != Vector2.ZERO and _herd_t <= 0.0 and not G.level.is_free(pos + want.normalized() * 30.0, radius * 0.6, self):
		_cow_goal = pos; _cow_t = randf_range(1.0, 2.5)
	return true

## The herder drives a cow: it walks that way, easing into it.
func herd(v: Vector2) -> void:
	_herd = v; _herd_t = 0.3

# Viscri's sexton, the vampire's thrall: swings the bell rope in a wide circle round himself, and calls
# the spellbound villagers to him once he is badly hurt.
func _sexton_step(dt: float, to: Vector2, d: float, mult: float) -> bool:
	if not _called and hp < max_hp * 0.45:
		_called = true
		call_thralls.emit(self)
		Audio.sfx_at("bell", pos, -6.0, 0.7)
		Fx.text(pos, "DONG", Fx.AMBER, 48.0)
	match state:
		"chase":
			face = to.normalized()
			if d < 150.0 and atk_cd <= 0.0:
				state = "windup"; t = 0.0; vel = Vector2.ZERO
				return true
			vel = face * speed * mult + knock + separation()
			knock = knock.move_toward(Vector2.ZERO, 900.0 * dt)
			return true
		"windup":
			vel = knock * 0.5
			knock = knock.move_toward(Vector2.ZERO, 900.0 * dt)
			if t > 0.6:
				state = "sweep"; t = 0.0; hit_done = false; strike_t = 0.5
				Audio.sfx_at("slash", pos, -6.0, 0.6)
			return true
		"sweep":
			vel = Vector2.ZERO
			if not hit_done and t > 0.12 and d < 145.0:
				player.hurt(dmg * mult, to.normalized())
				hit_done = true
			if t > 0.45:
				state = "chase"; atk_cd = 1.6
			return true
	return false

# A burning skull that homes on the hunter and bursts on contact.
func _skull_step(dt: float, to: Vector2, d: float) -> bool:
	face = face.slerp(to.normalized(), minf(1.0, dt * 2.2)).normalized()
	vel = face * speed + knock
	knock = knock.move_toward(Vector2.ZERO, 900.0 * dt)
	if d < 30.0 or t > 6.0:
		if d < 40.0: player.hurt(dmg, face)
		FirePatch.spawn(pos)
		Audio.sfx("fire", -8.0, 1.5)
		queue_free()
	return true

func _ward_step(d: float) -> bool:
	vel = Vector2.ZERO
	if d < aggro and atk_cd <= 0.0:
		atk_cd = 6.0
		var bat: Enemy = G.level.spawn_enemy("bat", pos + Vector2(randf_range(-30.0, 30.0), -40.0))
		bat.state = "chase"
	return true

# Bats: erratic swoops, nip and veer away.
func _bat_step(dt: float, to: Vector2, d: float, mult: float) -> bool:
	orbit += dt * 7.0
	if state == "idle":
		vel = Vector2.from_angle(orbit * 0.4) * 40.0
		if d < aggro:
			state = "chase"
			Audio.sfx("bat", -10.0, randf_range(0.9, 1.3))
		return true
	var dir := to.normalized()
	face = dir
	var side := dir.orthogonal()
	if state == "retreat":
		vel = -dir * speed * 0.8 + side * sin(orbit) * 120.0
		if t > 0.8: state = "chase"
		return true
	vel = dir * speed * mult + side * sin(orbit) * 160.0 + knock
	knock = knock.move_toward(Vector2.ZERO, 900.0 * dt)
	if d < radius + 22.0 and atk_cd <= 0.0:
		player.hurt(dmg * mult, dir)
		atk_cd = 0.9; state = "retreat"; t = 0.0
	return true

# Strigoi: stalk, crouch, then leap onto where the hunter stood.
# Bites drink blood and heal the strigoi, unless the hunter wears garlic.
func _strigoi_step(to: Vector2, d: float, mult: float) -> bool:
	match state:
		"chase":
			face = to.normalized()
			vel = face * speed * mult + knock + separation()
			if d > 110.0 and d < 330.0 and atk_cd <= 0.0:
				state = "crouch"; t = 0.0; home = player.pos
			elif d < radius + 26.0 and atk_cd <= 0.0: _bite(face, mult)
			return true
		"crouch":
			vel = knock
			if t > 0.55:
				state = "leap"; t = 0.0; lunge_dir = pos
				Audio.sfx("shriek", -6.0, randf_range(0.95, 1.2))
			return true
		"leap":
			var k := clampf(t / 0.45, 0.0, 1.0)
			vel = Vector2.ZERO
			pos = lunge_dir.lerp(home, k)
			if k >= 1.0:
				state = "chase"; atk_cd = 2.0
				Fx.ring(pos, Color(0.6, 0.1, 0.1, 0.7), 60.0, 0.35)
				if player.pos.distance_to(pos) < 62.0: _bite((player.pos - pos).normalized(), mult)
			return true
	return false

func _bite(dir: Vector2, mult: float) -> void:
	var amount := dmg * mult * (0.5 if player.garlic else 1.0)
	player.hurt(amount, dir)
	atk_cd = 1.1
	strike_t = 0.5
	if not player.garlic:
		hp = minf(max_hp, hp + amount * 0.5)
		Fx.text(pos, "drinks", Color("c0392b"), 40.0)

# Iele: dance around their fairy ring, then circle the hunter, sing to slow and draw him in, and dart in.
func _iele_step(dt: float, to: Vector2, d: float, mult: float) -> bool:
	if state in ["windup", "lunge"]: return false
	if state == "idle":
		orbit += dt * 1.3
		vel = (home + Vector2.from_angle(orbit) * 70.0 - pos) * 3.0 + knock
		face = Vector2.from_angle(orbit + PI / 2.0)
		if d < aggro:
			state = "chase"
			if _song_t <= 0.0:
				Audio.sfx("iele_song", -6.0, randf_range(0.95, 1.05))
				_song_t = 4.5
				Hud.toast("The Iele sing. Your legs grow heavy...")
		return true
	_song_t = maxf(0.0, _song_t - dt / 3.0)
	orbit += dt * 1.5
	var tgt := player.pos + Vector2.from_angle(orbit) * 135.0
	face = to.normalized()
	vel = (tgt - pos).limit_length(speed * mult) + knock + separation()
	if salted > 0.0: vel = -to.normalized() * speed + knock
	if d < 290.0 and salted <= 0.0 and not player.wormwood:
		player.slow_t = maxf(player.slow_t, 0.15)
		player.pull += -to.normalized() * 55.0
	if _song_t <= 0.0 and d < 300.0:
		_song_t = 4.5
		Audio.sfx("iele_song", -9.0, randf_range(0.9, 1.1))
	if d < 210.0 and atk_cd <= 0.0 and salted <= 0.0:
		state = "windup"; t = 0.15
	if d > aggro * 2.2: state = "idle"
	return true

# ------------------------------------------------------------------ damage

func salt_hit(ring_pos: Vector2, dt: float) -> void:
	hp -= (16.0 if kind == "moroi" else 11.0) * dt
	flash = 0.05
	knock = (pos - ring_pos).normalized() * 260.0
	if salted <= 0.0:
		Fx.text(pos, "salt!", Color("e8eeff"), 30.0)
		if state == "dormant": state = "chase"
	salted = 0.6
	if hp <= 0.0: die()

func hurt(amount: float, dir: Vector2) -> void:
	if fainted: return
	if harmless: amount = 0.0
	# the Spiriduș-căpitan's pot-lid: blows from the front clang off unless he is still recovering from his own swing
	if kind == "spiridus_cap" and is_instance_valid(player) and state in ["chase", "idle"] and atk_cd <= 0.4 \
			and face.dot((player.pos - pos).normalized()) > 0.35:
		amount *= 0.15
		Audio.sfx_at("blip", pos, -6.0, 0.45)
		Fx.text(pos, "CLANG", Color(0.8, 0.8, 0.85), 40.0)
	hp -= amount
	flash = 0.12
	knock = dir * 280.0
	# a blade in flesh for the living and the undead-in-flesh; a dull knock for bone, straw and spirits
	if not kind in ["wolf", "pricolici", "strigoi", "moroi"]: Audio.sfx("hit", -5.0)
	elif hp <= 0.0: Audio.sfx("kill", -6.0, randf_range(0.95, 1.05))
	else:
		Audio.sfx("slash", -8.0)
		Audio.sfx("hit", -14.0, 0.8)
	if state in ["dormant", "idle"]: state = "chase"
	if kind in ["dead", "dead_big"]:
		hp = max_hp   # already dead: a blade only drives them back...
		stun_t = 2.5 if kind == "dead" else 1.6
		knock = dir * (420.0 if kind == "dead" else 260.0)
		Audio.sfx_at("hit", pos, -10.0, 0.7)
		_dead_hits += 1
		hurted.emit(self)
		# ...until they have had enough, and lie back down in the earth until the next wave
		if _dead_hits >= (3 if kind == "dead" else 6):
			Fx.text(pos, "(it sinks back into the earth)", Color(0.75, 0.8, 0.9), 40.0)
			Fx.ring(pos, Color(0.7, 0.8, 1.0, 0.6), 50.0)
			coin = 0
			die()
		else:
			Fx.text(pos, "Hmph!" if _dead_hits == 1 else "Ugh...", Color(0.75, 0.8, 0.9), 40.0)
		return
	if kind == "cow":
		_flee_t = 2.5
		Audio.sfx_at("boss_roar", pos, -10.0, 1.6)
		Fx.text(pos, "MOO!", Fx.AMBER, 40.0)
	if not harmless: Fx.text(pos, str(roundi(amount)), Color("ffe08a"))
	hurted.emit(self)
	if flee_low and hp <= max_hp * 0.35:
		hp = maxf(hp, 1.0)
		if not fleeing: _start_flee()
		return
	if hp <= 0.0: die()

func die() -> void:
	if kind.begins_with("spiridus") or kind in FAINTS:   # spellbound villagers drop senseless, they are not killed
		if fainted: return
		fainted = true; state = "fainted"; hp = 0.0
		died.emit(self)
		set_solid(false)
		vel = Vector2.ZERO
		all.erase(self)
		fainted_ones.append(self)
		Audio.sfx_at("blip", pos, -8.0, 1.6)
		_pay()
		Fx.text(pos, "* * *", Fx.AMBER, 34.0)
		_bar.visible = false
		return
	died.emit(self)
	match kind:
		"wolf": Audio.sfx_at("die_wolf", pos, -9.0, randf_range(0.95, 1.1))
		"pricolici": Audio.sfx_at("die_beast", pos, -6.0, 0.85)
		"strigoi": Audio.sfx_at("die_beast", pos, -8.0, 1.2)
	if coin > 0: Audio.sfx("coin", -12.0)
	_pay()
	Fx.ring(pos, Color(0.8, 0.8, 0.9, 0.8), 40.0)
	if fig and kind in ["dead", "dead_big", "shade"]:   # smoke has no blood: it just thins out
		var f := fig; fig = null
		remove_child(f); G.level.add_child(f); f.position = position
		var tw := f.create_tween(); tw.tween_property(f, "scale", Vector3(1.3, 0.05, 1.3), 0.6); tw.tween_callback(f.queue_free)
	if fig:
		# it keeps its last pose, topples over in a spreading pool of blood and fades
		fig.become_corpse()
		Fx.corpse(fig, fig.flip)
		fig = null
	queue_free()

func _pay() -> void:
	if coin > 0 and is_instance_valid(G.player):
		G.player.coins += coin
		Fx.text(pos, "+%d" % coin, Fx.AMBER, 16.0)

# ------------------------------------------------------------------ looks

## Which animation the figure plays this frame.
func anim_state() -> String:
	if hp <= 0.0 and not fainted: return "death"
	if state in ["dormant", "rise"] and fig.has_clip("rise"): return state
	if strike_t > 0.0 or state in ["windup", "lunge", "leap", "crouch", "sweep"]: return "attack"
	if flash > 0.08: return "hurt"
	return "move"

func _process(dt: float) -> void:
	if fig == null: return
	var now := Time.get_ticks_msec() / 1000.0
	fig.hurt = clampf(flash / 0.12, 0.0, 1.0)
	fig.hover = 0.0; fig.sink = 0.0; fig.sway = 0.0; fig.alpha = 1.0; fig.tint_mul = Color.WHITE
	if kind == "varcolac" and not call("vulnerable"):   # away from the fire it is only shadow
		fig.tint_mul = Color(0.45, 0.45, 0.6); fig.alpha = 0.75
	if kind == "giant":   # after the fight he sinks down to sit
		set("slump", move_toward(get("slump"), 0.2 if get("done") else 0.0, dt * 0.12))
		fig.sink = get("slump")
	match kind:
		"wolf", "pricolici":
			fig.tint_mul = Color(1.45, 1.42, 1.38)
		"spiridus", "spiridus_cap":
			fig.tint_mul = Color(1.35, 1.32, 1.28)
		"moroi":   # a buried moroi shows only its head above the earth, then shoves itself up out of the ground
			if state == "dormant":
				fig.sink = 0.82; _rise_t = 0.0
			elif state == "rise":
				_rise_t += dt
				var u := clampf(_rise_t / 0.8, 0.0, 1.0)
				fig.sink = 0.82 * (1.0 - u * u * (3.0 - 2.0 * u)) + sin(_rise_t * 60.0) * 0.02 * (1.0 - u)
		"iele", "iele_s":   # the iele never quite touch the ground: they hover and bob, faintly see-through
			fig.hover = 0.18 + sin(now * 2.3 + _seed * 9.0) * 0.06
			fig.tint_mul = Color(0.85, 0.9, 1.0, 0.8)
		"shade", "dead", "dead_big":   # smoke in a man's shape: it drifts higher and the light passes half through it
			fig.hover = 0.32 + sin(now * 3.1 + _seed * 9.0) * 0.09 + (0.15 * strike_t if strike_t > 0.0 else 0.0)
			fig.sway = clampf(-vel.x * Fx.S * 4.0, -14.0, 14.0) + sin(now * 1.7 + _seed * 5.0) * 3.0
			fig.tint_mul = Color(0.7, 0.72, 0.85, 0.86 + 0.08 * sin(now * 5.0 + _seed))
	if state == "windup" and kind in ["wolf", "pricolici", "iele"]:
		fig.tint_mul = fig.tint_mul.lerp(Color(1.4, 0.5, 0.4, fig.tint_mul.a), 0.5 + 0.4 * sin(t * 30.0))
	fig.rotation.z = deg_to_rad(78.0) if fainted else 0.0   # out cold on his side
	# a monster's strike leaves three red claw rakes in front of it
	if strike_t > _last_strike + 0.05 and kind != "iele": Fx.claw(pos, face)
	_last_strike = strike_t
	fig.tick(anim_state(), vel, face, dt)
	var show_bar: bool = hp < max_hp and hp > 0.0 and not kind in ["bat", "skull", "dead", "dead_big"]
	_bar.visible = show_bar
	if show_bar:
		var k := clampf(hp / max_hp, 0.0, 1.0)
		_bar.position.y = fig.height * 1.25 + 0.15
		_bar_fill.scale = Vector3(30 * Fx.S * k, 4 * Fx.S, 1)
		_bar_fill.position.x = (-15.0 + 15.0 * k) * Fx.S
