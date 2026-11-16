## Burning ground (fire skulls, the Balaur's fire head), rime (its frost head), Muma's brew, or the bear's bees.
class_name FirePatch
extends Node3D

const R := 38.0
var mode := "fire"   # fire, frost, brew, bees
var life := 2.6
var t := 0.0
var tick := 0.0
var _mat: StandardMaterial3D

static func spawn(at: Vector2, patch_mode := "fire") -> FirePatch:
	var p := FirePatch.new()
	p.mode = patch_mode
	p.life = {"fire": 2.6, "frost": 3.4, "brew": 3.0, "bees": 4.0}[patch_mode]
	Fx.root().add_child(p)
	p.position = Fx.to3(at, 0.03)
	p._mat = Mats.unlit(Color.WHITE, Fx.circle_tex()).duplicate()
	var mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(R * 2.0, R * 2.0) * Fx.S
	mi.mesh = pm
	mi.material_override = p._mat
	p.add_child(mi)
	return p

func _physics_process(dt: float) -> void:
	t += dt; life -= dt; tick -= dt
	if life <= 0.0:
		queue_free()
		return
	var pl: Player = G.player
	var here := Fx.to2(position)
	if is_instance_valid(pl) and pl.pos.distance_to(here) < R:
		match mode:
			"bees":
				if tick <= 0.0:
					tick = 0.4; pl.hurt(5.0, Vector2.ZERO)
			"brew":
				pl.slow_t = maxf(pl.slow_t, 0.2)
				if tick <= 0.0:
					tick = 0.5; pl.hurt(6.0, Vector2.ZERO)
			"frost":
				pl.slow_t = maxf(pl.slow_t, 0.25)
				if tick <= 0.0:
					tick = 0.6; pl.hurt(4.0, Vector2.ZERO)
			_:
				if tick <= 0.0:
					tick = 0.5; pl.hurt(9.0, (pl.pos - here).normalized())
	var c := Color(1, 0.45 + 0.1 * sin(t * 12.0), 0.1, 0.6)
	match mode:
		"bees": c = Color(0.6, 0.45, 0.1, 0.25)
		"brew": c = Color(0.25, 0.45, 0.1, 0.6)
		"frost": c = Color(0.7, 0.85, 1, 0.55)
	c.a *= clampf(life, 0.0, 1.0)
	_mat.albedo_color = c
