extends RayCast2D

var pewpew = false
var pewpew_ready = false
var pewpew_point
var point_in_distance = Vector2(50000, 0)
func process_input_action(action):
	point_in_distance = action["cursor"].rotated(-get_parent().get_rotation()) * 50000
	set_target_position(point_in_distance)	
	if action["pewpew"]:
		pewpew = true
		pewpew_ready = false

func _process(delta):
	if pewpew_ready:
		var tween = create_tween()
		$beam_line.points[1] = pewpew_point
		pewpew = false
		tween.tween_property($beam_line, "width", 20, 0.05)
		tween.tween_property($beam_line, "width", 0, 0.1)
		pewpew_ready = false

func _physics_process(delta):
	if pewpew:		
		force_raycast_update()
		if is_colliding():
			pewpew_point = to_local(get_collision_point())
			var victim = get_collider()
			# has_method if 
			if victim.has_method("accept_damage"):
				victim.accept_damage(1.)
		else:
			pewpew_point = point_in_distance
		pewpew_ready = true
	
