extends Node2D

class_name PlayerInput

signal action_triggered(action: Dictionary)

static var _instance: PlayerInput = null
static var instance: PlayerInput:
	get:
		return _instance

@export var input_disabled: bool = true

var current_intent: Vector2 = Vector2()
var current_action_direction: Vector2 = Vector2()
var is_shooting: bool = false
var current_acquired_target: Vector2 = Vector2()

func set_disabled(yesno: bool) -> void:
	input_disabled = yesno

func _unhandled_key_input(event: InputEvent) -> void:
	var action = get_action(event)

	if "movement_intent" in action:
		current_intent += action["movement_intent"]
		action["movement_intent"] = current_intent

	var was_shooting = is_shooting
	if "action_direction" in action:
		action["action_direction"] = action["action_direction"]
		current_action_direction += action["action_direction"]
		action["action_direction"] = current_action_direction
		is_shooting = 0 < action["action_direction"].length()

	if was_shooting and not is_shooting:
		action["action_released"] = true

	if not was_shooting and is_shooting:
		action["action_initiated"] = true

	if not input_disabled and not action.is_empty():
		action_triggered.emit(action)

func _process(_delta: float) -> void:
	if is_shooting: action_triggered.emit(
		{"action_direction": current_action_direction}
	)

#	_FORCE_INLINE_ real_t tdotx(const Vector2 &p_v) const { return columns[0][0] * p_v.x + columns[1][0] * p_v.y; }
static func tdotx(mat, vec):
	return mat.get_scale().x * vec.x  # Let's pretend for now that there is no rotation.. '^^
	
#	_FORCE_INLINE_ real_t tdoty(const Vector2 &p_v) const { return columns[0][1] * p_v.x + columns[1][1] * p_v.y; }
static func tdoty(mat, vec):
	return mat.get_scale().y * vec.y

static func xform(mat, vec):
	return Vector2(tdotx(mat, vec), tdoty(mat, vec)) + mat.get_origin()
"""
Provides the processed control output in a form of a dictionary from the provided data and user input events
Output format is the following:
	action["movement_intent"]: vector: intent of user control in 2D space (up, down, left right). Vector values are either -1, 0 or 1
	action["action_direction"]: vector: direction of weapon action in 2D space (up, down, left right). Vector values are either -1, 0 or 1
	action["acquired_target_position"]: vector: weapon target position in 2D space
	action["boost_initiated"]: boolean value for the activation of the ships booster
	action["boost_released"]: boolean value for the de-activation of the ships booster ( not stored in temporal records )
	action["switch_shield"]: boolean value for shield activation(when active, action direction is used to set shield position instead of weapon aim)
	action["action_initiated"]: boolean value for weapon activation
	action["action_released"]: boolean value for weapon deactivation
	action["acquired_target"]: the target object to which the laser is supposed to be fired
	action["deploy_mine"]: activate and release the attached mine ( if any )
"""
static func get_action(input_event):
	var action = Dictionary()
	var intent_direction = Vector2(
		(-1. if input_event.is_action_pressed("movement_left") else 0. + 1. if input_event.is_action_pressed("movement_right") else 0.),\
		(1. if input_event.is_action_pressed("movement_down") else 0. + -1. if input_event.is_action_pressed("movement_up") else 0.)
	)
	intent_direction -= Vector2(
		(-1. if input_event.is_action_released("movement_left") else 0. + 1. if input_event.is_action_released("movement_right") else 0.),\
		(1. if input_event.is_action_released("movement_down") else 0. + -1. if input_event.is_action_released("movement_up") else 0.)
	)
	if 0. < intent_direction.length():
		action["movement_intent"] = intent_direction

	var action_direction = Vector2(
		(-1. if input_event.is_action_pressed("action_left") else 0. + 1. if input_event.is_action_pressed("action_right") else 0.),\
		(1. if input_event.is_action_pressed("action_down") else 0. + -1. if input_event.is_action_pressed("action_up") else 0.)
	)
	action_direction -= Vector2(
		(-1. if input_event.is_action_released("action_left") else 0. + 1. if input_event.is_action_released("action_right") else 0.),\
		(1. if input_event.is_action_released("action_down") else 0. + -1. if input_event.is_action_released("action_up") else 0.)
	)
	if 0. < action_direction.length():
		action["action_direction"] = action_direction

	if input_event.is_action_pressed("boost"):
		action["boost_initiated"] = true

	if input_event.is_action_released("boost"):
		action["boost_released"] = true

	if input_event.is_action_pressed("deploy_mine"):
		action["deploy_mine"] = true

	if input_event.is_action_pressed("activate_shield"):
		action["switch_shield"] = true

	if input_event.is_action_pressed("emote_1"):
		action["emote_1"] = true

	if input_event.is_action_pressed("emote_2"):
		action["emote_2"] = true

	if input_event.is_action_pressed("emote_3"):
		action["emote_3"] = true

	# Handle weapon selection (1-4 keys)
	if(
		input_event is InputEventKey and input_event.pressed and not input_event.echo
		and input_event.physical_keycode >= KEY_1 and input_event.physical_keycode <= KEY_4
	):
		action["weapon_slot"] = input_event.physical_keycode - KEY_1
	return action

func _enter_tree() -> void:
	if instance == null:
		_instance = self

func _exit_tree() -> void:
	if instance == self:
		_instance = null
