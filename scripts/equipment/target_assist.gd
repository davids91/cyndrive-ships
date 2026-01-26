extends Area2D

var enabled: bool = true
var contained_bodies: Dictionary = {}
var highligthed_body: Node2D

func set_disabled(yesno: bool) -> void:
	enabled = not yesno

func is_target_locked() -> bool:
	return 0 < contained_bodies.size()

func get_current_target() -> Node2D:
	return highligthed_body

func get_current_target_position() -> Vector2:
	if highligthed_body and enabled:
		return highligthed_body.get_global_position()
	return get_global_position()

func highlight_centermost() -> void:
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
		
func _on_body_entered(body: Node2D) -> void:
	if(
		body and body.has_method("set_highlight")
		and ( # Either the parent doesN't have a team node, or the body is an enemy by team assignments
			not get_parent().has_node("team")
			or (body.has_node("team") and body.get_node("team").is_enemy(get_parent().get_node("team")))
		)
	):
		contained_bodies[body] = BattleTimeline.instance.time_msec()
		highlight_centermost()

func _on_body_exited(body: Node2D) -> void:
	contained_bodies.erase(body)
	if(body.has_method("set_highlight")):
		body.set_highlight(false)
	highlight_centermost()
