class_name Balaur
extends Node2D
## The Balaur: a three-headed serpent coiled in the flooded quarry. It dies
## when all three necks are cut and seared.

signal died(b)

var heads: Array = []
var intro := true
var t := 0.0
var bat_t := 9.0
var arena
var main
var max_hp := 510.0
var hp := 510.0
var gaze_state := ""
var gaze_t := 9.0
var gt := 0.0
var gaze_a := 0.0
var gaze_dir := 1.0
var gaze_tick := 0.0
var devour_state := ""
var devour_t := 14.0
var dt_ := 0.0
var lane_x := 800.0
var lunge := 0.0
const GEM := Vector2(0, -70)


func build_heads() -> void:
	var offs := [Vector2(-130, 30), Vector2(0, 50), Vector2(130, 30)]
	var rests := [Vector2(-240, 250), Vector2(0, 290), Vector2(240, 250)]
	for i in 3:
		var h := BalaurHead.new()
		h.setup("balaur_head")
		h.body = self
		h.main = main
		h.anchor = global_position + offs[i]
		h.rest = global_position + rests[i]
		h.element = ["frost", "fire", "thirst"][i]
		h.position = h.rest
		get_parent().add_child(h)
		heads.append(h)


func hud_name() -> String:
	return "THE BALAUR"


func gazing() -> bool:
	return gaze_state != ""


func gem_pos() -> Vector2:
	return global_position + GEM


func hud_hint() -> String:
	if gaze_state != "":
		return "The stag's gaze! Hide behind a pillar!"
	if devour_state == "tel":
		return "It will devour the marked lane! Get out of it!"
	for h in heads:
		if h.hstate == "stump":
			return "Sear the stump (%s) before the head grows back!" % ("USE" if G.touch_mode else "E")
	return "Cut down a head, then sear its stump."


func vulnerable() -> bool:
	return true


func rage() -> float:
	var sealed := 0
	for h in heads:
		if h.sealed:
			sealed += 1
	return 1.0 + 0.3 * sealed


func fire_ring() -> void:
	var w := WaterWave.new()
	w.fire = true
	w.dmg = 18.0
	w.speed = 360.0
	w.position = global_position + Vector2(0, 60)
	get_parent().add_child(w)
	G.sfx("fire", 0.0, 0.6)


func head_sealed(_h) -> void:
	fire_ring()
	for h in heads:
		if not h.sealed:
			G.sfx("hiss", 0.0, 0.7)
			if arena != null:
				arena.on_head_sealed()
			return
	died.emit(self)
	G.sfx("boss_roar", 0.0, 0.7)
	G.fx_ring(get_parent(), global_position, Color(0.6, 1.0, 0.5, 0.9), 260, 1.0)
	set_physics_process(false)
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 2.0)
	for h in heads:
		h.queue_free()


func _physics_process(delta: float) -> void:
	t += delta
	if intro and t > 3.0:
		intro = false
	hp = 0.0
	for h in heads:
		if is_instance_valid(h) and not h.sealed:
			hp += h.hp
	if not intro:
		gaze_step(delta)
		devour_step(delta)
	if not intro and rage() > 1.0:
		bat_t -= delta
		if bat_t <= 0.0 and arena != null:
			bat_t = 10.0
			arena.call_bats()
	queue_redraw()


## Like a blasphemous serpent lord, the body surges out of the lake to devour
## whatever stands in its lane.
func devour_step(delta: float) -> void:
	var pl = main.player
	match devour_state:
		"":
			if gaze_state != "":
				return
			devour_t -= delta * rage()
			if devour_t <= 0.0:
				devour_state = "tel"
				dt_ = 0.0
				lane_x = clampf(pl.global_position.x, 250.0, 1350.0)
				G.sfx("hiss", 4.0, 0.5)
				main.toast("The Balaur rears back to devour!")
		"tel":
			dt_ += delta
			if dt_ > 1.1:
				devour_state = "surge"
				dt_ = 0.0
				G.sfx("boss_roar", 0.0, 0.8)
		"surge":
			dt_ += delta
			lunge = minf(1.0, dt_ / 0.25)
			var reach := global_position.y + 80.0 + 620.0 * lunge
			if absf(pl.global_position.x - lane_x) < 85.0 and pl.global_position.y < reach and pl.inv_t <= 0.0 and dt_ < 0.35:
				pl.hurt(42.0, Vector2.DOWN)
				main.toast("Devoured! It spits you out, scorched.")
			if dt_ > 0.8:
				devour_state = "back"
				dt_ = 0.0
		"back":
			dt_ += delta
			lunge = maxf(0.0, 1.0 - dt_ / 0.6)
			if dt_ > 0.6:
				devour_state = ""
				devour_t = 14.0
				lunge = 0.0


## The jewelled crown of the enchanted stag: its gaze kills. Hide behind stone.
func gaze_step(delta: float) -> void:
	var pl = main.player
	match gaze_state:
		"":
			gaze_t -= delta * rage()
			if gaze_t <= 0.0:
				gaze_state = "charge"
				gt = 0.0
				G.sfx("hiss", 2.0, 0.4)
				main.toast("Gems blaze on the Balaur's crown...")
		"charge":
			gt += delta
			gaze_a = (pl.global_position - gem_pos()).angle()
			if gt > 1.3:
				gaze_state = "beam"
				gt = 0.0
				gaze_dir = 1.0 if randf() < 0.5 else -1.0
				gaze_a -= gaze_dir * 0.35
				G.sfx("fire", 0.0, 0.5)
		"beam":
			gt += delta
			gaze_a += gaze_dir * 0.5 * delta
			gaze_tick -= delta
			if gaze_tick <= 0.0 and beam_hits(pl.global_position + Vector2(0, -14)):
				gaze_tick = 0.2
				pl.hurt(9.0, Vector2.from_angle(gaze_a))
			if gt > 1.6:
				gaze_state = ""
				gaze_t = 11.0


func beam_hits(p: Vector2) -> bool:
	var dir := Vector2.from_angle(gaze_a)
	var to := p - gem_pos()
	if to.dot(dir) < 0.0:
		return false
	if absf(to.cross(dir)) > 34.0:
		return false
	if arena != null:
		for r in arena.pillars:
			var steps := 24
			for i in steps:
				var q := gem_pos().lerp(p, float(i) / steps)
				if r.has_point(q):
					return false
	return true


func _draw() -> void:
	if devour_state == "tel":
		var lx := lane_x - global_position.x
		draw_rect(Rect2(lx - 85, 80, 170, 620), Color(1, 0.2, 0.1, 0.15 + 0.15 * sin(t * 20.0)))
		draw_rect(Rect2(lx - 85, 80, 170, 620), Color(1, 0.3, 0.1, 0.6), false, 3.0)
	if lunge > 0.0:
		var lx2 := lane_x - global_position.x
		var end := Vector2(lx2, 80.0 + 620.0 * lunge)
		draw_line(Vector2(0, 40), end, Color("0e1a12"), 120.0)
		draw_line(Vector2(0, 40), end, Color("2e4a30"), 104.0)
		draw_line(Vector2(0, 40), end, Color("c8b46a", 0.4), 20.0)
		draw_circle(end, 64, Color("2e4a30"))
		draw_circle(end + Vector2(-22, 10), 8, Color("ffcc3a"))
		draw_circle(end + Vector2(22, 10), 8, Color("ffcc3a"))
	for h in heads:
		if not is_instance_valid(h):
			continue
		var a: Vector2 = h.anchor - global_position
		var b: Vector2 = h.global_position - global_position
		if h.hstate in ["stump", "sealed"]:
			b = a + (b - a) * 0.9
		var mid: Vector2 = (a + b) / 2.0 + Vector2(sin(t * 1.4 + a.x) * 30.0, -60.0)
		var pts := PackedVector2Array()
		for i in 13:
			var k := i / 12.0
			pts.append(a.lerp(mid, k).lerp(mid.lerp(b, k), k))
		draw_polyline(pts, Color("0e1a12"), 34.0, true)
		draw_polyline(pts, Color("2e4a30"), 26.0, true)
		draw_polyline(pts, Color("c8b46a", 0.4), 6.0, true)
		for i in range(1, 12, 2):
			draw_circle(pts[i] + Vector2(0, -8), 3.0, Color("16261a"))
	var tex := G.tex("res://assets/sprites/balaur_body.svg")
	if tex != null:
		draw_texture_rect(tex, Rect2(-240, -150, 480, 360), false)
	# the stag's jewelled crown
	var glow := 0.3
	if gaze_state == "charge":
		glow = 0.4 + 0.6 * gt / 1.3
	elif gaze_state == "beam":
		glow = 1.0
	for i in 5:
		var gp := GEM + Vector2((i - 2) * 16.0, -absf(i - 2) * -6.0)
		draw_circle(gp, 6, Color(0.3, 1.0, 0.6, glow))
	draw_circle(GEM, 16 * glow, Color(0.5, 1.0, 0.7, 0.35 * glow))
	if gaze_state == "charge":
		draw_line(GEM, GEM + Vector2.from_angle(gaze_a) * 1200.0, Color(0.5, 1.0, 0.6, 0.25), 3.0)
	elif gaze_state == "beam":
		var end := GEM + Vector2.from_angle(gaze_a) * 1300.0
		draw_line(GEM, end, Color(0.4, 1.0, 0.6, 0.35), 60.0)
		draw_line(GEM, end, Color(0.85, 1.0, 0.9, 0.9), 12.0)
