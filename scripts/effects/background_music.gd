extends AudioStreamPlayer2D

func _on_finished() -> void:
	if get_node("/root/Main/LevelContainer/battle"): play()
