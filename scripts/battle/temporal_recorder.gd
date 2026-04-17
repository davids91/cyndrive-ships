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

var usec_records : Dictionary[int, Dictionary] # key is in usec
var msec_records : Dictionary[float, Dictionary] # key is in msec

@export var triggers_per_second: int = 4
@export var autostart: bool = false

@onready var target : Node2D = get_parent()

var last_time_flow: BattleTimeline.TimeFlow = BattleTimeline.TimeFlow.FORWARD
var last_snapshot: Dictionary

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

func _ready() -> void: if autostart: start_recording()

func _process(_delta: float) -> void:
	if BattleTimeline.time_flow == BattleTimeline.TimeFlow.BACKWARD:
		# Erase "future" usec records when rewinding
		var usec_keys: Array[int] = usec_records.keys()
		while not usec_records.is_empty() and usec_keys.back() > BattleTimeline.instance.time_usec():
			if ( # Correct actions for reversed timeflow and apply them
				target.has_node("controller")
				and not (target.has_node("replayer")
				and target.get_node("replayer").is_within_current_time())
			):
				var snapshot_to_apply = usec_records[usec_keys.back()]
				reverse_action_key_in_snapshot("boost", snapshot_to_apply)
				reverse_action_key_in_snapshot("action", snapshot_to_apply)
				target.process_input_action(snapshot_to_apply)
			usec_records.erase(usec_keys.back())
			usec_keys.pop_back()

		# Erase "future" msec records when rewinding
		var msec_keys: Array[float] = msec_records.keys()
		while not msec_records.is_empty() and msec_keys.back() > BattleTimeline.instance.time_msec():
			last_snapshot = { msec_keys.back() : msec_records[msec_keys.back()]}
			msec_records.erase(msec_keys.back())
			msec_keys.pop_back()

		# Apply msec record if it is close enough
		if not msec_records.is_empty() or (last_snapshot != null and not last_snapshot.is_empty()):
			var corrective_snapshot: Dictionary
			var time_to_snapshot: float
			if msec_records.is_empty() and last_snapshot != null:
				corrective_snapshot = last_snapshot[last_snapshot.keys()[0]]
				time_to_snapshot = abs(BattleTimeline.instance.time_since_msec(last_snapshot.keys()[0]))
			if not msec_records.is_empty() and last_snapshot == null:
				corrective_snapshot = msec_records[msec_keys.back()]
				time_to_snapshot = abs(BattleTimeline.instance.time_since_msec(msec_keys.back()))
			if not msec_records.is_empty() and last_snapshot != null:
				# The current reverse corrected time point is expected to be between the last popped key and the last stored key
				# --> In this case the earlier motion is selected with the corresponding time to interpolate to it
				corrective_snapshot = msec_records[msec_keys.back()]
				time_to_snapshot = abs(BattleTimeline.instance.time_since_msec(msec_keys.back()))
			target.correct_temporal_state(corrective_snapshot, time_to_snapshot)

	if BattleTimeline.time_flow == BattleTimeline.TimeFlow.FORWARD \
		and last_time_flow == BattleTimeline.TimeFlow.BACKWARD \
		and last_snapshot != null and not last_snapshot.is_empty():
			last_snapshot.erase("health") #TechDebt: while motion might need to be restored, health shouldt be restored in this situation
			target.correct_temporal_state(last_snapshot[last_snapshot.keys()[0]])
	last_time_flow = BattleTimeline.time_flow

var last_triggered: float = 0.
var recording: bool = false
## Restarts recording of the target, erasing all previous stored data
func start_recording() -> void:
	if !recording: recording = true
	usec_records = {}
	msec_records = {}
	last_triggered = 0. # Set to 0 to record first frame!

func stop_recording() -> Dictionary:
	var recorded_actions = usec_records
	var recorded_motion = msec_records
	usec_records = {}
	msec_records = {}
	recording = false
	return { "action" : recorded_actions, "temporal_snapshots" :  recorded_motion }

func process_input_action(action) -> void:
	if BattleTimeline.time_flow == BattleTimeline.TimeFlow.BACKWARD:
		return
	usec_records[BattleTimeline.instance.time_usec()] = action

var marked_usec_index: int = 0
var marked_msec_index: int = 0
func mark_current_time() -> void:
	marked_usec_index = usec_records.size() - 1
	marked_msec_index = msec_records.size() - 1

func copy_marked_records(last_usec_timestamp: int, last_msec_timestamp: float) -> Dictionary:
	var recorded_action = {}
	if not usec_records.is_empty():
		var usec_keys: Array[int] = usec_records.keys()
		# rewind marked index values to be inside bounds, pointing after the last stored record in the replayer
		marked_usec_index = min(marked_usec_index, usec_records.size() - 1)
		var usec_marker = usec_keys[marked_usec_index]
		while usec_marker > last_usec_timestamp and 0 < usec_marker:
			marked_usec_index -= 1
			usec_marker = usec_keys[marked_usec_index]
		marked_usec_index = min(marked_usec_index + 1, usec_records.size() - 1)

		# Grab the relevant records
		if usec_keys[marked_usec_index] > last_usec_timestamp:
			for index in range(marked_usec_index, usec_records.size()):
				var key = usec_keys[marked_usec_index]
				recorded_action[key] = usec_records[key]

	var recorded_motion = {}
	if not msec_records.is_empty():
		var msec_keys: Array[float] = msec_records.keys()
		# rewind marked index values to be inside bounds, pointing after the last stored record in the replayer
		marked_msec_index = min(marked_msec_index, msec_records.size() - 1)
		var msec_marker = msec_keys[marked_msec_index]
		while msec_marker > last_msec_timestamp and 0 < msec_marker:
			marked_msec_index -= 1
			msec_marker = msec_keys[marked_msec_index]
		marked_msec_index = min(marked_msec_index + 1, msec_records.size() - 1)
		# Grab the relevant records
		if msec_keys[marked_msec_index] > last_msec_timestamp:
			for index in range(marked_msec_index, msec_records.size()):
				var key = msec_keys[index]
				recorded_motion[key] = msec_records[key]

	return { "action" : recorded_action, "temporal_snapshots" :  recorded_motion }

func _physics_process(_delta: float) -> void:
	if not recording or BattleTimeline.time_flow == BattleTimeline.TimeFlow.BACKWARD \
		or abs(BattleTimeline.instance.time_since_msec(last_triggered)) <  (1000. / triggers_per_second):
			return
	msec_records[BattleTimeline.instance.time_msec()] = target.get_snapshot()
