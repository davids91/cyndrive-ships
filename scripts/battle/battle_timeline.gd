class_name BattleTimeline extends Node

static var _instance: BattleTimeline = null
static var instance: BattleTimeline:
	get: return _instance

static var time_flow: TimeFlow = TimeFlow.FORWARD:
	get: return TimeFlow.FORWARD if not instance else instance._time_flow

enum TimeFlow {FORWARD = 1, BACKWARD = -1}

signal round_reset()
signal rewind_started()
signal rewind_stopped()
signal checkpoint_triggered()

var _time_flow : TimeFlow = TimeFlow.FORWARD
var player_timeline_start_msec: float
var player_timeline_start_usec: int
var player_rewind_amount_sec: float

@export var time_reverse_acceleration: float = 1.0025
var reverse_speed: float = 1.
var time_accrued_usec: int = 0
var time_accured_msec: float = 0.0

var _time_flow_ll: TimeFlow = _time_flow # Time Flow Last Loop
func _process(delta: float) -> void:
	if _time_flow == TimeFlow.BACKWARD:
		if player_rewind_amount_sec * 1000. < time_accured_msec:
			reverse_speed *= time_reverse_acceleration
			player_rewind_amount_sec += delta * reverse_speed
		else: finish_reverse()
	else:
		if _time_flow_ll != _time_flow_ll: finish_reverse()
		time_accured_msec += delta * 1000.
		time_accrued_usec += int(delta * 1000000.)
	_time_flow_ll = _time_flow

func start_reverse() -> void:
	if _time_flow != TimeFlow.BACKWARD: rewind_started.emit()
	_time_flow = TimeFlow.BACKWARD

func finish_reverse() -> void:
	# Correct start time so records are stored with the actual relative timestamp moving forward
	# Push it forward with the double of the rewind time --> time spent while reversing AND time reversed
	time_accured_msec -= player_rewind_amount_sec * 1000
	time_accrued_usec -= int(player_rewind_amount_sec * 1000000.)
	player_rewind_amount_sec = 0.
	reverse_speed = 1.
	_time_flow = TimeFlow.FORWARD
	rewind_stopped.emit()

func slowdown_value() -> float:
	return Difficulty.slowdown_multiplier

# Set the current time as 0 without emitting a round reset signal
func checkpoint() -> void:
	checkpoint_triggered.emit()
	time_accrued_usec = 0
	time_accured_msec = 0.0
	_time_flow = TimeFlow.FORWARD
	player_timeline_start_msec = Time.get_ticks_msec()
	player_timeline_start_usec = Time.get_ticks_usec()
	player_rewind_amount_sec = 0.

## Resetting sets the relative timestamp to be of the current time, and restarts the battle
func reset() -> void:
	time_accrued_usec = 0
	time_accured_msec = 0.0
	_time_flow = TimeFlow.FORWARD
	player_timeline_start_msec = Time.get_ticks_msec()
	player_timeline_start_usec = Time.get_ticks_usec()
	player_rewind_amount_sec = 0.
	round_reset.emit()

func time_usec() -> int:
	if 0 < player_rewind_amount_sec:
		return time_accrued_usec - int(player_rewind_amount_sec * 1000000.)
	return time_accrued_usec

func time_since_usec(past_time_usec: int) -> int:
	return time_usec() - past_time_usec

func time_msec() -> float:
	return max(0., time_accured_msec - player_rewind_amount_sec * 1000)

func time_since_msec(past_time_msec: float) -> float:
	return time_msec() - past_time_msec

func _enter_tree() -> void:
	if instance == null:
		_instance = self

func _exit_tree() -> void:
	if instance == self:
		_instance = null
