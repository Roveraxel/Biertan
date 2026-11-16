## Things lying on the ground that act on whoever stands in them: a ring of thrown salt, and patches of fire,
## rime, Muma's brew or the bear's bees.
class_name SaltRing
extends Node3D

const RADIUS := 120.0
static var all: Array[SaltRing] = []

var life := 6.0
var t := 0.0
var _disc: StandardMaterial3D
var _edge: StandardMaterial3D

var pos: Vector2:
	get: return Vector2(position.x, position.z) / Fx.S

static func throw_at(at: Vector2) -> SaltRing:
	var r := SaltRing.new()
	Fx.root().add_child(r)
	r.position = Fx.to3(at, 0.03)
	r._build()
	Fx.ring(at, Color(1, 1, 1, 0.8), RADIUS, 0.4)
	return r

func _enter_tree() -> void: all.append(self)
func _exit_tree() -> void: all.erase(self)

func _build() -> void:
	var rr := RADIUS * Fx.S
	_disc = Mats.unlit(Color(0.9, 0.92, 1, 0.08)).duplicate()
	_edge = Mats.unlit(Color(0.95, 0.96, 1, 0.3)).duplicate()
	var b := Batch.new()
	b.mb(_disc).disc(Vector3.ZERO, rr, rr, 0.0, 40)
	b.mb(_edge).ring(Vector3(0, 0.01, 0), rr - 0.06, rr + 0.06, 64)
	b.commit(self, "Salt", false)

func contains(p: Vector2, extra := 0.0) -> bool:
	return p.distance_to(pos) < RADIUS + extra

func _physics_process(dt: float) -> void:
	t += dt
	life -= dt
	if life <= 0.0:
		queue_free()
		return
	for e in Enemy.all.duplicate():
		if is_instance_valid(e) and e.undead() and contains(e.pos, e.radius): e.salt_hit(pos, dt)
	var a := clampf(life, 0.0, 1.0)
	_disc.albedo_color.a = 0.08 * a
	_edge.albedo_color.a = (0.3 + 0.1 * sin(t * 6.0)) * a
