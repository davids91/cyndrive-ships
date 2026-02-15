extends Node2D

#region init_before_ready: Variables to be set for the recorder before calling ready
var usec_records: Dictionary # key is in usec
var msec_records: Dictionary # key is in msec
#endregion

signal temporal_scope_changed(still_relevant: bool)

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

var is_in_scope: bool = true
func reset() -> void:
	is_in_scope = true
	current_action_key = 0
	current_msec_records_key = 0
	last_corrected = BattleTimeline.instance.time_msec()

func start_replay() -> void: 
	replay_enabled = true

func stop_replay() -> void:
	replay_enabled = false

var cached_frame_duration_usec: float = 1000000. / 30. # 30 fps to microseconds
var corrected_in_this_physics_loop: bool = false
var last_applied_usec_key: int = -1

func _process(delta: float) -> void:
	if not replay_enabled or not ship.in_battle():
		return

	# Monitor if the replayer is relevant
	if is_in_scope != is_within_current_time():
		is_in_scope = is_within_current_time()
		temporal_scope_changed.emit(is_in_scope)

	# Estimate time until the next physics step
	time_since_last_physics_step_sec += delta
	if time_since_last_physics_step_sec >= physics_interval_sec:
		time_since_last_physics_step_sec -= physics_interval_sec
		corrected_in_this_physics_loop = false

	# Step action pointer to closesr to actual time if needed
	var delta_to_current_action = INF
	var current_time_flow = BattleTimeline.instance.time_flow
	while abs(current_action_key) < usec_records.keys().size():
		delta_to_current_action = -BattleTimeline.instance.time_since_usec(usec_records.keys()[current_action_key])
		var delta_to_next_action = INF
		if abs(current_action_key + current_time_flow) < usec_records.keys().size():
			delta_to_next_action = -BattleTimeline.instance.time_since_usec(usec_records.keys()[current_action_key + current_time_flow])

		# Step the action pointer to the direction of the closest action
		if 0 < delta_to_current_action and delta_to_next_action < delta_to_current_action:
			if last_applied_usec_key != current_action_key: # Apply the current action if not applied already
				last_applied_usec_key = current_action_key
				ship.process_input_action(usec_records[usec_records.keys()[current_action_key]])
			current_action_key += current_time_flow
			delta_to_current_action = delta_to_next_action
		else: break # Can't step action pointer forward anymore, because it is at the correct spot

	# Apply upcoming action
	if ( # if there is any action stored for the current time
		abs(current_action_key) < usec_records.keys().size()
		and( # and if it's within the current estimated frametime
			delta_to_current_action * current_time_flow < 0.
			or abs(delta_to_current_action) <= cached_frame_duration_usec
		)
	):
		last_applied_usec_key = current_action_key
		ship.process_input_action(usec_records[usec_records.keys()[current_action_key]])
		current_action_key += current_time_flow
		return # do not correct msec_records when an action was applied

	# Move msec_records pointer to the closest time point
	var delta_to_current_msec_records = INF
	var delta_to_next_msec_records = INF
	if abs(current_msec_records_key) < msec_records.keys().size():
		delta_to_current_msec_records = ( \
			-BattleTimeline.instance.time_since_msec(msec_records.keys()[current_msec_records_key]) \
			* current_time_flow \
		)

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

	# Apply temporal state correction
	if(
		not corrected_in_this_physics_loop
		and abs(current_msec_records_key) < msec_records.keys().size()
		and abs(delta_to_current_msec_records) <= (cached_frame_duration_usec / 1000.)
		and (
			BattleTimeline.instance.time_flow == BattleTimeline.TimeFlow.BACKWARD
			or abs(BattleTimeline.instance.time_since_msec(last_corrected)) > (1000. / corrections_per_second)
		)
	):
		var snapshot_to_apply = msec_records[msec_records.keys()[current_msec_records_key]]
		if( # Do not apply health during replays, only when reversing!
			"health" in snapshot_to_apply
			and BattleTimeline.instance.time_flow == BattleTimeline.TimeFlow.FORWARD
		):
			snapshot_to_apply.erase("health")
		ship.correct_temporal_state(snapshot_to_apply, delta_to_current_msec_records)
		last_corrected = BattleTimeline.instance.time_msec()
		current_msec_records_key += BattleTimeline.instance.time_flow
		corrected_in_this_physics_loop = true

		# Also update average frametime
		cached_frame_duration_usec = lerp(cached_frame_duration_usec, Performance.get_monitor(Performance.TIME_PROCESS) * 1000000., 0.5)
