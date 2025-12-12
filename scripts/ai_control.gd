extends Node2D

@export var runs_per_second: float = 5.
@export var max_distance_from_target: float = 10.
@export var laser_aim: float = 0.85
@export var laser_haste: float = 0.615
@export var difficuilty_laser_frequency_sec: float = 0.8
@export var attack_range: float = 2000.
@export var goldfish_memory_sec: float = 1.

@onready var character: BattleCharacter = get_parent()
var time_until_script_execution = 1. / runs_per_second
var chosen_target: CharacterBody2D
var laser_direction: Vector2
var enabled: bool = true
var time_since_laser: float = 0.
var distance_to_target: float = 0.
var time_until_target_drop: float = goldfish_memory_sec

func stop() -> void:
	enabled = false
	chosen_target = null
	laser_direction = Vector2()
	time_since_laser = 0.

func resume() -> void:
	enabled = true

func _process(delta):
	time_until_script_execution -= delta
	time_since_laser += delta

	if not enabled or time_until_script_execution >= 0:
		return
	time_until_script_execution = 1. / runs_per_second
	var action = Dictionary()
	action["intent"] = Vector2()
	action["cursor"] = Vector2()
	action["pewpew"] = false
	action["boost"] = false


	var combatants = character.get_parent()
	var to_target : Vector2

	# target not visible
	var space_state = get_world_2d().direct_space_state
	if chosen_target != null:
		to_target = ( chosen_target.get_global_position() - character.get_global_position() )
		distance_to_target = to_target.length()
		to_target = to_target.normalized()
		var target_range_raycast_query = PhysicsRayQueryParameters2D.create( \
			character.get_global_position(), \
			character.get_global_position() + to_target * attack_range \
		)
		var target_range_raycast_result = space_state.intersect_ray(target_range_raycast_query)
		if not target_range_raycast_result.has("collider") or chosen_target != target_range_raycast_result.collider:
			time_until_target_drop -= delta
		if time_until_target_drop <= 0.:
			chosen_target = null

	# chosen target is not alive
	if chosen_target != null and ("is_alive" not in chosen_target or not chosen_target.is_alive()):
		chosen_target = null

	# decide potential new target
	var random_target = combatants.get_children().pick_random()
	var tries = 0
	while tries < 5 and ("in_battle" not in random_target or !random_target.in_battle()):
		random_target = combatants.get_children().pick_random()
		tries += 1
	if random_target != null and random_target.has_node("team") and random_target.get_node("team").is_enemy(character.get_node("team")):
		var vector_to_target = random_target.global_position - character.global_position
		var candidate_distance = vector_to_target.length()
		if (chosen_target == null or candidate_distance < distance_to_target or candidate_distance < attack_range):
			var random_target_raycast_query = PhysicsRayQueryParameters2D.create( \
				character.get_global_position(), \
				character.get_global_position() + vector_to_target.normalized() * attack_range \
			)
			var random_target_raycast_result = space_state.intersect_ray(random_target_raycast_query)
			if random_target_raycast_result.has("collider") and random_target == random_target_raycast_result.collider:
				chosen_target = random_target
				distance_to_target = vector_to_target.length()
				time_until_target_drop = goldfish_memory_sec

	# Go to spawn position if no target
	var target_is_alive = false
	if chosen_target != null and "is_alive" in chosen_target and chosen_target.is_alive():
		target_is_alive = true
		to_target = ( chosen_target.get_global_position() - character.get_global_position() )
		distance_to_target = to_target.length()
	else: 
		to_target = ( character.spawn_position - character.get_global_position() )
		distance_to_target = to_target.length()

	# Determine the speed to advance towards the target
	var ideal_speed = lerp(
		character.get_node("controller").top_speed, 0.,
		max_distance_from_target / (distance_to_target)
	)
	
	laser_direction = lerp(laser_direction, to_target, laser_aim + max(0.05, 0.6 - time_since_laser) * laser_haste)

	# See if there's anything in the way to the target
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
	action["pewpew"] = target_acquired and target_is_alive and time_since_laser > difficuilty_laser_frequency_sec
	action["intent"] = Vector2(sign(to_target.x), sign(to_target.y)) * ideal_speed

	if action["pewpew"]:
		time_since_laser = 0

	character.process_input_action(action)
