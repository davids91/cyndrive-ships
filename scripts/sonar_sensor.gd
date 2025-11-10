extends RayCast2D

@export var rotation_speed = 0.005

var direct_control = false

func set_manual_rotation(rad):
	direct_control = true
	set_rotation(rad)

func _process(delta):
	if !direct_control: set_rotation(get_rotation() + rotation_speed)
	$"../GUI/sonar_display".set_display_rotation(get_rotation())
	
func _physics_process(delta):
	force_raycast_update()
	if is_colliding():
		var coll_pos = get_collision_point() - get_global_position()
		var coll_color = Color.AZURE
		if get_collider().has_node("team"):
			coll_color = get_collider().modulate
		$"../GUI/sonar_display".add_display_object(coll_pos, coll_color)
