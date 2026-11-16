## A village's real layout, from data/<id>.json (made from OpenStreetMap, (c) OpenStreetMap contributors, ODbL):
## building boxes, wall and road lines, woods, cemeteries. Everything in map pixels (50 = 1 m, y south).
class_name MapData
extends RefCounted

var size := Vector2.ZERO
var village := Rect2()
var road_width: Array = []
var _at := {}
var _raw := {}
var _cache := {}

func _init(id: String) -> void:
	_raw = JSON.parse_string(FileAccess.get_file_as_string("res://data/%s.json" % id))
	size = Vector2(_raw.size[0], _raw.size[1])
	_at = _raw.at
	road_width = _raw.roadwidth
	if _raw.has("village"): village = Rect2(_raw.village[0], _raw.village[1], _raw.village[2], _raw.village[3])

## A real place (metres east and north of the survey origin) as a map point.
func at(real_x: float, real_y: float) -> Vector2:
	return Vector2((real_x - _at.x0) * _at.k + _at.ox, (_at.y0 - real_y) * _at.k + _at.oy)

## Building outlines: [{name, style, c, size, angle, area}], angle counter-clockwise on the map.
func boxes(key: String) -> Array:
	if not _cache.has(key):
		var out := []
		for b in _raw.get(key, []):
			out.append({"name": b.name, "style": b.style, "c": Vector2(b.c[0], b.c[1]), "size": Vector2(b.size[0], b.size[1]), "angle": float(b.angle), "area": float(b.area)})
		_cache[key] = out
	return _cache[key]

## Polylines or polygons: an Array of Arrays of Vector2.
func lines(key: String) -> Array:
	if not _cache.has(key):
		var out := []
		for ln in _raw.get(key, []):
			var pts: Array[Vector2] = []
			for p in ln: pts.append(Vector2(p[0], p[1]))
			out.append(pts)
		_cache[key] = out
	return _cache[key]

## Scale every point and box of the map about the origin (a village made more compact): boxes keep their
## proportions and shrink with it. Arrays and dictionaries are changed in place, so anything holding them sees it.
func scale_all(f: float) -> void:
	for key in _raw:
		if key in ["size", "at", "roadwidth", "village"]: continue
		var v = _raw[key]
		if not (v is Array) or v.is_empty(): continue
		if v[0] is Dictionary and v[0].has("c"):
			for b in boxes(key):
				b.c *= f; b.size *= f
		elif v[0] is Array:
			for ln in lines(key):
				for i in ln.size(): ln[i] *= f
	size *= f
	village = Rect2(village.position * f, village.size * f)
	_at.k = float(_at.k) * f; _at.ox = float(_at.ox) * f; _at.oy = float(_at.oy) * f
