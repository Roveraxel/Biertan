## The Bull of Șapartoc, a vain Limousin who comes thundering over when the hunter hits one of his cows. He
## paws the ground and charges in a straight line (run him into a tree and he is dazed), stomps when crowded,
## and stops to flex. He is wide open while dazed or posing. Beaten, he sits down; he is not killed.
class_name Bull
extends Enemy

signal beaten

const LINES := ["Mooo-hoo-hoo. You hit a lady? On MY hill?", "Look at these shoulders. Go on. Look.", "Hmm-hmm-HMM. Still got it.",
	"Flex... and flex... and the other side.", "This quiff took me all morning.", "Nobody touches the herd. Nobody.", "Do you even plough, little man?"]

var bstate := "intro"
var bt := 0.0
var charge_dir := Vector2.ZERO
var pose_t := 5.0
var stomp_cd := 0.0
var done := false

func hud_name() -> String: return "THE BULL OF ȘAPARTOC"
func hud_hint() -> String:
	if bstate in ["dazed", "pose"]: return "He's wide open. Hit him now!"
	return "He's pawing the ground. Get out of his line!" if bstate == "windup" else ""

func setup(_k: String) -> void:
	kind = "bull"
	hp = 420.0; max_hp = 420.0
	speed = 120.0; dmg = 22.0; radius = 30.0; coin = 60; aggro = 99999.0
	heavy = true
	_make_figure()
	set_body_radius(radius * 0.9)
	G.boss = self
	Audio.sfx("boss_roar", -2.0, 0.55)
	Hud.banner("THE BULL OF ȘAPARTOC", "You hit one of his cows. He has noticed.")

func _say(line: String) -> void:
	Fx.text(pos, line, Fx.AMBER, 110.0)
	Audio.sfx_at("boss_roar", pos, -8.0, randf_range(0.45, 0.6))

func step(dt: float, to: Vector2, d: float, mult: float) -> bool:
	if done:
		vel = Vector2.ZERO
		return true
	bt += dt; stomp_cd -= dt; pose_t -= dt
	var dir := to.normalized()
	match bstate:
		"intro":
			vel = dir * speed * 1.6   # thundering in from the far pasture
			face = dir
			if d < 650.0 or bt > 4.0:
				_say(LINES[0]); bstate = "windup"; bt = 0.0
		"walk":
			face = dir
			vel = dir * speed * mult + knock + separation()
			if d < 170.0 and stomp_cd <= 0.0:
				bstate = "stomp"; bt = 0.0
			elif pose_t <= 0.0 and d > 260.0:
				bstate = "pose"; bt = 0.0
				_say(LINES[randi_range(1, LINES.size() - 1)])
			elif bt > 1.4 and d > 280.0:
				bstate = "windup"; bt = 0.0
		"windup":   # paws the ground, head down, snorting
			vel = Vector2.ZERO; face = dir; charge_dir = dir
			if bt > 0.75:
				bstate = "charge"; bt = 0.0; hit_done = false; strike_t = 0.6
				Audio.sfx("boss_roar", -4.0, 0.7)
		"charge":
			vel = charge_dir * 640.0
			if not hit_done and d < radius + 34.0:
				player.hurt(dmg * mult, charge_dir)
				hit_done = true
				player.vel = charge_dir * 600.0
			if touching_wall:
				bstate = "dazed"; bt = 0.0
				_say("...ow. My quiff.")
				Fx.ring(pos, Color(0.9, 0.85, 0.6), 120.0, 0.5)
				Fx.shake(0.15)
			elif bt > 1.3:
				bstate = "walk"; bt = 0.0
		"dazed":
			vel = Vector2.ZERO
			if bt > 1.8:
				bstate = "walk"; bt = 0.0
		"stomp":
			vel = Vector2.ZERO; face = dir
			if bt > 0.55 and not hit_done:
				hit_done = true; strike_t = 0.5
				Fx.ring(pos, Color(0.7, 0.55, 0.35, 0.9), 190.0, 0.45)
				Audio.sfx_at("hit", pos, -2.0, 0.4)
				if d < 190.0: player.hurt(14.0 * mult, dir)
			if bt > 1.0:
				bstate = "walk"; bt = 0.0; hit_done = false; stomp_cd = 2.2
		"pose":   # flexing for nobody in particular
			vel = Vector2.ZERO
			if bt > 1.6:
				bstate = "windup"; bt = 0.0; pose_t = randf_range(5.0, 8.0)
	knock = knock.move_toward(Vector2.ZERO, 900.0 * dt)
	return true

func hurt(amount: float, dir: Vector2) -> void:
	if done: return
	if bstate in ["dazed", "pose"]: amount *= 2.0
	elif bstate == "charge": amount *= 0.4
	hp -= amount; flash = 0.12
	knock = dir * 60.0   # he barely moves
	Audio.sfx("hit", -6.0, 0.6)
	Fx.text(pos, str(roundi(amount)), Color("ffe08a"))
	if bstate == "intro":
		bstate = "walk"; bt = 0.0
	if hp <= 0.0: die()

func die() -> void:
	if done: return
	done = true; hp = 0.0; bstate = "beaten"
	vel = Vector2.ZERO
	_pay()
	if G.boss == self: G.boss = null
	Hud.banner("THE BULL SITS DOWN", "He combs his quiff with one hoof, gives you a long look, and decides you can stay.")
	_say("Fine. FINE. But stay away from the ladies.")
	beaten.emit()
	died.emit(self)
	set_solid(false)
	fainted = true
	all.erase(self)
	fainted_ones.append(self)
	get_tree().create_timer(6.0, false).timeout.connect(queue_free)

func anim_state() -> String:
	if bstate == "charge" and fig.has_clip("charge"): return "charge"
	return super()
