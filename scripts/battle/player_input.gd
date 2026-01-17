extends Node2D

class_name PlayerInput

signal action_triggered(action: Dictionary)

var current_intent: Vector2 = Vector2()
var is_shooting: bool = false
var current_pewpew_target: Vector2 = Vector2()
var input_disabled = true

func set_disabled(yesno: bool) -> void:
	input_disabled = yesno

func _unhandled_input(input_event: InputEvent) -> void:
	var action = get_action(input_event)
	is_shooting = (
		(is_shooting and (not "pewpew_released" in action or not action["pewpew_released"]))
		or ("pewpew_initiated" in action and action["pewpew_initiated"])
	)

	if "intent" in action:
		current_intent += action["intent"]
		action["intent"] = current_intent
	if not input_disabled:
		action_triggered.emit(action)

func _process(_delta: float) -> void:
	var action: Dictionary = {}
	if is_shooting:
		action["pewpew"] = xform(get_viewport().get_canvas_transform().affine_inverse(), get_viewport().get_mouse_position())
		action_triggered.emit(action)

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
	action["intent"]: vector: intent of user control in 2D space (up, down, left right). Vector values are either -1, 0 or 1
	action["boost_initiated"]: boolean value for the activation of the ships booster
	action["boost_released"]: boolean value for the de-activation of the ships booster ( not stored in temporal records )
	action["pewpew_initiated"]: boolean value for weapon activation
	action["pewpew_released"]: boolean value for weapon deactivation
	action["pewpew_target"]: the target object to which the laser is supposed to be fired
"""
static func get_action(input_event):
	var action = Dictionary()
	var intent_direction = Vector2(
		(-1. if input_event.is_action_pressed("left") else 0. + 1. if input_event.is_action_pressed("right") else 0.),\
		(1. if input_event.is_action_pressed("down") else 0. + -1. if input_event.is_action_pressed("up") else 0.)
	)
	intent_direction -= Vector2(
		(-1. if input_event.is_action_released("left") else 0. + 1. if input_event.is_action_released("right") else 0.),\
		(1. if input_event.is_action_released("down") else 0. + -1. if input_event.is_action_released("up") else 0.)
	)
	
	if 0. < intent_direction.length():
		action["intent"] = intent_direction

	if(input_event.is_action_pressed("pewpew")):
		action["pewpew_initiated"] = true

	if(input_event.is_action_released("pewpew")):
		action["pewpew_released"] = true

	if input_event.is_action_pressed("boost"):
		action["boost_initiated"] = true

	if input_event.is_action_released("boost"):
		action["boost_released"] = true

	# Handle weapon selection (1-4 keys)
	if(
		input_event is InputEventKey and input_event.pressed and not input_event.echo
		and input_event.physical_keycode >= KEY_1 and input_event.physical_keycode <= KEY_4
	):
		action["weapon_slot"] = input_event.physical_keycode - KEY_1
	return action
