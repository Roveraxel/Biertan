## The ridge above Richiș. Ilie plays the nai: three phrases bring what the rot has stirred up, then the seven
## Iele themselves. Three are real; they can only be struck when Ilie's Doina makes one solid, and his Căluș
## call bursts two illusions at a time. The level is its own boss bar (the three real sisters' strength).
extends Level

const CENTRE := Vector2(2000, 1400)
const ILIE_AT := Vector2(2000, 2250)
const ILIE_COL := Color(1, 0.85, 0.55)

var wave := 0
var phase := 0
var foes: Array[Enemy] = []
var sisters: Array[IeleSister] = []
var call_t := 0.0
var ribbon_t := 0.0
var well_t := 0.0
var lift_t := 0.0
var lift_anim := 0.0
var wave_delay := 0.0
var calls := 0
var won := false
var started := false
var start_t := 0.0
var lift_from := Vector2.ZERO
var time := 0.0
var ribbons: Array[Dictionary] = []
var wells: Array[Dictionary] = []

# the boss bar reads these
var max_hp := 330.0
var hp: float:
	get:
		var h := 0.0
		for s in sisters:
			if is_instance_valid(s) and s.real: h += maxf(0.0, s.hp)
		return h

func hud_name() -> String: return "THE SEVEN IELE"
func hud_hint() -> String:
	for s in sisters:
		if is_instance_valid(s) and s.real and s.solid_t > 0.0: return "Doina! One of them is solid. Strike her!"
	return "Their song drags you in. Wait for the Doina." if phase == 3 else "Don't strike the dancers. Wait for Ilie's call."

func build() -> void:
	title = "THE RIDGE"
	subtitle = "Above Richiș · Ilie plays"
	size = Vector2(4000, 2900)
	spawn = Vector2(2000, 2050)
	ground = Color("3a403e")
	tile = ""
	quest = RcQuest.new()
	rng = NetRandom.new(1777)
	scatter(Rect2(Vector2.ZERO, size), 360, [Color("4a5252"), Color("363c3a"), Color("5c6264")])
	var x := 80.0
	while x < size.x - 60.0:
		var y := 80.0
		while y < size.y - 60.0:
			var p := Vector2(x + (rng.f() - 0.5) * 120.0, y + (rng.f() - 0.5) * 120.0)
			y += 170.0
			if p.distance_to(CENTRE) < 1150.0 or p.distance_to(ILIE_AT) < 400.0 or (absf(p.x - 2000.0) < 220.0 and p.y > 2000.0): continue
			if rng.f() < 0.3: continue
			add_tree(p, rng.f() < 0.5)
		x += 170.0
	add_wall(Vector2(size.x / 2.0, -20), Vector2(size.x, 40))
	add_wall(Vector2(size.x / 2.0, size.y + 20), Vector2(size.x, 40))
	add_wall(Vector2(-20, size.y / 2.0), Vector2(40, size.y))
	add_wall(Vector2(size.x + 20, size.y / 2.0), Vector2(40, size.y))
	add_decor(CENTRE, "iele_circle")
	add_prop("npc", "ilie", "Moș Ilie", ILIE_AT, "", Color("5a4a3a"))
	add_torch(ILIE_AT + Vector2(0, -40), 260.0, Color(1, 0.65, 0.35), 0.5)
	add_torch(CENTRE, 900.0, Color(0.7, 0.78, 1), 0.45)
	add_trigger(Rect2(1700, 2600, 600, 300), leave)
	if G.side_has("rc_iele"): won = true

func _begin() -> void:
	started = true
	G.start_dialogue("Moș Ilie", [
		"(Ilie sits on a stump at the edge of the clearing and puts the nai to his lips. His hands are shaking. Then they aren't.)",
		"(The first note goes out over the frost like a thread. Something answers it from the trees.)",
		"They come for the one who listens, not the one who plays. Stay in the light, hunter.",
	], func(): _start_wave(1))

func _at(a: float, r: float) -> Vector2:
	return CENTRE + Vector2(cos(a), sin(a)) * r

func _add(kind: String, g: Vector2, flee := false) -> void:
	var e := spawn_enemy(kind, g)
	e.max_hp *= 1.0 + 0.18 * (wave - 1); e.hp = e.max_hp
	e.speed *= lerpf(1.0, 1.12, (wave - 1) / 2.0)
	e.state = "chase"; e.aggro = 4000.0
	if flee:
		e.flee_low = true
		e.fled.connect(func(_e): _wave_check())
	e.died.connect(func(_e): _wave_check())
	foes.append(e)

func _start_wave(w: int) -> void:
	wave = w; foes.clear()
	if w == 1:
		Hud.banner("THE FIRST PHRASE", "Bats, out of the beeches.")
		for i in 8: _add("bat", _at(i * 0.8, 1100.0))
	elif w == 2:
		Hud.banner("THE SECOND PHRASE", "Vântoase. The wind itself turns on you.")
		for i in 4: _add("vantoasa", _at(i * 1.6, 1000.0))
		for i in 3: _add("bat", _at(i * 2.1 + 0.5, 1100.0))
	else:
		Hud.banner("THE THIRD PHRASE", "Măiastre, burning gold, and the dead, and wolves with the rot in them.")
		for i in 3: _add("maiastra", _at(i * 2.1, 1050.0))
		_add("moroi", _at(0.7, 900.0)); _add("moroi", _at(3.8, 900.0))
		for i in 3: _add("wolf", _at(i * 2.1 + 1.0, 1000.0), true)
	Audio.sfx("iele_song", -10.0, 0.8 + 0.1 * w)

func _wave_check() -> void:
	for e in foes:
		if is_instance_valid(e) and e.hp > 0.0 and not e.fleeing and not e.fainted: return
	if wave == 0 or wave > 3 or phase > 0 or wave_delay > 0.0: return
	if wave < 3:
		wave_delay = 2.5
		Fx.text(ILIE_AT, "(the melody climbs)", Color(1, 0.85, 0.6), 90.0)
		return
	wave = 4; wave_delay = 3.0
	Hud.toast("Ilie: \"Now. Here they come.\"")

func _start_boss() -> void:
	phase = 1; calls = 0; call_t = 7.0; ribbon_t = 3.0; well_t = 4.0
	var reals := {}
	while reals.size() < 3: reals[rng.i(7)] = true
	for i in 7:
		var a := i * TAU / 7.0
		var s: IeleSister = spawn_enemy("iele_s", CENTRE + Vector2(cos(a), sin(a)) * 380.0, IeleSister)
		s.ring = self
		if reals.has(i): s.make_real()
		sisters.append(s)
	G.boss = self
	Audio.sfx("iele_song", -4.0)
	Hud.banner("THE SEVEN IELE", "Three of them are real. Hit the wrong one and she hits back.")

func line() -> String:
	if won: return "The ridge is quiet. Back down to Richiș."
	if not started: return "The clearing on the ridge. Ilie is waiting for you to be ready."
	if phase == 0:
		var n := 0
		for e in foes:
			if is_instance_valid(e) and e.hp > 0.0 and not e.fleeing: n += 1
		return "Ilie plays. Phrase %d/3 (%d left)." % [wave, n] if wave <= 3 else "Ilie plays on. Here they come."
	var dancing := 0
	for s in sisters:
		if is_instance_valid(s) and s.hp > 0.0: dancing += 1
	match phase:
		1: return "Seven Iele. Wait for Ilie's Doina; dodge the ribbons and the wells. (%d dancing)" % dancing
		2: return "Five left. They'll try to lift you. Wait for the Doina."
	return "Three, and all of them real. Their song drags you in."

func _process(dt: float) -> void:
	super(dt)
	if not is_instance_valid(G.player): return
	if not started and not won and G.state == G.State.PLAY and not G.transitioning:
		start_t += dt
		if start_t > 0.8: _begin()
	if G.state != G.State.PLAY or won: return
	time += dt
	if wave_delay > 0.0:
		wave_delay -= dt
		if wave_delay <= 0.0:
			if wave < 3: _start_wave(wave + 1)
			elif phase == 0: _start_boss()
	if phase == 0: return
	var pl: Player = G.player
	var pp := pl.pos
	# the ring turns; the circle shrinks as the illusions go
	var r: float = [380.0, 330.0, 260.0][phase - 1]; var w: float = [0.55, 0.75, 0.95][phase - 1]
	var alive := 0
	for s in sisters:
		if is_instance_valid(s) and s.hp > 0.0: alive += 1
	var k := 0
	for s in sisters:
		if not is_instance_valid(s) or s.hp <= 0.0: continue
		var a := time * w + k * TAU / maxi(1, alive); k += 1
		s.target = CENTRE + Vector2(cos(a), sin(a) * 0.75) * r
	# Ilie's calls
	call_t -= dt
	if call_t <= 0.0:
		if phase < 3 and calls % 3 == 2: _calus()
		else: _doina()
		calls += 1
		call_t = [7.0, 6.0, 5.0][phase - 1]
	if phase < 3:
		ribbon_t -= dt
		if ribbon_t <= 0.0:
			ribbon_t = 3.2 if phase == 1 else 2.6
			_ribbon()
	if phase == 1:
		well_t -= dt
		if well_t <= 0.0:
			well_t = 4.5
			var at := pp + Vector2.from_angle(randf() * TAU) * sqrt(randf()) * 160.0
			Fx.ring(at, Color(0.4, 0.5, 0.7, 0.8), 60.0, 0.8)
			wells.append({at = at, t = -0.8, tick = 0.0, decor = null})
	if phase == 2:
		lift_t -= dt
		if lift_t <= 0.0 and lift_anim <= 0.0:
			lift_t = 9.0; lift_anim = 1.3; lift_from = pp; pl.frozen = true
			Hud.toast("The Iele lift you in a whirlwind!")
			Audio.sfx("swing", -2.0, 0.4)
	if lift_anim > 0.0:
		lift_anim -= dt
		var u := 1.0 - lift_anim / 1.3
		var p := lift_from.lerp(CENTRE, u * 0.7) + Vector2(cos(u * 12.0), sin(u * 12.0)) * 90.0 * (1.0 - u)
		pl.pos = p
		if lift_anim <= 0.0:
			pl.frozen = false
			pl.hurt(8.0, Vector2.DOWN)
			Fx.ring(p, Color(0.85, 0.9, 1, 0.9), 80.0, 0.4)
	if phase == 3: pl.pull += (CENTRE - pp).normalized() * (40.0 if pl.wormwood else 80.0)
	_ribbons(dt, pl)
	_wells(dt, pl)

func _doina() -> void:
	var pp: Vector2 = G.player.pos
	var best: IeleSister = null; var bd := INF
	for s in sisters:
		if is_instance_valid(s) and s.real and s.hp > 0.0 and pp.distance_to(s.pos) < bd:
			bd = pp.distance_to(s.pos); best = s
	if best == null: return
	best.solid_t = 4.0 if phase == 3 else 4.5
	_shout("Doina! Now they're solid, strike!")
	Audio.sfx("bell", -16.0, 1.5)

func _calus() -> void:
	_shout("Căluș! Hold your ground!")
	Fx.ring(ILIE_AT, Color(1, 0.85, 0.5, 0.9), 260.0, 0.6)
	Audio.sfx("bell", -6.0, 1.1)
	Fx.shake(0.25)
	var pl: Player = G.player
	if pl.vel.length() > 60.0:
		pl.slow_t = maxf(pl.slow_t, 1.5)
		Fx.text(pl.pos, "(you stumble)", Fx.AMBER, 70.0)
	var n := 0
	for s in sisters:
		if not is_instance_valid(s) or s.real or s.hp <= 0.0 or n >= 2: continue
		n += 1
		s.hp = 0.0
		Fx.ring(s.pos, Color(0.85, 0.9, 1, 0.9), 90.0, 0.5)
		Fx.text(s.pos, "(she was never there)", Color(0.85, 0.85, 1), 60.0)
		Enemy.all.erase(s)
		get_tree().create_timer(0.1, false).timeout.connect(s.queue_free)
	phase = mini(3, phase + 1)
	if phase == 2:
		lift_t = 4.0
		Hud.banner("FIVE", "The ring tightens. The wind is in their skirts now.")
	elif phase == 3: Hud.banner("THREE", "Only the real ones are left. Listen to the song, and don't.")

func _shout(s: String) -> void:
	Fx.text(ILIE_AT, s, ILIE_COL, 100.0)
	Hud.toast("Ilie: \"%s\"" % s)

## A ribbon: a ring of white silk that spins out from one of the dancers.
func _ribbon() -> void:
	var live := sisters.filter(func(s): return is_instance_valid(s) and s.hp > 0.0)
	if live.is_empty(): return
	ribbons.append({from = live[rng.i(live.size())].pos, r = 0.0, hit = false, fx = 0.0})

func _ribbons(dt: float, pl: Player) -> void:
	for rb in ribbons.duplicate():
		rb.r += 440.0 * dt; rb.fx -= dt
		if rb.fx <= 0.0:
			rb.fx = 0.08
			Fx.ring(rb.from, Color(0.92, 0.94, 1, 0.55), rb.r, 0.12)
		if not rb.hit and pl.inv_t <= 0.0 and absf(pl.pos.distance_to(rb.from) - rb.r) < 26.0:
			rb.hit = true
			pl.hurt(9.0, (pl.pos - rb.from).normalized())
		if rb.r >= 700.0: ribbons.erase(rb)

## A well opens in the frost under the hunter's feet: a warning, then it pulls and bites.
func _wells(dt: float, pl: Player) -> void:
	for wl in wells.duplicate():
		wl.t += dt
		if wl.t < 0.0: continue
		if wl.decor == null: wl.decor = add_decor(wl.at, "well_hole")
		wl.tick -= dt
		if pl.pos.distance_to(wl.at) < 60.0:
			pl.slow_t = maxf(pl.slow_t, 0.3)
			if wl.tick <= 0.0:
				wl.tick = 0.5
				pl.hurt(5.0, Vector2.ZERO)
		if wl.t >= 5.0 or phase != 1:
			if is_instance_valid(wl.decor): remove_decor(wl.decor)
			wells.erase(wl)

func sister_down(_s: IeleSister) -> void:
	for s in sisters:
		if is_instance_valid(s) and s.real and s.hp > 0.0: return
	if won: return
	won = true
	G.boss = null
	G.player.frozen = false
	for s in sisters:
		if is_instance_valid(s): get_tree().create_timer(2.0, false).timeout.connect(s.queue_free)
	G.start_dialogue("The ridge", [
		"(The last of them stops. The nai stops. For a moment there is no sound on the ridge at all.)",
		"(Three young women in white stand in the frost, blinking, as if they'd just woken up.)",
		"— It's freezing. — It's OCTOBER. — Whose idea was this?",
		"(They pull their sleeves over their hands, and drift off into the trees, grumbling, to sleep until summer.)",
		"(Something old and rotten lets go of the ridge, like a hand opening. Far down the road, Biertan's tower is a black thumb against the dawn.)",
	], func():
		G.side_add("rc_iele")
		Hud.banner("THE RIDGE IS OPEN", "Ilie lowers the nai. Somewhere below, in Richiș, his brother sits up.")
		Loader.goto_level("richisvillage"))

func leave() -> void:
	if G.state != G.State.PLAY or G.transitioning: return
	if not won and started:
		Hud.toast("Ilie is still playing. You can't leave him here.")
		return
	Loader.goto_level("richisvillage", RcQuest.ridge_gate + Vector2(0, 200) if RcQuest.ridge_gate != Vector2.ZERO else null)
