extends CPUParticles2D

# How many times the flames should trigger per second.
# The thruster sound is 2.24 seconds long and contains about 10 beats
@export var triggers_per_sec: float = 10. / 2.24
var time_to_trigger = 0.

func _process(delta: float) -> void:
	time_to_trigger -= delta
	if 0 >= time_to_trigger:
		time_to_trigger = 1. / triggers_per_sec
		if 0 < $"../controller".intent_direction.length():
			emitting = true
