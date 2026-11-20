## The hunter: movement, the blade, the dash, tinctures, the salt ring, and the curses three bosses lay on him
## (madness, vampirism, haste).
class_name Player
extends Actor

signal died

var hp := 100.0
var max_hp := 100.0
var stamina := 100.0
var max_stamina := 100.0
var sprint_exhausted := false
var speed := 205.0
var dmg := 12.0
var facing := Vector2.RIGHT
var attack_t := 0.0
var attack_cd := 0.0
var dodge_t := 0.0
var dodge_cd := 0.0
var dodge_dir := Vector2.RIGHT
var inv_t := 0.0
var hurt_flash := 0.0
var slow_t := 0.0
var walk_t := 0.0
var potions := 1
var coins := 20
var charm_dodge := false
var red_thread := false
var frozen := false
var god := false
var grabbed := false      # held by something big (the giant's apron): rooted, but no ice
var salt := 0
var salt_unlocked := false
var wormwood := false
var oak_heart := false
var garlic := false
var torch := false
var pull := Vector2.ZERO
var salt_cd := 0.0
var root_t := 0.0
var madness := 0.0        # Muma Pădurii: grows with every hit, tinctures don't touch it
var blood := 0.0          # Vlad: hits build the curse
var vamp_t := 0.0         # time left as a vampire
var haste_t := 0.0        # Magda's bandage
var gust_cd := 0.0        # Petrea's weather whistle
var drunk_t := 0.0        # Mălâncrav's flashbacks: steps drift, the camera sways, swings go wide
var no_trousers := false  # the morning after: every step comes out as a fart
var _step_t := 0.0
var _arc: MeshInstance3D
var _arc_mesh := ImmediateMesh.new()

func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	radius = 16.0
	set_body_radius(16.0)
	set_figure("hunter", 1.3)
	_arc = MeshInstance3D.new()
	_arc.mesh = _arc_mesh
	_arc.material_override = Fx._line_mat()
	_arc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_arc)

func reset_stats() -> void:
	max_hp = 100.0; hp = max_hp; dmg = 12.0; potions = 1; coins = 20
	charm_dodge = false; red_thread = false; frozen = false
	salt = 0; salt_unlocked = false; wormwood = false; oak_heart = false; garlic = false; torch = false
	madness = 0.0; blood = 0.0; vamp_t = 0.0; haste_t = 0.0; drunk_t = 0.0; no_trousers = false; stamina = max_stamina; sprint_exhausted = false

func _move_input() -> Vector2:
	var v := Vector2(Input.get_axis("move_left", "move_right"), Input.get_axis("move_up", "move_down"))
	v = v.rotated(-Fx.yaw)
	return v.normalized() if v.length_squared() > 1.0 else v

func mouse_world() -> Vector2:
	var cam := Fx.cam
	if cam == null: return pos
	var m := get_viewport().get_mouse_position()
	var o := cam.project_ray_origin(m); var d := cam.project_ray_normal(m)
	if absf(d.y) < 1e-4: return pos
	return Fx.to2(o + d * (-o.y / d.y))

func _physics_process(dt: float) -> void:
	var now := Time.get_ticks_msec() / 1000.0
	attack_cd = maxf(0.0, attack_cd - dt)
	dodge_cd = maxf(0.0, dodge_cd - dt)
	inv_t = maxf(0.0, inv_t - dt)
	attack_t = maxf(0.0, attack_t - dt)
	hurt_flash = maxf(0.0, hurt_flash - dt)
	slow_t = maxf(0.0, slow_t - dt)
	salt_cd = maxf(0.0, salt_cd - dt)
	root_t = maxf(0.0, root_t - dt)
	if vamp_t > 0.0:
		vamp_t = maxf(0.0, vamp_t - dt)
		if vamp_t <= 0.0: Hud.toast("The vampire blood fades. You are yourself again.")
	blood = maxf(0.0, blood - dt * 0.25)
	haste_t = maxf(0.0, haste_t - dt)
	gust_cd = maxf(0.0, gust_cd - dt)

	if root_t > 0.0 and hp > 0.0 and not frozen:
		vel = Vector2.ZERO
		slide()
		if Input.is_action_pressed("attack") and attack_cd <= 0.0: swing()
		return
	if frozen or hp <= 0.0:
		vel = vel.move_toward(Vector2.ZERO, 1800.0 * dt)
		slide()
		return

	var dir := _move_input()
	if drunk_t > 0.0:
		var a := sin(now * 1.3) * 0.75 + sin(now * 3.1) * 0.25
		if dir != Vector2.ZERO: dir = dir.rotated(a)
		else: dir = Vector2(sin(now * 0.8), cos(now * 1.1)) * 0.18   # he can't stand still
	if no_trousers and G.current == "malancrav" and dir.length_squared() > 0.1:   # bare legs in the October cold: now and then he shivers
		_step_t -= dt
		if _step_t <= 0.0:
			_step_t = randf_range(5.0, 9.0)
			Fx.text(pos + Vector2(0, -30), "brrr", Color(0.75, 0.85, 1.0), 20.0)

	var md := mouse_world() - pos
	if md.length() > 8.0: facing = md.normalized()
	if drunk_t > 0.0: facing = facing.rotated(deg_to_rad(sin(now * 2.3) * 55.0))   # swings go wide
	elif dir != Vector2.ZERO: facing = dir

	if dodge_t > 0.0:
		dodge_t -= dt
		vel = dodge_dir * (600.0 if charm_dodge else 540.0)
	else:
		var sprinting := Input.is_key_pressed(KEY_SHIFT) and dir != Vector2.ZERO and not sprint_exhausted and slow_t <= 0.0
		if sprinting:
			stamina -= 28.0 * dt
			if stamina <= 0.0:
				stamina = 0.0
				sprint_exhausted = true
		else:
			stamina = minf(max_stamina, stamina + 24.0 * dt)
			if sprint_exhausted and stamina >= 25.0: sprint_exhausted = false
		var sp := speed * (0.55 if slow_t > 0.0 else 1.0) * (1.25 if haste_t > 0.0 else 1.0) * (1.65 if sprinting else 1.0)
		vel = vel.move_toward(dir * sp + pull, 2800.0 * dt)
		pull = Vector2.ZERO
		if Input.is_action_just_pressed("dodge") and dodge_cd <= 0.0:
			dodge_dir = dir.normalized() if dir != Vector2.ZERO else facing
			dodge_t = 0.22
			inv_t = 0.32
			dodge_cd = 0.75 * (0.9 if charm_dodge else 1.0)
			Fx.ring(pos, Color(1, 1, 1, 0.5), 32.0)
			Audio.sfx("dodge", -6.0)
		if Input.is_action_pressed("attack") and attack_cd <= 0.0: swing()
		if Input.is_action_just_pressed("potion"): drink()
		if Input.is_action_just_pressed("salt"): throw_salt()
		if Input.is_action_just_pressed("gust") and G.side_has("rc_whistle"): gust()
		if Input.is_action_just_pressed("interact") and G.input_block <= 0.0:
			var near := Interact.nearest(pos)
			if near: near.interact()
	if dir != Vector2.ZERO: walk_t += dt * 9.0
	slide()

func _process(dt: float) -> void:
	if fig == null: return
	fig.set_figure(figure_name())
	var st := "move"
	if hp <= 0.0: st = "death"
	elif attack_t > 0.0: st = "attack"
	elif hurt_flash > 0.15: st = "hurt"
	fig.hurt = clampf((hurt_flash - 0.15) / 0.15, 0.0, 1.0)
	fig.alpha = 0.45 if (inv_t > 0.0 and int(inv_t * 30.0) % 2 == 0) else 1.0
	fig.tint_mul = Color(1.0, 0.75, 0.78) if vamp_t > 0.0 else (Color(0.75, 0.9, 1.15) if root_t > 0.0 and not grabbed else Color.WHITE)
	fig.tick(st, vel, facing, dt)
	_draw_arc()

## The hunter loses his hat to a spiriduș in the smoke-cellar, and his trousers in Mălâncrav.
func figure_name() -> String:
	if G.current == "malancrav" and G.side_has("ml_pantsless") and not G.side_has("ml_pants") and drunk_t <= 0.0: return "hunter_notrousers"
	return "hunter_nohat" if G.side_has("sig_hat_lost") and not G.side_has("sig_hat_back") else "hunter"

## The slash: a bright swoosh at waist height tracing the blade's real reach.
func _draw_arc() -> void:
	_arc_mesh.clear_surfaces()
	if attack_t <= 0.0: return
	var k := 1.0 - attack_t / 0.18
	var a0 := -facing.angle() + 1.2 - 2.4 * k
	var n := 10
	_arc_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	for i in n:
		var u := i / float(n - 1)
		var a := a0 + 0.9 * u
		var w := (lerpf(0.05, 1.0, u / 0.75) if u < 0.75 else lerpf(1.0, 0.3, (u - 0.75) / 0.25)) * 0.17
		var alpha := lerpf(0.0, 0.55, u / 0.6) if u < 0.6 else lerpf(0.55, 0.95, (u - 0.6) / 0.4)
		var d := Vector3(cos(a), 0, -sin(a))
		_arc_mesh.surface_set_color(Color(1, 0.97, 0.9, alpha))
		_arc_mesh.surface_add_vertex(d * (62.0 * Fx.S - w) + Vector3(0, 0.55, 0))
		_arc_mesh.surface_set_color(Color(1, 0.97, 0.9, alpha))
		_arc_mesh.surface_add_vertex(d * (62.0 * Fx.S + w) + Vector3(0, 0.55, 0))
	_arc_mesh.surface_end()

## Petrea's whistle: a gust that throws everything near the hunter back. It has to rest after.
func gust() -> void:
	if gust_cd > 0.0:
		Fx.text(pos, "(the whistle is resting)", Fx.AMBER, 70.0)
		return
	gust_cd = 14.0
	Audio.sfx("swing", -2.0, 0.35)
	Fx.ring(pos, Color(0.8, 0.88, 1.0, 0.9), 320.0, 0.5)
	for e in Enemy.all.duplicate():
		var to: Vector2 = e.pos - pos
		if to.length() < 340.0: e.shove(to.normalized() * 900.0)

var voice_n := 0       # counts swings: the hunter grunts on every third
var unarmed := false   # the blade stays in his belt (herding cows on the stână)

func swing() -> void:
	if unarmed: return
	Audio.sfx("swing", -9.0)
	voice_n += 1
	if voice_n % 3 == 0: Audio.sfx("hunter_attack", -4.0)
	attack_t = 0.18
	attack_cd = 0.36
	var reach := 82.0
	for e in Enemy.all.duplicate():   # a copy: a blow may kill and remove
		if not is_instance_valid(e): continue
		var to: Vector2 = e.pos - pos
		var close: bool = to.length() < e.radius + 26.0
		if to.length() < reach + e.radius and (close or absf(rad_to_deg(facing.angle_to(to))) < 72.0):
			var hit_dir := to.normalized() if to.length() > 1.0 else facing
			var at: Vector2 = e.pos - hit_dir * e.radius * 0.5
			e.hurt(dmg, hit_dir)
			if vamp_t > 0.0: hp = minf(max_hp, hp + 3.0)
			Fx.spark(at, hit_dir)
			if not is_instance_valid(e) or e.hp <= 0.0:
				Fx.shake(0.12); Fx.hit_stop(0.07)
			else: Fx.shake(0.05)

func drink() -> void:
	if potions > 0 and vamp_t > 0.0:
		potions -= 1
		hp = maxf(1.0, hp - 30.0)
		hurt_flash = 0.3
		Audio.sfx("sear", -2.0)
		Fx.text(pos, "-30  garlic burns!", Color("ff6a5a"))
		return
	if potions > 0 and hp < max_hp:
		potions -= 1
		hp = minf(max_hp, hp + 45.0)
		Audio.sfx("potion", -3.0)
		Fx.text(pos, "+45", Color("7bd36a"))
		Fx.ring(pos, Color("7bd36a"), 40.0)

func throw_salt() -> void:
	if not salt_unlocked or salt_cd > 0.0: return
	if salt <= 0:
		Hud.toast("Your salt pouch is empty.")
		return
	salt -= 1
	salt_cd = 1.0
	SaltRing.throw_at(pos)
	Audio.sfx("salt", -3.0)

func hurt(amount: float, dir: Vector2) -> void:
	if inv_t > 0.0 or hp <= 0.0 or god: return
	hp -= amount
	inv_t = 0.55
	Fx.shake(clampf(amount * 0.012, 0.06, 0.2))
	if G.current == "hollow":
		madness += amount
		if madness >= max_hp * 2.0:
			madness = max_hp * 2.0
			Hud.toast("Your mind is lost in the wood.")
			hp = 0.0
	if G.current == "church" and vamp_t <= 0.0:
		blood += 0.5 if garlic else 1.0
		if blood >= 5.0:
			blood = 0.0
			vamp_t = 18.0
			Audio.sfx("laugh", 0.0, 1.2)
			Hud.banner("VAMPIRISM", "His blood is in you. Tinctures burn, but your strikes drink.")
	hurt_flash = 0.25
	vel = dir * 320.0
	Audio.sfx("hurt", -2.0)
	Audio.sfx("hunter_down" if hp <= 0.0 else "hunter_hurt", -3.0)
	Fx.text(pos, str(roundi(amount)), Color("ff6a5a"))
	if hp <= 0.0:
		hp = 0.0
		died.emit()
