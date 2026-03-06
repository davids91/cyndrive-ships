extends Node2D

signal boosting(is_boosting: bool)

@export var active_movement_rotation_threshold: float = 0.05
@export var passive_movement_rotation_threshold: float = 0.15
@export var handle_rotation: bool = true

@onready var character: BattleCharacter = get_parent()
@onready var last_position = get_global_position()
var enabled: bool = true
var intent_direction: Vector2 = Vector2()
var intent_force: Vector2 = Vector2()
var internal_force: Vector2 = Vector2()

@export_range(0.001, 200) var top_speed: float = 20.
@export_range(0., 100) var start_resistance: float = 0.
@export_range(0.1, 10.) var booster_strength: float = 2.
@export_range(0., 1.) var momentum_dampener: float = 0.85

func accelerate_function(x: float) -> float:
	return pow(x,2.) / start_resistance

func decelerate_function(x: float) -> float:
	return pow(max(0., x),2.)

func get_accel_x(speed: float) -> float:
	return sqrt(start_resistance * speed)
	
func get_decel_x(speed: float) -> float:
	return sqrt(speed)

func start() -> void:
	enabled = true
	is_boosting = false

func pause() -> void:
	enabled = false

func stop() -> void:
	enabled = false
	intent_direction = Vector2()
	intent_force = Vector2()
	internal_force = Vector2()
	last_intent = Vector2()
	is_boosting = false

func apply_impulse(impulse: Vector2) -> void:
	internal_force += impulse

var last_intent: Vector2 = Vector2()
var is_boosting: bool = false
func process_input_action(action: Dictionary) -> void:
	if "movement_intent" in action:
		intent_direction = Vector2(sign(action["movement_intent"].x), sign(action["movement_intent"].y))
		if 0. < action["movement_intent"].length():
			last_intent = intent_direction
	var was_boosting = is_boosting
	is_boosting = (
		(is_boosting and (not "boost_released" in action or not action["boost_released"]))
		or ("boost_initiated" in action and action["boost_initiated"])
	)
	if was_boosting != is_boosting: boosting.emit(is_boosting)

func calculate_rotation() -> float:
	var calculated_rotation: float
	if active_movement_rotation_threshold < intent_force.length():
		calculated_rotation = intent_force.angle()
	else:
		var pos_delta = (get_global_position() - last_position)
		if passive_movement_rotation_threshold < pos_delta.length():
			calculated_rotation = lerp(pos_delta.angle(), get_global_rotation(), 0.2)
	if BattleTimeline.time_flow == BattleTimeline.TimeFlow.BACKWARD: calculated_rotation -= PI
	return calculated_rotation

func _physics_process(_delta: float) -> void:
	if not enabled or BattleTimeline.time_flow == BattleTimeline.TimeFlow.BACKWARD: return

	var previous_intent = intent_force * momentum_dampener
	var current_intent = Vector2()
	var x

	"""Calculating speed from intent"""
	if intent_direction.x == 0:
		x = get_decel_x(abs(previous_intent.x))
		current_intent.x = decelerate_function(x - 1) * sign(previous_intent.x)
	elif 0 == previous_intent.x or sign(previous_intent.x) == sign(intent_direction.x): #trying to accelerate in this direction
		x = get_accel_x(abs(previous_intent.x))
		current_intent.x = accelerate_function(x + 1) * sign(intent_direction.x)
	else:
		x = get_decel_x(abs(previous_intent.x))
		current_intent.x = decelerate_function(x - 1) * sign(previous_intent.x)
	if intent_direction.y == 0:
		x = get_decel_x(abs(previous_intent.y))
		current_intent.y = decelerate_function(x - 1) * sign(previous_intent.y)
	elif 0 == previous_intent.y or sign(previous_intent.y) == sign(intent_direction.y): #trying to accelerate in this direction
		x = get_accel_x(abs(previous_intent.y))
		current_intent.y = accelerate_function(x + 1) * sign(intent_direction.y)
	else:
		x = get_decel_x(abs(previous_intent.y))
		current_intent.y = decelerate_function(x - 1) * sign(previous_intent.y)
	current_intent = current_intent.clamp(-Vector2(top_speed,top_speed), Vector2(top_speed,top_speed))

	""" Apply boost"""
	if is_boosting:
		internal_force += (intent_direction + last_intent) * top_speed * booster_strength

	"""Apply the new speed"""
	internal_force *= 0.99
	internal_force += current_intent
	intent_force = current_intent

	character.set_velocity(internal_force)
	if handle_rotation: character.set_global_rotation(calculate_rotation())
	last_position = get_global_position()

#region temporal corrective functions

func _set_internal_force(force: Vector2) -> void:
	internal_force = force

#endregion
