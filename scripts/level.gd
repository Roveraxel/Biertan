class_name Level
extends Node2D
## Base class for an area. Subclasses override build().

var main
var size := Vector2(2000, 1200)
var spawn := Vector2(200, 200)
var ground := Color("2b3a26")
var rng := RandomNumberGenerator.new()
var details: Array = []
var title := ""
var tile_path := "res://assets/tiles/grass.svg"
var tile_tint := Color.WHITE
var subtitle := ""


func _init() -> void:
	y_sort_enabled = true


func build() -> void:
	pass


func ambient() -> Color:
	return G.ambient(G.dusk)


func add_block(rect: Rect2, style := "wall", h := 18.0) -> Block:
	var b := Block.new()
	b.setup(rect, style, h)
	add_child(b)
	return b


func add_tree(p: Vector2, pine := false) -> void:
	var t := Tree2D.new()
	t.position = p
	t.seed_v = rng.randi()
	t.pine = pine
	add_child(t)


func add_trigger(rect: Rect2, cb: Callable) -> Area2D:
	var a := Area2D.new()
	a.collision_layer = 0
	a.collision_mask = 2
	a.position = rect.get_center()
	var cs := CollisionShape2D.new()
	var s := RectangleShape2D.new()
	s.size = rect.size
	cs.shape = s
	a.add_child(cs)
	a.body_entered.connect(_on_trigger.bind(cb))
	add_child(a)
	return a


func _on_trigger(body: Node, cb: Callable) -> void:
	if body is Player:
		cb.call()


func add_torch(p: Vector2, radius := 240.0, col := Color(1.0, 0.68, 0.34), energy := 1.1) -> void:
	var l := FlickerLight.new()
	l.texture = G.light_tex()
	l.texture_scale = radius / 128.0
	l.color = col
	l.base = energy
	l.position = p
	add_child(l)


func add_prop(kind: String, id: String, display: String, p: Vector2, col := Color("a05030"), prompt := "") -> Prop:
	var pr := Prop.new()
	pr.main = main
	pr.kind = kind
	pr.id = id
	pr.display = display
	pr.col = col
	pr.prompt = prompt
	pr.position = p
	add_child(pr)
	return pr


func add_brazier(p: Vector2, lit := true) -> Brazier:
	var b := Brazier.new()
	b.lit = lit
	b.position = p
	add_child(b)
	return b


func spawn_enemy(kind: String, p: Vector2) -> Enemy:
	var e := Enemy.new()
	e.setup(kind)
	if main != null:
		var k: Vector2 = main.difficulty()
		e.hp *= k.x
		e.max_hp = e.hp
		e.dmg *= k.y
	e.position = p
	add_child(e)
	return e


func scatter(r: Rect2, n: int, cols: Array, kinds := [0, 1, 2]) -> void:
	for i in n:
		details.append([
			Vector2(rng.randf_range(r.position.x, r.end.x), rng.randf_range(r.position.y, r.end.y)),
			kinds[rng.randi() % kinds.size()],
			cols[rng.randi() % cols.size()],
			rng.randf_range(0.7, 1.4),
		])


func draw_ground() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), ground)
	var gt := G.tex(tile_path) if tile_path != "" else null
	if gt != null:
		draw_texture_rect(gt, Rect2(Vector2.ZERO, size), true, tile_tint)


func _draw() -> void:
	draw_ground()
	for d in details:
		var p: Vector2 = d[0]
		var k: int = d[1]
		var c: Color = d[2]
		var s: float = d[3]
		match k:
			0:
				draw_line(p, p + Vector2(-3, -8) * s, c, 1.5)
				draw_line(p, p + Vector2(0, -10) * s, c, 1.5)
				draw_line(p, p + Vector2(3, -7) * s, c, 1.5)
			1:
				draw_circle(p, 3.0 * s, c)
			2:
				draw_colored_polygon(PackedVector2Array([p, p + Vector2(6, -3) * s, p + Vector2(9, 2) * s, p + Vector2(2, 4) * s]), c)
