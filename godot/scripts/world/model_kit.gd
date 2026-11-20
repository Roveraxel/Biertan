## Buildings shaped from Meshy models (res://models/<name>.glb) but dressed like everything else in the game:
## each face is sorted by its slope into roof or wall and gets the village's own pixel textures, mapped in
## metres; faces are turned outward and flat-shaded; the ground the model was made standing on is cut away.
## A model is converted once and shared by every building that uses it.
class_name ModelKit
extends RefCounted

## How long the model's long side is in life, in metres: sets how big the textures are on it.
const NOMINAL := {"church": 26.0, "basilica": 28.0, "chapel": 12.0, "orthodox": 14.0, "reformed": 16.0,
	"tower": 7.0, "clocktower": 9.0, "house": 11.0, "inn": 16.0, "portal_wall": 8.0, "barn": 13.0, "hatch": 3.0,
	"bench": 2.2, "fence": 3.5, "bridge": 3.0, "stork": 7.5}

static var _shapes := {}

static func exists(name: String) -> bool:
	return ResourceLoader.exists("res://models/%s.glb" % name)

static func _nominal(name: String) -> float:
	for k in NOMINAL:
		if name.contains(k): return NOMINAL[k]
	return 10.0

## The converted model: {mesh (surface 0 roof, 1 wall), size (metres-free model units, base at y 0, centred),
## tip (horizontal direction of its tallest point from the middle: where a church's tower stands)}.
static func shape(name: String) -> Dictionary:
	if _shapes.has(name): return _shapes[name]
	var src: Node3D = load("res://models/%s.glb" % name).instantiate()
	var tris := PackedVector3Array()
	var wtris := PackedVector3Array()   # parts of the model named "wood_*": doors and shutters, drawn in timber
	for mi in src.find_children("*", "MeshInstance3D", true, false):
		var xf := _local_xf(src, mi)
		var dst := wtris if String(mi.name).begins_with("wood") else tris
		for si in mi.mesh.get_surface_count():
			var arr: Array = mi.mesh.surface_get_arrays(si)
			var vs: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
			var idx = arr[Mesh.ARRAY_INDEX]
			if idx == null or idx.is_empty():
				for v in vs: dst.append(xf * v)
			else:
				for i in idx: dst.append(xf * vs[i])
	src.free()
	var box := AABB(tris[0], Vector3.ZERO)
	var top := tris[0]
	for v in tris:
		box = box.expand(v)
		if v.y > top.y: top = v
	for v in wtris: box = box.expand(v)
	var c := box.get_center()
	const NO_GROUND_MODELS := ["house_town_2story", "house_saxon_halfhip", "inn_2story", "portal_wall_arched",
		"apold_church", "street_bench_wood", "fence_post_rail", "culvert_bridge", "stork_nest_pole"]
	var cut := box.position.y + (0.002 if name in NO_GROUND_MODELS else box.size.y * 0.06)   # the patch of ground, base or low wall it was modelled on
	var H := box.position.y + box.size.y - cut
	var uv_k := _nominal(name) / maxf(box.size.x, box.size.z)   # model units to metres, for the textures
	var roof := SurfaceTool.new(); roof.begin(Mesh.PRIMITIVE_TRIANGLES)
	var wall := SurfaceTool.new(); wall.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(0, tris.size() - 2, 3):
		if tris[i].y < cut and tris[i + 1].y < cut and tris[i + 2].y < cut: continue
		var pts: Array[Vector3] = []
		for v in [tris[i], tris[i + 1], tris[i + 2]]: pts.append(Vector3(v.x - c.x, maxf(v.y - cut, 0.0), v.z - c.z))
		var n := (pts[1] - pts[0]).cross(pts[2] - pts[0])
		if n.length_squared() < 1e-12: continue
		n = n.normalized()
		# Meshy's winding is not consistent: turn every face outward (walls away from the middle, roofs up)
		var mid: Vector3 = (pts[0] + pts[1] + pts[2]) / 3.0
		var flip_w := false
		if absf(n.y) < 0.3:
			if n.dot(Vector3(mid.x, 0, mid.z)) < 0.0:
				n = -n
				flip_w = true
		elif n.y < 0.0:
			n = -n
			flip_w = true
		if flip_w:
			var tmp := pts[1]; pts[1] = pts[2]; pts[2] = tmp
		var hi := maxf(pts[0].y, maxf(pts[1].y, pts[2].y))
		var st := roof if (n.y > 0.3 or (n.y > 0.08 and hi > H * 0.55)) else wall
		var an := n.abs()
		for p in [pts[0], pts[2], pts[1]]:
			var q: Vector3 = p * uv_k
			var uv := Vector2(q.x, q.z) if (an.y >= an.x and an.y >= an.z) else (Vector2(q.z, -q.y) if an.x >= an.z else Vector2(q.x, -q.y))
			var yn := clampf(p.y / maxf(H, 0.01), 0.0, 1.0)
			if st == wall:
				var plinth := smoothstep(0.08, 0.16, yn)
				var ao := lerpf(0.36, 1.0, plinth) * lerpf(1.0, 0.90, smoothstep(0.55, 0.95, yn))
				st.set_color(Color(ao, ao * 0.99, ao * 0.97))
			else:
				var shade := lerpf(0.90, 1.04, smoothstep(0.3, 1.0, yn))
				st.set_color(Color(shade, shade, shade))
			st.set_normal(n); st.set_uv(uv); st.add_vertex(p)
	var wood := SurfaceTool.new(); wood.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(0, wtris.size() - 2, 3):
		var wp: Array[Vector3] = []
		for v in [wtris[i], wtris[i + 1], wtris[i + 2]]: wp.append(Vector3(v.x - c.x, maxf(v.y - cut, 0.0), v.z - c.z))
		var wn := (wp[1] - wp[0]).cross(wp[2] - wp[0])
		if wn.length_squared() < 1e-12: continue
		wn = wn.normalized()
		var wm: Vector3 = (wp[0] + wp[1] + wp[2]) / 3.0
		var wflip := false
		if absf(wn.y) < 0.3:
			if wn.dot(Vector3(wm.x, 0, wm.z)) < 0.0: wn = -wn; wflip = true
		elif wn.y < 0.0: wn = -wn; wflip = true
		if wflip:
			var wt := wp[1]; wp[1] = wp[2]; wp[2] = wt
		var wa := wn.abs()
		for p in [wp[0], wp[2], wp[1]]:
			var q: Vector3 = p * uv_k
			var uv := Vector2(q.x, q.z) if (wa.y >= wa.x and wa.y >= wa.z) else (Vector2(q.z, -q.y) if wa.x >= wa.z else Vector2(q.x, -q.y))
			wood.set_normal(wn); wood.set_uv(uv); wood.add_vertex(p)
	var mesh := ArrayMesh.new()
	roof.commit(mesh)
	if mesh.get_surface_count() == 0:   # keep the surface order: 0 roof, 1 wall
		var empty := SurfaceTool.new(); empty.begin(Mesh.PRIMITIVE_TRIANGLES)
		for k in 3: empty.set_normal(Vector3.UP); empty.add_vertex(Vector3.ZERO)
		empty.commit(mesh)
	wall.commit(mesh)
	if not wtris.is_empty(): wood.commit(mesh)   # surface 2: timber
	var size := Vector3(box.size.x, H, box.size.z)
	var tip := Vector3(top.x - c.x, 0, top.z - c.z)
	_shapes[name] = {"mesh": mesh, "size": size, "tip": tip}
	return _shapes[name]

## Stand a model on a block's footprint (block-local frame in game space: x across [-w/2, w/2], z along [0, -d]).
## fit "both" stretches it to the footprint; "long" keeps its proportions to the long side (churches).
## height in metres (the long-fit cap for churches). tip_to: a block-local direction its tallest part should
## face (a church tower to the west), or ZERO.
static func place(level: Node3D, base: Transform3D, w: float, d: float, name: String, roof_mat: Material, wall_mat: Material,
		height: float, fit := "both", tip_to := Vector3.ZERO) -> MeshInstance3D:
	var s := shape(name)
	var size: Vector3 = s.size
	var model_long_x := size.x >= size.z
	var foot_long_x := w >= d
	var yaw := 0.0 if model_long_x == foot_long_x else PI / 2.0
	var along := maxf(w, d); var across := minf(w, d)
	var m_along := maxf(size.x, size.z); var m_across := minf(size.x, size.z)
	var k_along := along / m_along
	var k_across := across / m_across if fit == "both" else k_along
	var ky := height / size.y if fit == "both" else minf(k_along, height / size.y)
	# scale in the model's own axes before turning it
	var sc := Vector3(k_along, ky, k_across) if model_long_x else Vector3(k_across, ky, k_along)
	if tip_to != Vector3.ZERO and s.tip.length() > 0.001:
		var tip_after: Vector3 = Basis(Vector3.UP, yaw) * s.tip
		if tip_after.dot(tip_to) < 0.0: yaw += PI
	var node := MeshInstance3D.new()
	node.mesh = s.mesh
	node.set_surface_override_material(0, roof_mat)
	node.set_surface_override_material(1, wall_mat)
	var bases: Array = [roof_mat, wall_mat]
	if s.mesh.get_surface_count() > 2:
		var wood_mat := Mats.mat("px_planks", 1.1, Color(1.0, 0.8, 0.6), 0.04)
		node.set_surface_override_material(2, wood_mat)
		bases.append(wood_mat)
	level.add_child(node)
	node.transform = base * Transform3D(Basis(Vector3.UP, yaw) * Basis.from_scale(sc), Vector3(0, -0.04, -d / 2.0))
	# the many small faces flicker in the moon's shadow map as the camera moves: the model takes no part in
	# shadows, and a plain box the size of its body casts the house's shadow instead
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var caster := MeshInstance3D.new()
	var ch := minf(height * 0.46, 3.4)
	var bm := BoxMesh.new(); bm.size = Vector3(w * 0.82, ch, d * 0.82)
	caster.mesh = bm
	caster.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
	level.add_child(caster)
	caster.transform = base * Transform3D(Basis.IDENTITY, Vector3(0, ch * 0.5, -d / 2.0))
	var g: AABB = node.global_transform * node.get_aabb()
	level.cutaways.append({"node": node, "centre": g.get_center(), "half_w": g.size.x / 2.0, "half_d": g.size.z / 2.0,
		"faded": false, "base": bases, "caster": caster})
	return node

static func _local_xf(root: Node3D, n: Node3D) -> Transform3D:
	var xf := n.transform
	var p := n.get_parent()
	while p and p != root:
		if p is Node3D: xf = p.transform * xf
		p = p.get_parent()
	return xf
