## The one scene: sky, moon, camera, the hunter and the screen grading. Levels are added under it by Loader.
extends Node3D

const DISTANCE := 26.0
const FOV := 34.0
const POST := """
shader_type canvas_item;
uniform sampler2D screen : hint_screen_texture, filter_linear;
uniform float folk = 1.0;   // 0: the plain grading; 1: ink, muted folk colours and paper, like the story drawings
float rnd(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453); }
float vnoise(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(rnd(i), rnd(i + vec2(1, 0)), f.x), mix(rnd(i + vec2(0, 1)), rnd(i + vec2(1, 1)), f.x), f.y);
}
float lum(vec3 c) { return dot(c, vec3(0.299, 0.587, 0.114)); }
vec3 grade(vec3 c, vec2 uv) {
	c = (c - 0.5) * 1.18 + 0.5;
	float l = lum(c);
	c = mix(vec3(l), c, 0.84);
	c *= 1.0 - smoothstep(0.38, 0.9, distance(uv, vec2(0.5))) * 0.5;
	return c;
}
vec3 soft(vec2 uv, vec2 px) {   // a small blur: the ground's fine texture is not what an illustrator draws
	vec3 a = texture(screen, uv).rgb * 0.36;
	a += (texture(screen, uv + vec2(px.x * 2.0, 0)).rgb + texture(screen, uv - vec2(px.x * 2.0, 0)).rgb
		+ texture(screen, uv + vec2(0, px.y * 2.0)).rgb + texture(screen, uv - vec2(0, px.y * 2.0)).rgb) * 0.16;
	return a;
}
vec3 folk_look(vec2 uv, vec2 px) {
	vec3 c = soft(uv, px);
	// ink only where the softened brightness jumps hard: the edges of houses, roofs, figures
	vec2 d = px * 2.5;
	float tl = lum(soft(uv + vec2(-d.x, -d.y), px)), tr = lum(soft(uv + vec2(d.x, -d.y), px));
	float bl = lum(soft(uv + vec2(-d.x, d.y), px)), br = lum(soft(uv + vec2(d.x, d.y), px));
	float gx = (tr + br) - (tl + bl), gy = (bl + br) - (tl + tr);
	float edge = smoothstep(0.16, 0.34, sqrt(gx * gx + gy * gy));
	// lift the night into the paper's range, then flatten into a few soft bands
	float l = clamp(pow(lum(c), 0.5) * 1.18, 0.0, 1.0);
	l = mix(l, floor(l * 4.0 + 0.5) / 4.0, 0.6);
	vec3 ink = vec3(0.106, 0.090, 0.078), grey = vec3(0.40, 0.37, 0.33), taupe = vec3(0.66, 0.61, 0.53), cream = vec3(0.92, 0.88, 0.80);
	vec3 p = mix(ink, grey, smoothstep(0.0, 0.32, l));
	p = mix(p, taupe, smoothstep(0.30, 0.62, l));
	p = mix(p, cream, smoothstep(0.62, 0.92, l));
	// a breath of each thing's own colour, and the strong reds kept as the drawings' one red
	vec3 tint = clamp(c / max(lum(c), 0.03), vec3(0.6), vec3(1.5));
	p = mix(p, p * tint, 0.10);
	float red = smoothstep(1.7, 2.4, c.r / max(max(c.g, c.b), 0.02)) * smoothstep(0.12, 0.25, c.r);
	p = mix(p, vec3(0.69, 0.12, 0.14) * (0.6 + 0.5 * l), red * 0.9);
	float warm = smoothstep(0.6, 0.9, lum(c)) * smoothstep(0.12, 0.3, c.r - c.b);   // lamplight stays warm
	p = mix(p, vec3(0.98, 0.86, 0.6), warm * 0.5);
	p = mix(p, ink, edge * 0.8);
	float paper = vnoise(uv * vec2(9.0, 6.0)) * 0.06 + vnoise(uv * vec2(420.0, 60.0)) * 0.03 + rnd(uv * 900.0) * 0.02;
	p *= 0.95 + paper;
	p *= 1.0 - smoothstep(0.5, 1.0, distance(uv, vec2(0.5))) * 0.3;
	return p;
}
void fragment() {
	vec3 c = folk > 0.5 ? folk_look(SCREEN_UV, SCREEN_PIXEL_SIZE) : grade(texture(screen, SCREEN_UV).rgb, UV);
	if (folk <= 0.5) c += (rnd(UV * 700.0 + fract(TIME) * 60.0) - 0.5) * 0.035;
	COLOR = vec4(c, 1.0);
}
"""

var env: Environment
var post_mat: ShaderMaterial
var folk_filter := false   # the illustration filter test: off (it muddied the game); F2 still shows it
var moon: DirectionalLight3D
var cam: Camera3D
var cam_target := Vector3.ZERO
var yaw_goal := 0.0   # the view turns in quarter-eighths of a circle (Z / C), like Don't Starve
var player: Player

func _ready() -> void:
	_bind_keys()
	env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.015, 0.018, 0.03)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 1.3
	env.fog_enabled = true
	env.glow_enabled = true
	env.glow_hdr_threshold = 0.95
	env.glow_intensity = 0.7
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	moon = DirectionalLight3D.new()
	moon.shadow_enabled = true
	moon.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	moon.directional_shadow_max_distance = 60.0
	add_child(moon)
	moon.look_at_from_position(Vector3.ZERO, Vector3(-0.384, -0.743, -0.548))
	cam = Camera3D.new()
	cam.fov = FOV
	cam.near = 0.3
	cam.far = 200.0
	add_child(cam)
	cam.make_current()
	Fx.cam = cam
	set_light(Color(0.55, 0.62, 0.9), 1.1, 0.75, Color(0.3, 0.32, 0.45), Color(0.2, 0.2, 0.26), Color(0.1, 0.09, 0.08), 0.012, Color(0.05, 0.06, 0.09))
	player = Player.new()
	player.name = "Hunter"
	add_child(player)
	G.player = player
	player.died.connect(G.on_player_died)
	var post := CanvasLayer.new()
	post.layer = 1
	add_child(post)
	var rect := ColorRect.new()
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sh := Shader.new()
	sh.code = POST
	var sm := ShaderMaterial.new()
	sm.shader = sh
	rect.material = sm
	post.add_child(rect)
	post_mat = sm
	if OS.has_feature("web") and JavaScriptBridge.eval("window.location.search.indexOf('filter=0') >= 0"): folk_filter = false
	sm.set_shader_parameter("folk", 1.0 if folk_filter else 0.0)
	Audio.set_music("music_hub", -9.0)
	# ?level=<id> (web) or --level=<id> drops straight into a level, for testing
	var start := ""
	for a in OS.get_cmdline_user_args(): if a.begins_with("--level="): start = a.substr(8)
	if OS.has_feature("web"):
		var q = JavaScriptBridge.eval("new URLSearchParams(window.location.search).get('level') || ''")
		if q is String and q != "": start = q
		if JavaScriptBridge.eval("window.location.search.indexOf('fast') >= 0"): G.instant = true
	var at = null
	if OS.has_feature("web"):
		var yq = JavaScriptBridge.eval("new URLSearchParams(window.location.search).get('yaw') || '0'")
		Fx.yaw = deg_to_rad(float(str(yq))); yaw_goal = Fx.yaw
	if OS.has_feature("web"):
		var a = JavaScriptBridge.eval("new URLSearchParams(window.location.search).get('at') || ''")
		if a is String and a.contains(","): at = Vector2(float(a.get_slice(",", 0)), float(a.get_slice(",", 1)))
		var fl = JavaScriptBridge.eval("new URLSearchParams(window.location.search).get('flags') || ''")   # ?flags=a,b sets story flags
		if fl is String:
			for f in fl.split(",", false): G.side_add(f)
	if start != "" and Loader.exists(start):
		G.state = G.State.PLAY
		Loader.direct_start = true
		Loader.enter(start, at)
		Loader.direct_start = false
		if at != null: _hold_at(at)
		if OS.has_feature("web"):   # ?near=<prop id> drops the hunter in front of that prop (test shots)
			var nr = JavaScriptBridge.eval("new URLSearchParams(window.location.search).get('near') || ''")
			if nr is String and nr != "" and is_instance_valid(G.level):
				var pr = G.level.prop_by_id(nr)
				if pr: _hold_at(pr.pos + Vector2(0, 110))
			var dz = JavaScriptBridge.eval("new URLSearchParams(window.location.search).get('do') || ''")   # ?do=<level method>: play a scene
			if dz is String and dz.begins_with("story:"):   # ?do=story:<card>: show a story card (test shots)
				await get_tree().create_timer(2.0).timeout
				G.show_story(dz.substr(6))
			elif dz is String and dz != "" and is_instance_valid(G.level) and G.level.has_method(dz):
				await get_tree().create_timer(3.0).timeout
				G.level.call(dz, func(): pass)
		if OS.has_feature("web"):   # ?then=<id> walks on to a second level after a few seconds: tests a real transition
			var nx = JavaScriptBridge.eval("new URLSearchParams(window.location.search).get('then') || ''")
			if nx is String and nx != "":
				await get_tree().create_timer(4.0).timeout
				G.state = G.State.PLAY
				Loader.goto_level(nx)

## Test drops: keep the hunter where he was put while the level's opening scene runs.
func _hold_at(at: Vector2) -> void:
	for i in 30:
		await get_tree().process_frame
		player.pos = at
	snap_camera()

## Moon, the three tones of ambient light, and fog, as each level sets them.
func set_light(moon_col: Color, moon_e: float, shadow: float, sky: Color, eq: Color, gnd: Color, fog_d: float, fog_c: Color) -> void:
	moon.light_color = moon_col
	moon.light_energy = moon_e * 0.6
	moon.shadow_opacity = shadow
	env.ambient_light_color = sky * 0.45 + eq * 0.4 + gnd * 0.15
	env.ambient_light_energy = 1.05
	env.fog_light_color = fog_c
	env.fog_density = fog_d * fog_d * 27.0

func snap_camera() -> void:
	cam_target = player.global_position
	_place_camera(0.0)

func _process(dt: float) -> void:
	player.visible = G.state != G.State.TITLE and is_instance_valid(G.level)
	_apply_yaw()
	_place_camera(dt)

func _place_camera(dt: float) -> void:
	var target := player.global_position
	if is_instance_valid(G.cam_look):   # a scene the hunter is watching: the camera drifts over to it
		cam_target = cam_target.lerp(G.cam_look.global_position, 1.0 - exp(-dt * 2.5))
	else:
		cam_target = target if cam_target.distance_to(target) > 20.0 else cam_target.lerp(target, 1.0 - exp(-dt * 6.0))
	Fx.yaw = lerp_angle(Fx.yaw, yaw_goal, 1.0 - exp(-dt * 9.0))
	if absf(angle_difference(Fx.yaw, yaw_goal)) < 0.002: Fx.yaw = yaw_goal
	var rot := Vector3(-deg_to_rad(Fx.PITCH), Fx.yaw, 0)
	# drunk: the whole world sways and rolls, slowly, like the deck of a boat
	if player.drunk_t > 0.0:
		var tt := Time.get_ticks_msec() / 1000.0; var k := clampf(player.drunk_t / 2.0, 0.0, 1.0)
		rot = Vector3(-deg_to_rad(Fx.PITCH + sin(tt * 0.9) * 3.0 * k), Fx.yaw + deg_to_rad(sin(tt * 0.53) * 6.0 * k), deg_to_rad(sin(tt * 0.71) * 7.0 * k))
	var basis := Basis.from_euler(rot)
	# a jolt on heavy blows that dies away within a quarter second
	var jolt := Vector3(randf_range(-1, 1), randf_range(-1, 1), 0) * Fx.shake_amt
	cam.global_transform = Transform3D(basis, cam_target + basis * (Vector3(0, 0, DISTANCE) + jolt))


## Dash on Space, Shift and the right mouse button; keys also match by position, so a held modifier or a
## German/Romanian layout never blocks one.
func _bind_keys() -> void:
	for pair in [["cam_left", KEY_Z], ["cam_right", KEY_C]]:
		if not InputMap.has_action(pair[0]): InputMap.add_action(pair[0])
		var ek := InputEventKey.new(); ek.physical_keycode = pair[1]
		InputMap.action_add_event(pair[0], ek)
	var shift := InputEventKey.new(); shift.keycode = KEY_SHIFT
	InputMap.action_add_event("dodge", shift)
	var rmb := InputEventMouseButton.new(); rmb.button_index = MOUSE_BUTTON_RIGHT
	InputMap.action_add_event("dodge", rmb)
	for a in InputMap.get_actions():
		if str(a).begins_with("ui_"): continue
		for e in InputMap.action_get_events(a):
			if e is InputEventKey and e.physical_keycode == 0 and e.keycode != KEY_SHIFT:
				var p := InputEventKey.new(); p.physical_keycode = e.keycode
				InputMap.action_add_event(a, p)


func _unhandled_key_input(ev: InputEvent) -> void:
	if ev is InputEventKey and ev.pressed and not ev.echo and G.state == G.State.PLAY:
		if ev.physical_keycode == KEY_Z: yaw_goal = wrapf(yaw_goal - PI / 4.0, -PI, PI + 0.01)
		elif ev.physical_keycode == KEY_C: yaw_goal = wrapf(yaw_goal + PI / 4.0, -PI, PI + 0.01)
	if ev is InputEventKey and ev.pressed and not ev.echo and ev.keycode == KEY_F2:
		folk_filter = not folk_filter
		post_mat.set_shader_parameter("folk", 1.0 if folk_filter else 0.0)
		Hud.toast("Illustration look on  (F2)" if folk_filter else "Illustration look off  (F2)")

var _yaw_applied := 0.0
## Standing sprites turn with the camera, so they always face it.
func _apply_yaw() -> void:
	if Fx.yaw == 0.0 and _yaw_applied == 0.0: return
	for n in get_tree().get_nodes_in_group("ybill"):
		if n is Node3D: n.rotation.y = Fx.yaw
	_yaw_applied = Fx.yaw
