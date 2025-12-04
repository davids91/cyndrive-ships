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
func _process(_delta: float) -> void:
	if BattleTimeline.instance.time_flow == BattleTimeline.TimeFlow.BACKWARD:
		# update stored actions
		while not usec_records.is_empty() and usec_records.keys().back() > BattleTimeline.instance.time_usec():
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
		and last_time_flow == BattleTimeline.TimeFlow.BACKWARD:
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
	return { "actions" : recorded_actions, "motion" :  recorded_motion }

func process_input_action(action) -> void:
	if BattleTimeline.instance.time_flow == BattleTimeline.TimeFlow.BACKWARD:
		return
	usec_records[BattleTimeline.instance.time_usec()] = action

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
	if target.has_node("health"):
		current_snapshot["health"] = target.get_node("health").value()
	if target.has_node("controller"):
		current_snapshot["intent_force"] = target.get_node("controller").intent_force
		current_snapshot["internal_force"] = target.get_node("controller").internal_force
	msec_records[last_triggered] = current_snapshot
