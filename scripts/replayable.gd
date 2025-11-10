extends Node2D

#region Variables to be set for the recorder before calling ready
var start_time_usec # in microseconds, from Time.get_ticks_usec()
var correction_interval_sec
var actions: Dictionary # key is in usec
var transforms: Dictionary # key is in msec
#endregion

@export var corrections_per_second = 4

@onready var start_time_msec = start_time_usec / 1000.
@onready var current_action_key = 0
@onready var current_transform_key = 0
@onready var replay_enabled = true
@onready var ship = get_parent()

var physics_interval_sec = 1. / Engine.physics_ticks_per_second
var time_since_last_physics_step_sec = 0.
var last_corrected

func reset() -> void:
	current_action_key = 0
	current_transform_key = 0
	replay_enabled = true
	start_time_usec = Time.get_ticks_usec()
	start_time_msec = Time.get_ticks_msec()
	last_corrected = start_time_msec

func _process(delta: float) -> void:
	# Estimate time until the next physics step
	time_since_last_physics_step_sec += delta
	if time_since_last_physics_step_sec >= physics_interval_sec:
		time_since_last_physics_step_sec -= physics_interval_sec
	
	if not replay_enabled or actions.keys().size() <= current_action_key:
		return

	# Apply actions
	var last_frame_duration_usec = Performance.get_monitor(Performance.TIME_PROCESS) * 1000000.
	var delta_to_next_action = actions.keys()[current_action_key] - (Time.get_ticks_usec() - start_time_usec)
	if delta_to_next_action < 0 or delta_to_next_action < (last_frame_duration_usec / 2.):
		if 0 < delta_to_next_action: # await the next opportunity to apply the input
			# but only wait for the 90% of the delta to account for delays in this function call (estimation)
			await get_tree().create_timer((delta_to_next_action) * 900000.).timeout 
		ship.process_input_action(actions[actions.keys()[current_action_key]])
		current_action_key += 1
		if actions.keys().size() <= current_action_key:
			replay_enabled = false
		return # don't apply position correction when applying input
	
	# Apply position correction
	# BUT only when the transform key points inside the transform array
	if( \
		current_transform_key < transforms.keys().size() \
		and (Time.get_ticks_msec() - last_corrected) > (1000. / corrections_per_second) \
	):
		while( \
			current_transform_key < transforms.keys().size() \
			and transforms.keys()[current_transform_key] < (Time.get_ticks_msec() - start_time_msec) \
		): # step the transforms pointer forward until the current start time frame is reached
			current_transform_key += 1
		if current_transform_key >= transforms.keys().size():
			return # No upcoming positions are stored
		var transform_stored_at = transforms.keys()[current_transform_key]
		var delta_to_next_transfrom = transform_stored_at - (Time.get_ticks_msec() - start_time_msec)
		if delta_to_next_transfrom >= (last_frame_duration_usec / 1000.):
			return # Do not apply transform if it's from a time after the current frame
		
		if( \
			0 < delta_to_next_transfrom \
			and delta_to_next_transfrom < (physics_interval_sec - time_since_last_physics_step_sec) * 1000. \
		): 
			# if needed, await the exact time to apply the position correction
			# but only wait for the 90% of the delta to account for delays in this function call (estimation)
			await get_tree().create_timer((delta_to_next_transfrom) * 9000.).timeout 
		if -(last_frame_duration_usec / 2.) < (delta_to_next_transfrom * 1000.):
			# only correct the position if it was relatively close to the current frame
			ship.overwrite_transform(transforms[transforms.keys()[current_transform_key]])
