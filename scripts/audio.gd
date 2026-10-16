class_name Audio
extends Node
## Sound effects pool plus crossfading music and ambience.

var pool: Array = []
var idx := 0
var music: AudioStreamPlayer
var ambient: AudioStreamPlayer
var cur_music := ""
var cur_amb := ""
var music_db := -10.0
var amb_db := -12.0
var mute := false


func _ready() -> void:
	for i in 10:
		var p := AudioStreamPlayer.new()
		add_child(p)
		pool.append(p)
	music = AudioStreamPlayer.new()
	music.volume_db = -80.0
	add_child(music)
	ambient = AudioStreamPlayer.new()
	ambient.volume_db = -80.0
	add_child(ambient)


func play(sfx_name: String, vol := 0.0, pitch := 1.0) -> void:
	var s := G.sound(sfx_name, false)
	if s == null:
		return
	var p: AudioStreamPlayer = pool[idx]
	idx = (idx + 1) % pool.size()
	p.stream = s
	p.volume_db = vol
	p.pitch_scale = pitch * randf_range(0.95, 1.05)
	p.play()


func set_music(track: String, vol := -10.0) -> void:
	if track == cur_music:
		return
	cur_music = track
	_swap(music, track, vol)


func set_ambient(track: String, vol := -12.0) -> void:
	if track == cur_amb:
		return
	cur_amb = track
	_swap(ambient, track, vol)


func _swap(player: AudioStreamPlayer, track: String, vol: float) -> void:
	var tw := create_tween()
	if player.playing:
		tw.tween_property(player, "volume_db", -80.0, 0.6)
	tw.tween_callback(func():
		if track == "":
			player.stop()
			return
		var s := G.sound(track, true)
		if s == null:
			return
		player.stream = s
		player.play()
	)
	if track != "":
		tw.tween_property(player, "volume_db", vol, 1.6)
