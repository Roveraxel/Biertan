## Finding what the hunter can use with E: the nearest usable thing within reach, with the quest's own target
## preferred when it is also within reach.
class_name Interact
extends RefCounted

const REACH := 80.0

static func nearest(at: Vector2) -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	var best: Node = null
	var bd := REACH
	var all := tree.get_nodes_in_group("interact")
	for n in all:
		if not n.is_visible_in_tree() or not n.can_interact(): continue
		var d: float = at.distance_to(n.pos)
		if d < bd:
			bd = d; best = n
	if best:
		var tg := Quests.target()
		if not tg.is_empty():
			for n in all:
				if n == best or not n.is_visible_in_tree() or not n.can_interact(): continue
				if n.pos.distance_to(tg[0]) > 12.0: continue
				if at.distance_to(n.pos) < REACH: return n
	return best
