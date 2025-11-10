extends Area2D

var contained_bodies = Dictionary()
var highligthed_body

func is_target_locked():
	return 0 < contained_bodies.size()

func get_current_target_position():
	if highligthed_body:
		return highligthed_body.get_global_position()
	return get_global_position()

func highlight_centermost():
	if contained_bodies.is_empty():
		return
		
	var target = contained_bodies.keys().front()
	for body in contained_bodies:
		if (get_global_position() - body.get_global_position()).length() \
		< (get_global_position() - target.get_global_position()).length():
			target = body

	if highligthed_body and highligthed_body.has_method("set_highlight"):
		highligthed_body.set_highlight(false)

	if target.has_method("set_highlight"):
		target.set_highlight(true)
		highligthed_body = target
		
func _on_body_entered(body):
	#TODO: what should even be the value of this entry
	if body and body.has_method("set_highlight"):
		contained_bodies[body] = body.get_global_position()
		highlight_centermost()

func _on_body_exited(body):
	contained_bodies.erase(body)
	if(body.has_method("set_highlight")):
		body.set_highlight(false)
	highlight_centermost()
