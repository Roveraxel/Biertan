## Several MeshBuilders, one per material, turned into a single MeshInstance3D with a surface each.
class_name Batch
extends RefCounted

var xf := Transform3D.IDENTITY:
	set(v):
		xf = v
		for b in _b.values(): b.xf = v
var _b := {}   # Material -> MeshBuilder

func mb(m: Material) -> MeshBuilder:
	if not _b.has(m):
		var b := MeshBuilder.new()
		b.xf = xf
		_b[m] = b
	return _b[m]

func empty() -> bool:
	for b in _b.values():
		if not b.empty(): return false
	return true

func commit(parent: Node, node_name := "Mesh", shadows := true) -> MeshInstance3D:
	if empty(): return null
	var mesh := ArrayMesh.new()
	for m in _b:
		var b: MeshBuilder = _b[m]
		if b.empty(): continue
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, b.arrays())
		mesh.surface_set_material(mesh.get_surface_count() - 1, m)
	var mi := MeshInstance3D.new()
	mi.name = node_name
	mi.mesh = mesh
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadows else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	return mi
