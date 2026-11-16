## A ham on a chain swinging across the smokehouse: an obstacle to time, not to fight. Walk into it and it
## knocks the hunter aside and hurts a little.
class_name SwingingHook
extends Decor

var anchor := Vector2.ZERO
var reach := 150.0
var period := 2.4
var phase := 0.0
var along_x := true
var hit_cd := 0.0
var t := 0.0

func _process(dt: float) -> void:
	super(dt)
	t += dt
	hit_cd = maxf(0.0, hit_cd - dt)
	var axis := Vector2.RIGHT if along_x else Vector2.UP
	var w := (t + phase) * TAU / period
	pos = anchor + axis * sin(w) * reach
	if hit_cd > 0.0 or G.state != G.State.PLAY or not is_instance_valid(G.player): return
	if G.player.pos.distance_to(pos) < 30.0:
		hit_cd = 1.2
		G.player.hurt(4.0, axis * signf(cos(w)))   # knocked sideways, the way the ham is swinging
		Audio.sfx_at("blip", pos, -6.0, 0.5)
