"""
## The temporal recorder stores data of the given @target within the battle on a given BattleTimeline
---
Stores motion in milliseconds resolution and prompted action in microseconds resolution
Requirements for Temporal Record and Playback: 
	- Parent node of recroder to have @get_transform and @get_velocity
	- Motion corrections of the parent node of the recroder(e.g. during rewind) are implemented through calling the parents @correct_motion_course function
	- (Optional) User inputs are stored through @process_input_action of the recorder
	- (Optional) Character control intent forces are stored together with motion
"""
extends Node2D

var stored_actions : Dictionary # key is in usec
var stored_motion : Dictionary # key is in msec

@export var triggers_per_second: int = 4
@onready var target : PhysicsBody2D = get_parent()

var last_time_flow = BattleTimeline.TimeFlow.FORWARD
var last_popped_motion
func _process(_delta: float) -> void:
	if BattleTimeline.instance.time_flow == BattleTimeline.TimeFlow.BACKWARD:
		# update stored actions
		while not stored_actions.is_empty() and stored_actions.keys().back() > BattleTimeline.instance.time_usec():
			stored_actions.erase(stored_actions.keys().back())

		# update stored motion
		while not stored_motion.is_empty() and stored_motion.keys().back() > BattleTimeline.instance.time_msec():
			last_popped_motion = { stored_motion.keys().back() : stored_motion[stored_motion.keys().back()]}
			stored_motion.erase(stored_motion.keys().back())
		if not stored_motion.is_empty() or last_popped_motion != null:
			var corrective_motion
			var time_to_motion
			if stored_motion.is_empty() and last_popped_motion != null:
				corrective_motion = last_popped_motion[last_popped_motion.keys()[0]]
				time_to_motion = abs(BattleTimeline.instance.time_since_msec(last_popped_motion.keys()[0]))
			if not stored_motion.is_empty() and last_popped_motion == null:
				corrective_motion = stored_motion[stored_motion.keys().back()]
				time_to_motion = abs(BattleTimeline.instance.time_since_msec(stored_motion.keys().back()))
			if not stored_motion.is_empty() and last_popped_motion != null:
				# The current reverse corrected time point is expected to be between the last popped key and the last stored key
				# --> In this case the earlier motion is selected with the corresponding time to interpolate to it
				corrective_motion = stored_motion[stored_motion.keys().back()]
				time_to_motion = abs(BattleTimeline.instance.time_since_msec(stored_motion.keys().back()))
			target.correct_motion_course(corrective_motion, time_to_motion)
	if BattleTimeline.instance.time_flow == BattleTimeline.TimeFlow.FORWARD \
		and last_time_flow == BattleTimeline.TimeFlow.BACKWARD:
			target.correct_motion_course(last_popped_motion[last_popped_motion.keys()[0]], 0.001)
	last_time_flow = BattleTimeline.instance.time_flow
var last_triggered = 0. 
var recording = false

## Restarts recording of the target, erasing all previous stored data
func start_recording() -> void:
	if !recording:
		recording = true
	stored_actions = Dictionary()
	stored_motion = Dictionary()
	last_triggered = 0. # Set to 0 to record first frame!

func stop_recording() -> Dictionary:
	var recorded_actions = stored_actions
	var recorded_motion = stored_motion
	stored_actions = Dictionary()
	stored_motion = Dictionary()
	recording = false
	return { "actions" : recorded_actions, "motion" :  recorded_motion }

func process_input_action(action) -> void:
	if BattleTimeline.instance.time_flow == BattleTimeline.TimeFlow.BACKWARD:
		return
	stored_actions[BattleTimeline.instance.time_usec()] = action

func _physics_process(_delta: float) -> void:
	if not recording or BattleTimeline.instance.time_flow == BattleTimeline.TimeFlow.BACKWARD \
		or abs(BattleTimeline.instance.time_since_msec(last_triggered)) <  (1000. / triggers_per_second):
			return
	last_triggered = BattleTimeline.instance.time_msec()
	var current_motion = {"transform": target.get_transform()}
	if "velocity" in target:
		current_motion["velocity"] = target.get_velocity()
	if "linear_velocity" in target:
		current_motion["linear_velocity"] = target.get_linear_velocity()
	if "angular_velocity" in target:
		current_motion["angular_velocity"] = target.get_angular_velocity()
	if target.has_node("controller"):
		current_motion["intent_force"] = target.get_node("controller").intent_force
		current_motion["internal_force"] = target.get_node("controller").internal_force
	stored_motion[last_triggered] = current_motion
