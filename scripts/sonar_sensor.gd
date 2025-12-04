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
			_handle_collision(collider, get_collision_point()) 
	else:
		last_collider_id = 0
		
func _handle_collision(collider, collision_point):
	if _is_ship(collider):
		_fire_sonar_ship_blip(collider, collision_point)
	else:
		_fire_sonar_generic_blip(collision_point)
	
func _is_ship(collider) -> bool:
	return collider.has_node("team")
	
func _fire_sonar_ship_blip(collider: BattleCharacter, collision_point):
	var coll_pos = collision_point - get_global_position()
	var coll_color = collider.get_node("team").color
	$"../GUI/sonar_display".add_display_object(coll_pos, coll_color)
	
func _fire_sonar_generic_blip(collision_point):
	var coll_pos = collision_point - get_global_position()
	var coll_color = Color.CHARTREUSE
	$"../GUI/sonar_display".add_display_object(coll_pos, coll_color)
	
		
