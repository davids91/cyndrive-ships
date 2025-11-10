extends Node2D


@export var max_distance_from_target = 10.
@export var laser_aim = 1.815
@export var laser_haste = 0.03

@onready var character = get_parent()
var enabled = true
var count_up = 0
var time_since_laser = 0
var chosen_target : CharacterBody2D
var laser_direction : Vector2

func _process(delta):
	if not enabled:
		return
		
	var action = Dictionary()
	action["intent"] = Vector2()
	action["cursor"] = Vector2()
	action["pewpew"] = false

	var combatants = character.get_parent().combatants
	var to_target : Vector2
	var changed_target = false

	if not combatants.is_empty(): # check an enemy to decide
		var random_target = combatants.pick_random()
		var tries = 0
		while !random_target.is_alive() and tries < 50:
			random_target = combatants.pick_random()
			tries += 1
		if random_target.get_node("team").is_enemy(character.get_node("team")) \
			and ( \
				chosen_target == null or \
				((random_target.global_position + character.global_position).length() \
				< (chosen_target.global_position + character.global_position).length()) \
			) \
		:
			chosen_target = random_target
			changed_target = true

	time_since_laser += delta

	#TODO: Clear target when it's terminated
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
		
		if changed_target:
			laser_direction = to_target
		elif time_since_laser > 0.5:
			# Due to PD convergence, it looks like the enemy targeting system is "narrowing down" where to shoot
			# which is actually a flickering directions 
			var new_direction = lerp(laser_direction, to_target, laser_aim + max(0.05, 0.6 - time_since_laser))
			var old_direction = laser_direction
			laser_direction = new_direction + (new_direction - old_direction) * laser_haste
		
		action["cursor"] = laser_direction
		action["pewpew"] = time_since_laser > 1.3
		action["intent"] = Vector2(sign(to_target.x), sign(to_target.y)) * ideal_speed
	
	if action["pewpew"]:
		time_since_laser = 0

	character.process_input_action(action)
