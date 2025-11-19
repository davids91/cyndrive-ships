extends Node2D

@export var triggers_per_second: int = 4

var recording = false
var stored_actions : Dictionary # key is in usec
var stored_transforms : Dictionary # key is in msec

@onready var target : CollisionObject2D = get_parent()
@onready var start_time_usec = Time.get_ticks_usec()
@onready var start_time_msec = Time.get_ticks_usec()
@onready var last_triggered = Time.get_ticks_msec()

func start_recording():
	if !recording:
		recording = true
	stored_actions = Dictionary()
	stored_transforms = Dictionary()
	start_time_usec = Time.get_ticks_usec()
	start_time_msec = Time.get_ticks_msec()
	last_triggered = Time.get_ticks_msec()

func stop_recording() -> Dictionary:
	if recording:
		recording = false
		var recorded_actions = stored_actions
		var recorded_transforms = stored_transforms
		stored_actions = Dictionary()
		stored_transforms = Dictionary()
		return { "actions" : recorded_actions, "transforms" :  recorded_transforms }
	stored_actions = Dictionary()
	return { "actions" : {}, "transforms" :  {} }

func process_input_action(action) -> void:
	stored_actions[Time.get_ticks_usec() - start_time_usec] = action

func _physics_process(delta: float) -> void:
	if !recording or (Time.get_ticks_msec() - last_triggered) < (1000. / triggers_per_second):
		return
	last_triggered = Time.get_ticks_msec()
	stored_transforms[last_triggered - start_time_msec] = target.get_transform()
