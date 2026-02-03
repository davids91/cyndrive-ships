extends Node2D

@export var runs_per_second: float = 10.
@export var max_distance_from_target: float = 10.
@export var target_clamp_distance: float = 300.
@export var laser_haste: float = 0.6
@export var laser_lookahead: float = 0.15
@export var attack_range: float = 1200.
@export var goldfish_memory_sec: float = 1.
@export var stuck_sec_threshold: float = 3.
@export var stuck_motion_threshold: float = 30.
@export var seconds_of_bossting_after_stuck: float = 0.5

@onready var character: BattleCharacter = get_parent()
var position_moving_avg: Vector2 = get_global_position()
var target_moving_avg: Vector2 = Vector2()
var moving_intention: Vector2 = Vector2()
var time_until_script_execution = 1. / runs_per_second
var chosen_target: CharacterBody2D
var enabled: bool = true
var distance_to_target: float = 0.
var time_until_target_drop: float = goldfish_memory_sec

var permanently_disabled: bool = false
func set_disabled(yesno: bool) -> void:
	permanently_disabled = yesno

func stop() -> void:
	enabled = false
	chosen_target = null
	moving_intention = Vector2()

func resume() -> void:
	enabled = true

func _process(delta: float) -> void:
	if chosen_target != null:
		target_moving_avg = lerp(
			chosen_target.get_global_position() + chosen_target.get_velocity() * chosen_target.approx_size * delta * laser_lookahead,
			target_moving_avg,
			laser_haste
		)

var seconds_left_to_boost: float = 0.
var boost_direction: Vector2 = Vector2()
var target_is_acquired = false
var target_was_acquired = false
func _physics_process(delta: float) -> void:
	time_until_script_execution -= delta

	if(
		FeatureFlags.is_enabled("disable_ai")
		or time_until_script_execution >= 0
		or BattleTimeline.instance.time_flow == BattleTimeline.TimeFlow.BACKWARD
	): return

	if(
		permanently_disabled or not enabled
		or not character.in_battle()
	):
		character.process_input_action({"movement_intent": Vector2()})
		return

	time_until_script_execution = 1. / runs_per_second
	var action = Dictionary()
	var combatants = character.get_parent()

	# target not visible
	var space_state = get_world_2d().direct_space_state
	if chosen_target != null:
		var to_target = ( chosen_target.get_global_position() - character.get_global_position() )
		distance_to_target = to_target.length()
		to_target = to_target.normalized()
		var target_range_raycast_result = space_state.intersect_ray(PhysicsRayQueryParameters2D.create(
			character.get_global_position(), character.get_global_position() + to_target * attack_range
		))
		if not target_range_raycast_result.has("collider") or chosen_target != target_range_raycast_result.collider:
			time_until_target_drop -= delta
		if time_until_target_drop <= 0.: chosen_target = null

	# chosen target is not alive
	if chosen_target != null and ("is_alive" not in chosen_target or not chosen_target.is_alive):
		chosen_target = null

	# decide potential new target
	var tries = 0
	var raycast_result
	var random_target = combatants.get_children().pick_random()
	while tries < 5 and ("in_battle" not in random_target or !random_target.in_battle()):
		random_target = combatants.get_children().pick_random()
		tries += 1
	if random_target != null and random_target.has_node("team") and random_target.get_node("team").is_enemy(character.get_node("team")):
		var vector_to_target = random_target.global_position - character.global_position
		var candidate_distance = vector_to_target.length()
		if (chosen_target == null or candidate_distance < distance_to_target or candidate_distance < attack_range):
			raycast_result = space_state.intersect_ray(PhysicsRayQueryParameters2D.create(
				character.get_global_position(),
				character.get_global_position() + vector_to_target.normalized() * attack_range
			))
			if raycast_result.has("collider") and random_target == raycast_result.collider:
				chosen_target = random_target
				distance_to_target = vector_to_target.length()
				time_until_target_drop = goldfish_memory_sec
				target_moving_avg = random_target.get_global_position()
			else: raycast_result = null # In case the random target is not in line of sight, do not cache the raycast results

	# Go to spawn position if no target
	var target_is_alive = false
	if chosen_target != null and "in_battle" in chosen_target and chosen_target.in_battle():
		target_is_alive = true
		distance_to_target = (chosen_target.get_global_position() - character.get_global_position()).length()
	else: distance_to_target = (character.spawn_position - character.get_global_position()).length()

	# Determine the speed to advance towards the target
	var ideal_speed = lerp(
		character.get_node("controller").top_speed, 0.,
		max_distance_from_target / max(0.000001, distance_to_target)
	)

	# Detect where ship should move towards
	if target_is_alive:
		moving_intention = (target_moving_avg - character.get_global_position()).normalized() * ideal_speed
		action["movement_intent"] = moving_intention
	else:
		moving_intention = (character.spawn_position - character.get_global_position()).normalized() * ideal_speed
		action["movement_intent"] = moving_intention

	# See if there's anything in the way to the target
	target_was_acquired = target_is_acquired
	if chosen_target != null:
		var to_target = (chosen_target.get_global_position() - character.get_global_position())
		raycast_result = space_state.intersect_ray(PhysicsRayQueryParameters2D.create(
			get_global_position(),
			character.get_global_position() + to_target
		))
		target_is_acquired = (
			( # Collsiion detected at gunpoint, and the target is an enemy
				"collider" in raycast_result and raycast_result.collider.has_node("team")
				and raycast_result.collider.get_node("team").is_enemy(character.get_node("team"))
			) or ( # Becuase the Carriers might have more complex geometry, the raycasts don't work on them FOR SOME REASON >:C
				null != chosen_target and chosen_target.is_in_group("complex_collision_shapes")
				# Workaround: the chosen target is a carrier and the gunpoint points within its radius
				and (character.get_global_position() + to_target - chosen_target.get_global_position()).length() <= chosen_target.approx_size
				and ( # and Either there's no raycast result, or it's further away than the actual target
					not "collider" in raycast_result
					or distance_to_target <= (raycast_result.collider.get_global_position() - character.get_global_position()).length()
				)
			)
		)
	else: target_is_acquired = false

	if target_is_acquired and not target_was_acquired: action["action_initiated"] = true
	elif(
		not target_is_acquired and target_was_acquired
		or (
			not target_is_acquired and not "action_released" in action
			and character.has_node("weapon_slot") and character.get_node("weapon_slot").is_shooting
		)
	): action["action_released"] = true
	if target_is_acquired and target_is_alive:
		if (target_moving_avg - chosen_target.get_global_position()).length() < target_clamp_distance:
			action["action_intent"] = chosen_target.get_global_position()
		else: action["action_intent"] = target_moving_avg
		action["pewpew_target"] = chosen_target

	# Detect if the ship is stuck, and apply boost to break free
	position_moving_avg = lerp(get_global_position(), position_moving_avg, 0.5)
	if ( # The ship is in one place, and has a long term contact, set intent to "unstuck"
		(get_global_position() - position_moving_avg).length() < stuck_motion_threshold
		and null != get_parent().body_in_contact and get_parent().contact_time > stuck_sec_threshold
	):
		action["movement_intent"] = (character.get_global_position() - get_parent().body_in_contact.get_global_position()).normalized()
		action["boost_initiated"] = true
		seconds_left_to_boost = seconds_of_bossting_after_stuck
		boost_direction = action["movement_intent"]

	if 0 < seconds_left_to_boost:
		seconds_left_to_boost -= delta
		if 0 < seconds_left_to_boost: action["boost_released"] = true
		else: action["movement_intent"] = boost_direction

	if 0 == action["movement_intent"].length(): action.erase("movement_intent")

	character.process_input_action(action)
