## godot --headless --fixed-fps 30 -s tests/descent.gd
## A new game's real road: level change into the stână (its fade overlaps the prologue card), then down to
## Sighișoara. Fails if the screen is left black or the level never changes.
extends SceneTree
func _initialize() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main); current_scene = main
	_run()
func _run() -> void:
	var G = root.get_node("G"); var Loader = root.get_node("Loader"); var Hud = root.get_node("Hud")
	G.test_mode = true
	await process_frame
	G.state = G.State.PLAY
	Loader.goto_level("stana")
	for i in 600:
		await process_frame
		if G.state == G.State.DIALOGUE and i % 10 == 0: G.advance_dialogue()
	print("stana: state=%d fade=%.2f transitioning=%s" % [G.state, Hud._fade.color.a, G.transitioning])
	G.level.step = 3
	G.level._morning()
	for i in 900:
		await process_frame
		if G.state == G.State.DIALOGUE and i % 10 == 0: G.advance_dialogue()
		if i % 120 == 0: print("[%d] level=%s state=%d fade=%.2f transitioning=%s" % [i, G.current, G.state, Hud._fade.color.a, G.transitioning])
	print("RESULT ", "ok" if G.current == "sighisoara" and Hud._fade.color.a < 0.1 else "FAIL")
	quit()
