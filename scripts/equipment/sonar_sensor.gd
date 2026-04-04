extends ShapeCast2D

@export var rotation_speed: float = 0.01
@export var blip_radius: float = 100.
@export var tics_per_sec: float = 10.

@onready var display_node: Node2D = get_node("/root/Main/%GUI/sensors_display")
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
	for i in range(get_collision_count()): # prevent re-firing on each tick while colliding remains true
		var collider = get_collider(i)
		# Do not show invisible objects
		if not collider.visible or not "in_battle" in collider or not collider.in_battle(): continue
		if not blips.has(collider.get_instance_id()) or null == blips[collider.get_instance_id()]:
			blips[collider.get_instance_id()] = add_blip(collider)
			continue
		blips[collider.get_instance_id()].reinvigorate()

@export var blip_default_life_sec: float = 2.
func add_blip(collider: Node2D) -> Node2D:
	var coll_color: Color = Color.WEB_GRAY
	coll_color.a = collider.modulate.a
	if "team" in collider: 
		if collider is LaupeeriumSilo: coll_color = Color.GOLD
		elif collider.team.team_id == 1: coll_color = Color.LIME # team 1 is the player!
		else: coll_color = collider.team.color
	if "blip_color" in collider: coll_color = collider.blip_color
	return display_node.add_display_object(
		self, blip_radius, collider, coll_color,
		blip_default_life_sec if not "sonar_blip_lifetime" in collider else collider.sonar_blip_lifetime
	)
