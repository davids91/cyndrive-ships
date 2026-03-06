extends Node2D

class_name PlayerInput

signal time_control_triggered(action: Dictionary)
signal action_triggered(action: Dictionary)

static var _instance: PlayerInput = null
static var instance: PlayerInput:
	get:
		return _instance

@export var input_disabled: bool = true

const tap_interval_msec: int = 500
const short_reverse_hold_time_sec: float = 0.15 # How long to hold down the reverse action to start reversing time

var current_intent: Vector2 = Vector2()
var current_action_direction: Vector2 = Vector2()
var is_shooting: bool = false
var current_acquired_target: Vector2 = Vector2()
var reverse_being_held: bool = false
var reverse_initiated: bool = false
var reverse_hold_time_sec: float = 0.
var reverse_tap_count: int = 0
var reverse_last_tap_at: int = Time.get_ticks_msec()

func set_disabled(yesno: bool) -> void:
	input_disabled = yesno

func _unhandled_key_input(event: InputEvent) -> void:
	var action = get_action(event)
	var just_pressed = event.is_pressed() and not event.is_echo()
	var was_shooting = is_shooting

	if "movement_intent" in action:
		current_intent = action["movement_intent"]

	if "action_direction" in action:
		current_action_direction = action["action_direction"]
		is_shooting = 0 < action["action_direction"].length()

	if was_shooting and not is_shooting:
		action["action_released"] = true

	if not was_shooting and is_shooting:
		action["action_initiated"] = true

	if event.is_action_pressed("replay") and just_pressed:
		if (Time.get_ticks_msec() - reverse_last_tap_at) < tap_interval_msec:
			reverse_tap_count += 1
		reverse_last_tap_at = Time.get_ticks_msec()
		reverse_being_held = true

	if event.is_action_released("replay"):
		reverse_being_held = false

	if not input_disabled and not action.is_empty():
		action_triggered.emit(action)

func _process(delta: float) -> void:
	if input_disabled: return

	# Handling Battle restart
	var time_control: Dictionary = {}
	if (Time.get_ticks_msec() - reverse_last_tap_at) > tap_interval_msec:
		reverse_tap_count = 0
	if 2 <= reverse_tap_count:
		reverse_tap_count = 0
		time_control["checkpoint_reset_triggered"] = true

	# Handling Timeline reverse
	if reverse_being_held:
		reverse_hold_time_sec += delta
		if reverse_hold_time_sec > short_reverse_hold_time_sec:
			if not reverse_initiated:
				reverse_initiated = true
				time_control["rewind_toggled"] = true
	if reverse_initiated:
		if not reverse_being_held:
			time_control["rewind_toggled"] = false
			reverse_hold_time_sec = 0.
			reverse_initiated = false

	if not time_control.is_empty(): time_control_triggered.emit(time_control)
	if is_shooting: action_triggered.emit({"action_direction": current_action_direction})

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
static func get_action(input_event: InputEvent) -> Dictionary:
	var action = Dictionary()
	
	var intent_direction = Vector2(0,0)
	var action_direction = Vector2(0,0)
	
	if input_event.is_action_pressed("movement_left"):
		intent_direction.x = -1
		
	if input_event.is_action_pressed("movement_right"):
		intent_direction.x = 1
		
	if input_event.is_action_pressed("movement_down"):
		intent_direction.y = 1

	if input_event.is_action_pressed("movement_up"):
		intent_direction.y = -1

	#if intent_direction.length():
	action["movement_intent"] = intent_direction

	if input_event.is_action_pressed("action_left"):
		action_direction.x = -1
	
	if input_event.is_action_pressed("action_right"):
		action_direction.x = 1

	if input_event.is_action_pressed("action_down"):
		action_direction.y = 1

	if input_event.is_action_pressed("action_up"):
		action_direction.y = -1

	#if action_direction.length():
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

func _on_timeline_rewind_stopped() -> void:
	is_shooting = false
