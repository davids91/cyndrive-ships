extends Control

func _input(event: InputEvent) -> void:
	if not get_parent().visible: return
	if event.is_action_pressed("ui_accept"):
		if get_parent().is_dialogue_active and not get_parent().dialogue_in_progress: get_parent().finish()
		else: get_parent().start_new_line() # Skip the current line
		accept_event()
