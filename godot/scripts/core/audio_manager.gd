## Sound. Autoloaded as Audio: one-shot effects (with several takes each), sounds heard from somewhere in the
## world, music that crossfades, an ambient bed under it, footsteps, creature cries and night calls.
extends Node

const FADE := 1.6
const STONE := ["hub", "richis", "mosna", "biertan", "sighisoara", "viscri", "crit", "saschiz", "sapartoc", "apold", "cris", "malancrav", "richisvillage", "caves", "cellar", "crypt", "malcrypt", "tunnel", "gorge", "church", "sacristy", "biertanfort"]
const UNDER := ["caves", "cellar", "crypt", "malcrypt", "gorge", "tunnel"]

var _clips := {}
var _takes := {}
var _music: AudioStreamPlayer
var _music_b: AudioStreamPlayer
var _amb: AudioStreamPlayer
var _pool: Array[AudioStreamPlayer] = []
var _vol := {}                 # player -> linear volume (players keep decibels)
var _music_target := 1.0
var _amb_target := 0.0
var _amb_name := ""
var _step_t := 0.0
var _vocal_t := 0.0
var _night_t := 8.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_music = _player(); _music_b = _player(); _amb = _player()
	for i in 10: _pool.append(_player())

func _player() -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	add_child(p)
	_set_vol(p, 0.0)
	return p

func _set_vol(p: AudioStreamPlayer, v: float) -> void:
	_vol[p] = v
	p.volume_db = linear_to_db(maxf(v, 0.0001))

func _load(snd: String) -> AudioStream:
	if _clips.has(snd): return _clips[snd]
	var clip: AudioStream = null
	for ext in ["ogg", "mp3", "wav"]:
		var path := "res://audio/%s.%s" % [snd, ext]
		if ResourceLoader.exists(path):
			clip = load(path)
			break
	_clips[snd] = clip
	return clip

## A sound and its other takes: name, name_2, name_3 ...
func _variants(snd: String) -> Array:
	if _takes.has(snd): return _takes[snd]
	var list := []
	var first := _load(snd)
	if first: list.append(first)
	for i in range(2, 9):
		var c := _load("%s_%d" % [snd, i])
		if c == null: break
		list.append(c)
	_takes[snd] = list
	return list

func _free_player() -> AudioStreamPlayer:
	for p in _pool:
		if not p.playing: return p
	return null

func _looped(clip: AudioStream) -> AudioStream:
	if clip is AudioStreamOggVorbis or clip is AudioStreamMP3: clip.loop = true
	elif clip is AudioStreamWAV: clip.loop_mode = AudioStreamWAV.LOOP_FORWARD
	return clip

func sfx(snd: String, db := 0.0, pitch := 1.0) -> void:
	var takes := _variants(snd)
	var p := _free_player()
	if takes.is_empty() or p == null: return
	p.stream = takes[randi() % takes.size()]
	# recorded sounds with several takes also vary their pitch a touch, so repeats don't sound canned
	p.pitch_scale = pitch * randf_range(0.94, 1.06) if takes.size() > 1 else pitch
	p.volume_db = db
	p.play()

## A sound heard from somewhere in the world: quieter with distance from the hunter. Silent past about 900 px.
func sfx_at(snd: String, at: Vector2, db := 0.0, pitch := 1.0) -> void:
	if not is_instance_valid(G.player):
		sfx(snd, db, pitch)
		return
	var dist: float = (at - G.player.pos).length()
	if dist > 900.0: return
	var takes := _variants(snd)
	var p := _free_player()
	if takes.is_empty() or p == null: return
	var fall := clampf(1.0 - (dist - 150.0) / 750.0, 0.0, 1.0)
	p.stream = takes[randi() % takes.size()]
	p.pitch_scale = pitch * randf_range(0.94, 1.06)
	p.volume_db = db + linear_to_db(maxf(fall * fall, 0.0001))
	p.play()

var track := ""         # the tune playing now, to come back to after an interlude
var track_db := -9.0

func set_music(name: String, db := 0.0) -> void:
	var clip := _load(name)
	if clip == null: return
	track = name; track_db = db
	_music_target = db_to_linear(db)
	if _music.stream == clip and _music.playing: return
	# the old tune hands over to a second player and fades out while the new one fades in
	if _music.playing:
		_music_b.stream = _music.stream
		_set_vol(_music_b, _vol[_music])
		_music_b.play(_music.get_playback_position())
	_music.stream = _looped(clip)
	_set_vol(_music, 0.0)
	_music.play()

var _voice: AudioStreamPlayer

## Lorena's voice telling the story; null stops her. The music sinks under her while she speaks.
func voice(clip: AudioStream) -> void:
	if _voice == null:
		_voice = AudioStreamPlayer.new()
		_voice.bus = "Master"
		_voice.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(_voice)
	_voice.stop()
	if clip == null: return
	_voice.stream = clip
	_voice.volume_db = 1.0
	_voice.play()

func speaking() -> bool:
	return _voice != null and _voice.playing

## A creature's cry; first = it has just caught the hunter's scent.
func vocal(e: Enemy, first: bool) -> void:
	match e.kind:
		"wolf":
			if first and randf() < 0.5: sfx_at("howl", e.pos, -10.0, randf_range(0.95, 1.15))
			else: sfx_at("growl", e.pos, -8.0, randf_range(0.9, 1.1))
		"pricolici": sfx_at("roar_wolf" if first else "growl", e.pos, -6.0 if first else -5.0, 0.9 if first else randf_range(0.7, 0.8))
		"strigoi": sfx_at("hiss", e.pos, -9.0, randf_range(0.8, 0.95))
		"moroi": sfx_at("whisper", e.pos, -10.0, randf_range(0.85, 1.0))

func _process(dt: float) -> void:
	var k := dt / maxf(Engine.time_scale, 0.01) / FADE
	var duck := 0.35 if speaking() else 1.0   # under Lorena's voice
	_set_vol(_music, move_toward(_vol[_music], _music_target * duck, k * maxf(_music_target, 0.3)))
	_set_vol(_music_b, move_toward(_vol[_music_b], 0.0, k * 0.6))
	if _music_b.playing and _vol[_music_b] <= 0.0: _music_b.stop()
	_set_vol(_amb, move_toward(_vol[_amb], _amb_target, k * 0.5))
	_ambient()
	if G.state != G.State.PLAY or not is_instance_valid(G.player): return
	_vocals(dt)
	_night_calls(dt)
	# footsteps: cobbles and stone in the villages, caves and the church; grass and leaves out on the land
	var speed: float = G.player.vel.length()
	if speed < 60.0:
		_step_t = 0.05
		return
	_step_t -= dt * clampf(speed / 200.0, 0.6, 1.6)
	if _step_t > 0.0: return
	_step_t = 0.34
	sfx("step_concrete" if G.current in STONE else "step_grass", -15.0)

## The bed of sound under the music: dripping stone underground, wind and night everywhere else.
func _ambient() -> void:
	var want := ""; var db := -60.0
	if G.state == G.State.PLAY or G.state == G.State.DIALOGUE:
		var c: String = G.current
		if c in UNDER: want = "amb_cave"; db = -14.0
		elif c in ["church", "sacristy"]: want = "amb_cave"; db = -20.0
		elif Mats.is_village(c): want = "amb_wind"; db = -24.0
		elif c == "stana" or c in ["forest", "critforest", "crisforest", "richisforest", "ieleridge", "uriasi"]: want = "amb_woods"; db = -12.0
		elif c != "": want = "amb_night"; db = -16.0
	if want != _amb_name:
		_amb_target = 0.0   # fade the old bed down before swapping it
		if _vol[_amb] > 0.01 and _amb.playing: return
		_amb_name = want
		_amb.stop()
		if want == "": return
		var clip := _load(want)
		if clip == null: return
		_amb.stream = _looped(clip)
		_amb.play()
	_amb_target = 0.0 if want == "" else db_to_linear(db)

## Hunting creatures now and then give voice, heard from where they are.
func _vocals(dt: float) -> void:
	_vocal_t -= dt
	if _vocal_t > 0.0: return
	_vocal_t = 0.5
	for e in Enemy.all:
		if not is_instance_valid(e) or e.hp <= 0.0 or e.state in ["idle", "dormant"]: continue
		if randf() > 0.06: continue   # about one cry every eight seconds each
		vocal(e, false)

## Now and then an owl or a crow calls from somewhere out in the dark, wherever the sky is open.
func _night_calls(dt: float) -> void:
	if G.current == "" or G.current in UNDER or G.current in ["church", "sacristy"]: return
	_night_t -= dt
	if _night_t > 0.0: return
	_night_t = randf_range(12.0, 30.0)
	var at: Vector2 = G.player.pos + Vector2.from_angle(randf() * TAU) * randf_range(350.0, 700.0)
	var r := randf()
	if r < 0.55: sfx_at("owl", at, -8.0, randf_range(0.95, 1.05))
	elif r < 0.85: sfx_at("crow", at, -10.0, randf_range(0.9, 1.1))
	else: sfx_at("owl_shriek", at, -12.0)
