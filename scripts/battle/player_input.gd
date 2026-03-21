extends Node2D

class_name PlayerInput

signal view_control_triggered(action:Dictionary)
signal time_control_triggered(action: Dictionary)
signal action_triggered(action: Dictionary)

static var _instance: PlayerInput = null
static var instance: PlayerInput:
	get:
		return _instance

@export var input_disabled: bool = true:
	set(value):
		input_disabled = value
		is_shooting = false
		reverse_being_held = false
		current_action_direction = Vector2.ZERO

const tap_interval_msec: int = 500
const short_reverse_hold_time_sec: float = 0.15 # How long to hold down the reverse action to start reversing time

var movement_intent: Vector2 = Vector2()
var current_action_direction: Vector2 = Vector2()
var is_shooting: bool = false
var current_acquired_target: Vector2 = Vector2()
var reverse_being_held: bool = false
var slowdown_being_held: bool = false
var reverse_initiated: bool = false
var reverse_hold_time_sec: float = 0.
var accumulated_slowdown_value_sec: float = 0.

@export var zoom_range: float = 0.39
@export var zoom_center: float = 0.4
var current_zoom_value: float = zoom_center
func _unhandled_input(event: InputEvent) -> void:
	var action = get_action(event)
	var just_pressed = event.is_pressed() and not event.is_echo()
	var was_shooting = is_shooting

	if "movement_intent" in action:
		movement_intent += action["movement_intent"]
		action["movement_intent"] = movement_intent

	if "action_direction" in action:
		current_action_direction += action["action_direction"]
		action["action_direction"] = current_action_direction
		is_shooting = 0 < action["action_direction"].length()

	if was_shooting and not is_shooting:
		action["action_released"] = true

	if not was_shooting and is_shooting:
		action["action_initiated"] = true

	if event.is_action_pressed("slowdown") and just_pressed:
		slowdown_being_held = !slowdown_being_held

	if event.is_action_pressed("replay") and just_pressed and not slowdown_being_held:
		reverse_being_held = true
	if event.is_action_released("replay"):
		reverse_being_held = false

	if event.is_action_pressed("reset_round") and just_pressed:
		slowdown_being_held = false
		accumulated_slowdown_value_sec = 0.
		time_control_triggered.emit({
			"checkpoint_reset_triggered": true,
			"slowdown": 1.
		})

	if event.is_action_pressed("zoom_in"):
		current_zoom_value = max(current_zoom_value * 0.95, zoom_center * (1. - zoom_range))
		view_control_triggered.emit({"zoom": current_zoom_value})
	elif event.is_action_pressed("zoom_out"):
		current_zoom_value = min(current_zoom_value * 1.05, zoom_center * (1. + zoom_range))
		view_control_triggered.emit({"zoom": current_zoom_value})

	if not input_disabled and not action.is_empty():
		action_triggered.emit(action)

@export var slowdown_max_subtract_value: float = Difficulty.gameplay_speed * 0.9
@export var slowdown_max_hold_sec: float = 3.
@export var slowdown_regenerate_speed: float = 0.5
func _process(delta: float) -> void:
	if input_disabled: return
	var time_control: Dictionary = {}

	# Handling slowdown:
	if slowdown_being_held: accumulated_slowdown_value_sec += delta
	elif 0. < accumulated_slowdown_value_sec:
		accumulated_slowdown_value_sec = max(
			0., accumulated_slowdown_value_sec - delta * slowdown_regenerate_speed
		)
	if 0. < accumulated_slowdown_value_sec:
		time_control["slowdown"] = round((1. - min(
			slowdown_max_subtract_value,
			(
				pow(min(accumulated_slowdown_value_sec, slowdown_max_hold_sec), 2.) 
				/ (slowdown_max_hold_sec * slowdown_max_hold_sec)
			)
		)) * 1000.) / 1000.

	# Handling Timeline reverse
	if reverse_being_held and not slowdown_being_held:
		reverse_hold_time_sec += delta
		if reverse_hold_time_sec > short_reverse_hold_time_sec:
			if not reverse_initiated:
				reverse_initiated = true
				time_control["rewind_toggled"] = true
				slowdown_being_held = false
				accumulated_slowdown_value_sec = 0.
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
	action["zoom"]: set camera zoom level(not stored in temporal records)
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
	if input_event.is_action_released("movement_left"):
		intent_direction.x = 1
	if input_event.is_action_released("movement_right"):
		intent_direction.x = -1
	if input_event.is_action_released("movement_down"):
		intent_direction.y = -1
	if input_event.is_action_released("movement_up"):
		intent_direction.y = 1

	action["movement_intent"] = intent_direction

	if input_event.is_action_pressed("action_left"):
		action_direction.x = -1
	if input_event.is_action_pressed("action_right"):
		action_direction.x = 1
	if input_event.is_action_pressed("action_down"):
		action_direction.y = 1
	if input_event.is_action_pressed("action_up"):
		action_direction.y = -1
	if input_event.is_action_released("action_left"):
		action_direction.x = 1
	if input_event.is_action_released("action_right"):
		action_direction.x = -1
	if input_event.is_action_released("action_down"):
		action_direction.y = -1
	if input_event.is_action_released("action_up"):
		action_direction.y = 1

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
