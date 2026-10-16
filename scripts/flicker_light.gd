class_name FlickerLight
extends PointLight2D

var base := 1.0
var t := 0.0
var phase := 0.0


func _ready() -> void:
	phase = randf() * 10.0


func _process(delta: float) -> void:
	t += delta
	energy = base * (1.0 + 0.1 * sin(t * 11.0 + phase) + 0.06 * sin(t * 23.0 + phase * 2.0))
