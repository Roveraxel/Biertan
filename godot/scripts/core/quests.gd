## Routes talk, use, markers and the objective line to whoever runs the job where the hunter stands:
## the level itself, or the quest script its village shares between its places.
class_name Quests
extends RefCounted

static func _q() -> Object:
	if not is_instance_valid(G.level): return null
	return G.level.quest if G.level.get("quest") != null else G.level

static func talk(npc: String) -> bool:
	var q := _q()
	return q.talk(npc) if q else false

static func use(p: Prop) -> void:
	var q := _q()
	if q: q.use(p)

static func marker(npc: String) -> bool:
	var q := _q()
	return q.marker(npc) if q else false

static func pending(p: Prop) -> bool:
	var q := _q()
	return q.pending(p) if q else false

## [Vector2 where, String label], or [] when the job points nowhere.
static func target() -> Array:
	var q := _q()
	return q.target() if q else []

static func objective() -> String:
	var q := _q()
	return q.objective() if q else ""
