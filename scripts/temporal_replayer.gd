extends Node2D

#region init_before_ready: Variables to be set for the recorder before calling ready
var usec_records: Dictionary # key is in usec
var msec_records: Dictionary # key is in msec
#endregion

@export var corrections_per_second: float = 4.

@onready var current_action_key: int = 0
@onready var current_msec_records_key: float = 0
@onready var replay_enabled: bool = false
@onready var ship = get_parent()

var physics_interval_sec: float = 1. / Engine.physics_ticks_per_second
var time_since_last_physics_step_sec: float = 0.
var last_corrected: float = 0.

func is_within_current_time() -> bool:
	var current_time_msec = BattleTimeline.instance.time_msec()
	var current_time_usec = BattleTimeline.instance.time_usec()
	return (
		(
			not msec_records.is_empty()
			and current_time_msec >= msec_records.keys()[0] and current_time_msec < msec_records.keys().back()
		) or (
			not usec_records.is_empty()
			and current_time_usec >= usec_records.keys()[0] and current_time_usec < usec_records.keys().back()
		)
	)

func reset() -> void:
	current_action_key = 0
	current_msec_records_key = 0
	last_corrected = BattleTimeline.instance.time_msec()

func start_replay() -> void: 
	replay_enabled = true

func stop_replay() -> void:
	replay_enabled = false

var cached_frame_duration_usec: float = 1000000. / 30. # 30 fps to microseconds
var corrected_in_this_physics_loop: bool = false
func _process(delta: float) -> void:
	if not replay_enabled:
		return

	# Estimate time until the next physics step
	time_since_last_physics_step_sec += delta
	if time_since_last_physics_step_sec >= physics_interval_sec:
		time_since_last_physics_step_sec -= physics_interval_sec
		corrected_in_this_physics_loop = false

	# Set action pointer to be the closest to actual time
	var delta_to_current_action = INF
	var current_time_flow = BattleTimeline.instance.time_flow
	if abs(current_action_key) < usec_records.keys().size():
		delta_to_current_action = -BattleTimeline.instance.time_since_usec(usec_records.keys()[current_action_key])
		while true:
			var delta_to_next_action = INF
			if abs(current_action_key + current_time_flow) < usec_records.keys().size():
				delta_to_next_action = -BattleTimeline.instance.time_since_usec(usec_records.keys()[current_action_key + current_time_flow])
			if 0 < delta_to_current_action and delta_to_next_action < delta_to_current_action:
				current_action_key += current_time_flow
				delta_to_current_action = delta_to_next_action
			else:
				break
	
	if abs(current_msec_records_key) >= msec_records.keys().size():
		return # Do not correct position when out of timeframe, or already corrected in this physics loop
	
	# Apply nearest action ONLY when time is flowing forward and the action is near the current timepoint
	if current_time_flow == BattleTimeline.TimeFlow.FORWARD \
		and (delta_to_current_action < 0 or delta_to_current_action < (cached_frame_duration_usec / 2.)):
			if 0 < delta_to_current_action: # await the next opportunity to apply the input
				# but only wait for the 90% of the delta to account for delays in this function call (estimation)
				var key_to_apply = current_action_key
				get_tree().create_timer(delta_to_current_action / 900000.).connect("timeout", func():
					ship.process_input_action(usec_records[usec_records.keys()[key_to_apply]])
				)
			else:
				ship.process_input_action(usec_records[usec_records.keys()[current_action_key]])
			current_action_key += current_time_flow
			return # do not corrigate msec_records when an action was applieddd
	
	# Move msec_records pointer to the closest time point
	var delta_to_current_msec_records = ( \
		-BattleTimeline.instance.time_since_msec(msec_records.keys()[current_msec_records_key]) \
		* current_time_flow \
	)
	var delta_to_next_msec_records = INF
	while abs(current_msec_records_key + current_time_flow) < msec_records.keys().size():
		delta_to_next_msec_records = ( \
			-BattleTimeline.instance.time_since_msec(msec_records.keys()[current_msec_records_key + current_time_flow]) \
			* current_time_flow \
		)
		if abs(delta_to_next_msec_records) < abs(delta_to_current_msec_records):
			current_msec_records_key += current_time_flow
			delta_to_current_msec_records = delta_to_next_msec_records
		else:
			break

	# Apply position correction
	if(
		not corrected_in_this_physics_loop
		and abs(current_msec_records_key) < msec_records.keys().size()
		and abs(delta_to_current_msec_records) <= (cached_frame_duration_usec / 1000.)
		and (
			BattleTimeline.instance.time_flow == BattleTimeline.TimeFlow.BACKWARD
			or abs(BattleTimeline.instance.time_since_msec(last_corrected)) > (1000. / corrections_per_second)
		)
	):
		ship.correct_temporal_state(msec_records[msec_records.keys()[current_msec_records_key]], delta_to_current_msec_records)
		last_corrected = BattleTimeline.instance.time_msec()
		current_msec_records_key += BattleTimeline.instance.time_flow
		corrected_in_this_physics_loop = true

		# Also update average frametime
		cached_frame_duration_usec = lerp(cached_frame_duration_usec, Performance.get_monitor(Performance.TIME_PROCESS) * 1000000., 0.5)
