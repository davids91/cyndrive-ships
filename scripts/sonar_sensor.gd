extends RayCast2D

@export var rotation_speed = 0.005

var direct_control = false

var last_collider_id = 0

func set_manual_rotation(rad):
	direct_control = true
	set_rotation(rad)

func _process(_delta):
	if !direct_control: set_rotation(get_rotation() + rotation_speed)
	$"../GUI/sonar_display".set_display_rotation(get_rotation())
	
func _physics_process(_delta):
	force_raycast_update()
	if is_colliding():
		var collider = get_collider()
		#prevent re-firing on each tick while colliding remains true
		if collider.get_instance_id() != last_collider_id:
			last_collider_id = collider.get_instance_id() 
			var coll_pos = get_collision_point() - get_global_position()
			var coll_color = Color.AZURE
			if collider.has_node("team"):
				coll_color = collider.modulate
			$"../GUI/sonar_display".add_display_object(coll_pos, coll_color)
	else:
		last_collider_id = 0
