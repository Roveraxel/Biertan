extends SceneTree
func _initialize() -> void:
	for id in ["cris", "apold", "crisforest"]:
		var r = load("res://scripts/world/net_random.gd").new(hash(id) & 0x7fffffff)
		var lo := 9.0; var hi := -9.0
		for i in 20000:
			var v: float = r.f(); lo = minf(lo, v); hi = maxf(hi, v)
		print(id, " ", hash(id) & 0x7fffffff, " ", lo, " ", hi)
	quit()
