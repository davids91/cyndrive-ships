extends Node2D

@onready var character = get_parent()
@onready var team = get_parent().get_node("team")
var enabled = false
var intent_direction = Vector2()
var intent_force = Vector2()
var internal_force = Vector2()

"""
Run curve based on https://www.youtube.com/watch?v=yorTG9at90g
	--> Run curve is based on speed x time
	--> 3 phases: 
		- acceleration is based on the function x^2
		- speed is capped to: top_speed
		- deceleration: x^2
"""
@export_range(0.001, 200) var top_speed = 0.5
@export_range(1, 100) var start_resistance = 10
@export_range(1, 100) var stop_resistance = 5
@export_range(10., 100.) var booster_strength = 100.
@export_range(0., 1.) var momentum_dampener: float = 1.


"""
From 0 to the top speed the curve the player changes speed is based on x^2 / @start_resistance.
The function provides the speed based on x
"""
func accelerate_function(x):
	return pow(x,2) / start_resistance

"""
Decelerating from top speed to fullstop the curve of the player speed follows x^2 / @stop_resistance.
The function provides the speed based on x
"""	
func decelerate_function(x):
	var _x = max(0, x)
	return pow(_x,2) / stop_resistance

"""
Given: y(@speed) = x^2/@start_resistance; Based on that x = sqrt(y * @start_resistance)
The function provides the x value for the given y value(speed).
"""
func get_accel_x(speed):
	return sqrt(start_resistance * speed)
	
"""
Given: y(@speed) = x^2/@stop_resistance; Based on that x = sqrt(y * @stop_resistance)
The function provides the x value for the given y value(speed).
"""
func get_decel_x(speed):
	return sqrt(stop_resistance * speed)
	
"""
Accepts an inputevent and reconstructs an intent vector from it, based on the implementation in:
Input.get_vector("left", "right", "up", "down")
--> https://github.com/godotengine/godot/blob/a586e860e5fc382dec4ad9a0bec72f7c6684f020/core/input/input.cpp#L382
"""
func get_vector(event, p_deadzone = -1.):
	var vector = Vector2( \
		event.get_action_strength("right") - event.get_action_strength("left"), \
		event.get_action_strength("down") - event.get_action_strength("up"), \
	)
	
	var deadzone = p_deadzone
	if deadzone < 0:
		# If the deadzone isn't specified, get it from the average of the actions.
		deadzone = 0.25 * (
			InputMap.action_get_deadzone("left")
			+ InputMap.action_get_deadzone("right")
			+ InputMap.action_get_deadzone("up")
			+ InputMap.action_get_deadzone("down")
		);
	
	# Circular lentgh limiting and deadzone
	var length = vector.length()
	if(length <= deadzone):
		return Vector2()
	elif(length > 1.):
		return vector / length
	else:
		return vector * inverse_lerp(deadzone, 1. , length) / length

func start() -> void:
	enabled = true

func pause() -> void:
	enabled = false

func stop() -> void:
	enabled = false
	intent_force = Vector2()
	internal_force = Vector2()

func process_input_action(action: Dictionary) -> void:
	intent_direction += action["intent"]
	intent_direction = Vector2(sign(intent_direction.x), sign(intent_direction.y))
	
	if action["boost"]:
		internal_force = intent_direction * top_speed * booster_strength

func _physics_process(_delta):
	if not enabled or BattleTimeline.instance.time_flow == BattleTimeline.TimeFlow.BACKWARD:
		return
	
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

	"""Apply the new speed"""
	internal_force *= 0.99
	internal_force += current_intent
	intent_force = current_intent
	character.set_velocity(internal_force)

	"""Apply angle based on speed"""
	if 0.05 < intent_force.length():
		character.set_rotation(intent_force.angle())

#region temporal corrective functions

func _set_internal_force(force: float) -> void:
	internal_force = force

#endregion
