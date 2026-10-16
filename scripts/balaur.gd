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
var max_hp := 390.0
var hp := 390.0


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
		h.fire_head = i == 1
		h.position = h.rest
		get_parent().add_child(h)
		heads.append(h)


func hud_name() -> String:
	return "THE BALAUR"


func hud_hint() -> String:
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


func head_sealed(_h) -> void:
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
	if not intro and rage() > 1.0:
		bat_t -= delta
		if bat_t <= 0.0 and arena != null:
			bat_t = 10.0
			arena.call_bats()
	queue_redraw()


func _draw() -> void:
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
