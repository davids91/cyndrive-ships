extends Control

func _input(event):
	if visible and event is InputEventMouseButton and event.pressed:
		if not get_global_rect().has_point(event.position):
			hide()
	
