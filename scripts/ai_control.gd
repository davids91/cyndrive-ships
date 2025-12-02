extends Node2D


@export var max_distance_from_target = 10.
@export var laser_aim = 1.815
@export var laser_haste = 0.03
@export var difficuilty_laser_frequency_sec = 1.3
@export var difficuilty_aim_response = 0.5

@onready var character = get_parent()
var chosen_target: CharacterBody2D
var laser_direction: Vector2
var enabled = true
var time_since_laser = 0.

func stop() -> void:
	enabled = false
	chosen_target = null
	laser_direction = Vector2()
	time_since_laser = 0.

func resume() -> void:
	enabled = true

func _process(delta):
	if not enabled:
		return
		
	var action = Dictionary()
	action["intent"] = Vector2()
	action["cursor"] = Vector2()
	action["pewpew"] = false
	action["boost"] = false

	time_since_laser += delta

	var combatants = character.get_parent()
	var to_target : Vector2

	# If chosen target is not alive anymore..
	if chosen_target != null and ("is_alive" not in chosen_target or not chosen_target.is_alive()):
		chosen_target = null

	# decide new target
	var random_target = combatants.get_children().pick_random()
	var tries = 0
	while tries < 50 and ("is_alive" not in random_target or !random_target.is_alive()):
		random_target = combatants.get_children().pick_random()
		tries += 1
	if random_target.get_node("team").is_enemy(character.get_node("team")) \
		and ( \
			chosen_target == null or \
			((random_target.global_position + character.global_position).length() \
			< (chosen_target.global_position + character.global_position).length()) \
		) \
	:
		chosen_target = random_target

	if chosen_target != null:
		var target_direction = Vector2( \
			cos(chosen_target.get_rotation()), sin(chosen_target.get_rotation()), 
		)
		to_target = ( \
			(chosen_target.get_global_position() - target_direction * max_distance_from_target) \
			- character.get_global_position() \
		).normalized()
		var ideal_speed = lerp(
			character.get_node("controller").top_speed, 0.,
			max_distance_from_target / (chosen_target.get_global_position() - character.get_global_position()).length()
		)
		
		if time_since_laser > difficuilty_aim_response:
			# Due to PD convergence, it looks like the enemy targeting system is "narrowing down" where to shoot
			# which is actually a flickering directions 
			var new_direction = lerp(laser_direction, to_target, laser_aim + max(0.05, 0.6 - time_since_laser))
			var old_direction = laser_direction
			laser_direction = new_direction + (new_direction - old_direction) * laser_haste
		
		# See if there's anything in the way to the target
		var space_state = get_world_2d().direct_space_state
		var raycast_query = PhysicsRayQueryParameters2D.create( \
			character.get_global_position(), \
			character.get_global_position() + laser_direction * 50000000. \
		)
		var raycast_result = space_state.intersect_ray(raycast_query)
		var target_acquired = ( \
			"collider" in raycast_result and raycast_result.collider.has_node("team") \
			and raycast_result.collider.get_node("team").is_enemy(character.get_node("team"))
		)
				
		action["cursor"] = laser_direction
		action["pewpew"] = target_acquired and time_since_laser > difficuilty_laser_frequency_sec
		action["intent"] = Vector2(sign(to_target.x), sign(to_target.y)) * ideal_speed
	
	if action["pewpew"]:
		time_since_laser = 0

	character.process_input_action(action)
