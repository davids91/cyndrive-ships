extends CPUParticles2D

@export var remove_delay: float = 1

func _ready() -> void:
	emitting = true # because one-shot fx reset this in the godot editor
	await get_tree().create_timer(remove_delay).timeout
	queue_free()
	
