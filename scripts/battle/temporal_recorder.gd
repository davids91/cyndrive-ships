"""
## The temporal recorder stores data of the given @target within the battle on a given BattleTimeline
---
Stores motion, health in milliseconds and prompted action in microseconds resolution
Requirements for Temporal Record and Playback: 
	- Parent node of recroder to have @get_transform and @get_velocity
	- The parent node of the recroder is updated(e.g. during rewind) through @correct_temporal_state function
	- (Optional) User inputs are stored through @process_input_action of the recorder
	- (Optional) Character control intent forces are stored together with motion
"""
extends Node2D

var usec_records : Dictionary # key is in usec
var msec_records : Dictionary # key is in msec

@export var triggers_per_second: int = 4

@onready var target : PhysicsBody2D = get_parent()

var last_time_flow = BattleTimeline.TimeFlow.FORWARD
var last_snapshot

static func reverse_action_key_in_snapshot(key: String, snapshot: Dictionary) -> void:
	var initiated_key = key + "_initiated"
	var released_key = key + "_released"
	if initiated_key in snapshot:
		var value = snapshot[initiated_key]
		snapshot.erase(initiated_key)
		snapshot[released_key] = value
	elif released_key in snapshot:
		var value = snapshot[released_key]
		snapshot.erase(released_key)
		snapshot[initiated_key] = value

func _process(_delta: float) -> void:
	if BattleTimeline.instance.time_flow == BattleTimeline.TimeFlow.BACKWARD:
		# update stored actions
		while not usec_records.is_empty() and usec_records.keys().back() > BattleTimeline.instance.time_usec():
			if target.has_node("controller"): # Correct actions for reversed timeflow and apply them
				var snapshot_to_apply = usec_records[usec_records.keys().back()]
				reverse_action_key_in_snapshot("boost", snapshot_to_apply)
				reverse_action_key_in_snapshot("pewpew", snapshot_to_apply)
				target.process_input_action(snapshot_to_apply)
			usec_records.erase(usec_records.keys().back())

		# update stored msec entries
		while not msec_records.is_empty() and msec_records.keys().back() > BattleTimeline.instance.time_msec():
			last_snapshot = { msec_records.keys().back() : msec_records[msec_records.keys().back()]}
			msec_records.erase(msec_records.keys().back())
		if not msec_records.is_empty() or last_snapshot != null:
			var corrective_snapshot
			var time_to_snapshot
			if msec_records.is_empty() and last_snapshot != null:
				corrective_snapshot = last_snapshot[last_snapshot.keys()[0]]
				time_to_snapshot = abs(BattleTimeline.instance.time_since_msec(last_snapshot.keys()[0]))
			if not msec_records.is_empty() and last_snapshot == null:
				corrective_snapshot = msec_records[msec_records.keys().back()]
				time_to_snapshot = abs(BattleTimeline.instance.time_since_msec(msec_records.keys().back()))
			if not msec_records.is_empty() and last_snapshot != null:
				# The current reverse corrected time point is expected to be between the last popped key and the last stored key
				# --> In this case the earlier motion is selected with the corresponding time to interpolate to it
				corrective_snapshot = msec_records[msec_records.keys().back()]
				time_to_snapshot = abs(BattleTimeline.instance.time_since_msec(msec_records.keys().back()))
			target.correct_temporal_state(corrective_snapshot, time_to_snapshot)
	if BattleTimeline.instance.time_flow == BattleTimeline.TimeFlow.FORWARD \
		and last_time_flow == BattleTimeline.TimeFlow.BACKWARD \
		and last_snapshot != null:
			target.correct_temporal_state(last_snapshot[last_snapshot.keys()[0]], 0.001)
	last_time_flow = BattleTimeline.instance.time_flow
var last_triggered = 0. 
var recording = false

## Restarts recording of the target, erasing all previous stored data
func start_recording() -> void:
	if !recording:
		recording = true
	usec_records = Dictionary()
	msec_records = Dictionary()
	last_triggered = 0. # Set to 0 to record first frame!

func stop_recording() -> Dictionary:
	var recorded_actions = usec_records
	var recorded_motion = msec_records
	usec_records = Dictionary()
	msec_records = Dictionary()
	recording = false
	return { "action" : recorded_actions, "motion" :  recorded_motion }

func process_input_action(action) -> void:
	if BattleTimeline.instance.time_flow == BattleTimeline.TimeFlow.BACKWARD:
		return
	usec_records[BattleTimeline.instance.time_usec()] = action

var marked_usec_index: int = 0
var marked_msec_index: int = 0
func mark_current_time() -> void:
	marked_usec_index = usec_records.keys().size() - 1
	marked_msec_index = msec_records.keys().size() - 1

func copy_marked_records(last_usec_timestamp: int, last_msec_timestamp: float) -> Dictionary:
	var recorded_action = {}
	if not usec_records.is_empty():
		# rewind marked index values to be inside bounds, pointing after the last stored record in the replayer
		marked_usec_index = min(marked_usec_index, usec_records.keys().size() - 1)
		var usec_marker = usec_records.keys()[marked_usec_index]
		while usec_marker > last_usec_timestamp and 0 < usec_marker:
			marked_usec_index -= 1
			usec_marker = usec_records.keys()[marked_usec_index]
		marked_usec_index = min(marked_usec_index + 1, usec_records.keys().size() - 1)

		# Grab the relevant records
		if usec_records.keys()[marked_usec_index] > last_usec_timestamp:
			for index in range(marked_usec_index, usec_records.keys().size()):
				var key = usec_records.keys()[marked_usec_index]
				recorded_action[key] = usec_records[key]

	var recorded_motion = {}
	if not msec_records.is_empty():
		# rewind marked index values to be inside bounds, pointing after the last stored record in the replayer
		marked_msec_index = min(marked_msec_index, msec_records.keys().size() - 1)
		var msec_marker = msec_records.keys()[marked_msec_index]
		while msec_marker > last_msec_timestamp and 0 < msec_marker:
			marked_msec_index -= 1
			msec_marker = msec_records.keys()[marked_msec_index]
		marked_msec_index = min(marked_msec_index + 1, msec_records.keys().size() - 1)

		# Grab the relevant records
		if  msec_records.keys()[marked_msec_index] > last_msec_timestamp:
			for index in range(marked_msec_index, msec_records.keys().size()):
				var key = msec_records.keys()[index]
				recorded_motion[key] = msec_records[key]
	return { "action" : recorded_action, "motion" :  recorded_motion }


func _physics_process(_delta: float) -> void:
	if not recording or BattleTimeline.instance.time_flow == BattleTimeline.TimeFlow.BACKWARD \
		or abs(BattleTimeline.instance.time_since_msec(last_triggered)) <  (1000. / triggers_per_second):
			return
	last_triggered = BattleTimeline.instance.time_msec()
	var current_snapshot = {"transform": target.get_transform()}
	if "velocity" in target:
		current_snapshot["velocity"] = target.get_velocity()
	if "linear_velocity" in target:
		current_snapshot["linear_velocity"] = target.get_linear_velocity()
	if "angular_velocity" in target:
		current_snapshot["angular_velocity"] = target.get_angular_velocity()
	if target.has_node("controller"):
		current_snapshot["internal_force"] = target.get_node("controller").internal_force
	if "health" in target:
		current_snapshot["health"] = target.health
	if target.has_node("energy_systems"):
		current_snapshot["energy"] = target.get_node("energy_systems").temporal_snapshot()
	msec_records[last_triggered] = current_snapshot
