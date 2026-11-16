## Anything that walks the map: the hunter, creatures, bosses. Logic is in map pixels (see Fx).
class_name Actor
extends CharacterBody3D

var vel := Vector2.ZERO        # pixels a second
var radius := 14.0
var touching_wall := false
var fig: PixelFigure
var _shape: CollisionShape3D

var pos: Vector2:
	get: return Vector2(position.x, position.z) / Fx.S
	set(v): position = Fx.to3(v)

func _init() -> void:
	motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
	axis_lock_linear_y = true
	wall_min_slide_angle = 0.0
	_shape = CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.height = 2.0
	cyl.radius = 0.25
	_shape.shape = cyl
	_shape.position.y = 1.0
	add_child(_shape)

func set_body_radius(r: float) -> void:
	(_shape.shape as CylinderShape3D).radius = r * Fx.S

func set_solid(on: bool) -> void:
	_shape.disabled = not on

## Move by `vel`, sliding along whatever is solid; `vel` comes back as what was really covered.
func slide() -> void:
	velocity = Vector3(vel.x, 0.0, vel.y) * Fx.S
	move_and_slide()
	position.y = 0.0
	touching_wall = get_slide_collision_count() > 0
	vel = Vector2(velocity.x, velocity.z) / Fx.S

func set_figure(names, h: float) -> void:
	if fig: fig.queue_free()
	fig = PixelFigure.make(names, h)
	if fig: add_child(fig)
