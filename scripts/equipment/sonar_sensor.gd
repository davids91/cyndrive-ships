extends ShapeCast2D

@export var rotation_speed: float = 0.01
@export var blip_radius: float = 100.
@export var tics_per_sec: float = 10.

@onready var display_node: Node2D = get_node("/root/battle/GUI/sensors_display")
@onready var last_checked: float = 0.

var blips: Dictionary = {}

func _process(_delta: float) -> void:
	set_global_rotation(get_global_rotation() + rotation_speed)
	
func _physics_process(delta: float) -> void:
	# Only evaluate a few times per second, or with manual control
	last_checked += delta
	if last_checked < (1. / tics_per_sec):
		return
	last_checked = 0.

	# Check for node collisions
	force_shapecast_update()
	for i in range(get_collision_count()):	# prevent re-firing on each tick while colliding remains true
		var collider = get_collider(i)
		if not blips.has(collider.get_instance_id()) or null == blips[collider.get_instance_id()]:
			blips[collider.get_instance_id()] = add_blip(collider)
			continue
		blips[collider.get_instance_id()].reinvigorate()

func add_blip(collider: Object) -> Node2D:
	if "in_battle" in collider and not collider.in_battle():
		return # only add blip for objects in the current battle 

	if collider.has_node("team"):
		var coll_color = collider.get_node("team").color
		if collider.get_node("team").team_id == 1: # team 1 is the player!
			coll_color = Color.LIME
		return display_node.add_display_object(self, blip_radius, collider, coll_color)
	else:
		return display_node.add_display_object(self, blip_radius, collider, Color.WEB_GRAY)
