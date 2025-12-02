extends Node2D

#region init_before_ready: Variables to be set for the recorder before calling ready
var actions: Dictionary # key is in usec
var motion: Dictionary # key is in msec
#endregion

@export var corrections_per_second = 4.

@onready var current_action_key = 0
@onready var current_motion_key = 0
@onready var replay_enabled = false
@onready var ship = get_parent()

var physics_interval_sec = 1. / Engine.physics_ticks_per_second
var time_since_last_physics_step_sec = 0.
var last_corrected = 0.

func reset() -> void:
	current_action_key = 0
	current_motion_key = 0
	last_corrected = BattleTimeline.instance.time_msec()

func start_replay() -> void: 
	replay_enabled = true

func stop_replay() -> void:
	replay_enabled = false

func _process(delta: float) -> void:
	if not replay_enabled:
		return

	# Estimate time until the next physics step
	time_since_last_physics_step_sec += delta
	if time_since_last_physics_step_sec >= physics_interval_sec:
		time_since_last_physics_step_sec -= physics_interval_sec

	# Set action pointer to be the closest to actual time
	var delta_to_current_action = INF
	var current_time_flow = BattleTimeline.instance.time_flow
	var last_frame_duration_usec = Performance.get_monitor(Performance.TIME_PROCESS) * 1000000.
	if abs(current_action_key) < actions.keys().size():
		delta_to_current_action = -BattleTimeline.instance.time_since_usec(actions.keys()[current_action_key])
		while true:
			var delta_to_next_action = INF
			if abs(current_action_key + current_time_flow) < actions.keys().size():
				delta_to_next_action = -BattleTimeline.instance.time_since_usec(actions.keys()[current_action_key + current_time_flow])
			if 0 < delta_to_current_action and delta_to_next_action < delta_to_current_action:
				current_action_key += current_time_flow
				delta_to_current_action = delta_to_next_action
			else:
				break
	
	if abs(current_motion_key) >= motion.keys().size():
		return # Do not correct position when out of timeframe
	
	# Apply nearest action ONLY when time is flowing forward and the action is near the current timepoint
	if current_time_flow == BattleTimeline.TimeFlow.FORWARD \
		and (delta_to_current_action < 0 or delta_to_current_action < (last_frame_duration_usec / 2.)):
		if 0 < delta_to_current_action: # await the next opportunity to apply the input
			# but only wait for the 90% of the delta to account for delays in this function call (estimation)
			await get_tree().create_timer(delta_to_current_action * 900000.).timeout 
		ship.process_input_action(actions[actions.keys()[current_action_key]])
		current_action_key += current_time_flow
		return # do not corrigate motion when an action was applieddd
	
	# Move motion pointer to the closest time point
	var delta_to_current_motion = ( \
		-BattleTimeline.instance.time_since_msec(motion.keys()[current_motion_key]) \
		* current_time_flow \
	)
	var delta_to_next_motion = INF
	while abs(current_motion_key + current_time_flow) < motion.keys().size():
		delta_to_next_motion = ( \
			-BattleTimeline.instance.time_since_msec(motion.keys()[current_motion_key + current_time_flow]) \
			* current_time_flow \
		)
		if abs(delta_to_next_motion) < abs(delta_to_current_motion):
			current_motion_key += current_time_flow
			delta_to_current_motion = delta_to_next_motion
		else:
			break
			
	# Apply position correction
	var time_to_next_physics_step_ms = (physics_interval_sec - time_since_last_physics_step_sec) * 1000.
	if( \
		abs(current_motion_key) < motion.keys().size() \
		and abs(delta_to_current_motion) <= (last_frame_duration_usec / 1000.) \
		and ( \
			BattleTimeline.instance.time_flow == BattleTimeline.TimeFlow.BACKWARD \
			or abs(BattleTimeline.instance.time_since_msec(last_corrected)) > (1000. / corrections_per_second) \
		) \
	):
		# Calculate the motion to set, try to interpolate if a preious frame is available
		var motion_to_set = motion[motion.keys()[current_motion_key]]
		var index_delta_for_motion_interpolation = sign( BattleTimeline.instance.time_msec() - motion.keys()[current_motion_key] )
		
		# Update delta to current motion, including the estimation to the next physics step
		delta_to_current_motion = motion.keys()[current_motion_key] - (BattleTimeline.instance.time_msec() + time_to_next_physics_step_ms)
		if 0 != index_delta_for_motion_interpolation \
			and current_motion_key + index_delta_for_motion_interpolation >=  0 \
			and current_motion_key + index_delta_for_motion_interpolation < motion.keys().size():
				# Interpolate between the two positions stored at the closest timeframe
				# --> Use estimated time when the next physics step is going to take place
				var previous_motion_distance = abs( \
					motion.keys()[current_motion_key + index_delta_for_motion_interpolation] \
					- (BattleTimeline.instance.time_msec() + time_to_next_physics_step_ms) \
				)
				motion_to_set = BattleTimeline.lerp_motion( \
					motion[motion.keys()[current_motion_key]], \
					motion[motion.keys()[current_motion_key + index_delta_for_motion_interpolation]], \
					previous_motion_distance / (previous_motion_distance + abs(delta_to_current_motion))
				)
		ship.correct_motion_course(motion_to_set, delta_to_current_motion)
		last_corrected = BattleTimeline.instance.time_msec()
		current_motion_key += BattleTimeline.instance.time_flow
