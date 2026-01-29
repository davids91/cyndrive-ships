class_name BattleDebris extends RigidBody2D

@export var debris_collision_layer_value = 0x01

@onready var spawn_snapshot: Dictionary = get_snapshot()
@onready var spawn_time_msec: float = BattleTimeline.instance.time_msec()
@onready var was_in_battle: bool = in_battle()

func in_battle() -> bool:
	return spawn_time_msec < BattleTimeline.instance.time_msec()

var temporal_overwrite_time_msec: float = 0.
var snapshot_to_set : Dictionary
func correct_temporal_state(snapshot: Dictionary, over_time_msec: float) -> void:
	snapshot_to_set = snapshot
	temporal_overwrite_time_msec = abs(over_time_msec)

func get_snapshot() -> Dictionary:
	return {"transform": transform, "linear_velocity": linear_velocity, "angular_velocity": angular_velocity}

func _process(_delta: float) -> void:
	if not in_battle() and was_in_battle:
		create_tween().tween_method(func(value): $skin.set_burn_percentage(value), 0.0, 1.0, 0.5)
		set_collision_layer_value(debris_collision_layer_value, false)
		was_in_battle = false
	elif in_battle() and not was_in_battle:
		create_tween().tween_method(func(value): $skin.set_burn_percentage(value), 1.0, 0.0, 0.5)
		set_collision_layer_value(debris_collision_layer_value, true)
		was_in_battle = true

var physics_interval_msec = 1000. / Engine.physics_ticks_per_second
func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	if 0 < temporal_overwrite_time_msec:
		var weight_in_interpolation = physics_interval_msec / temporal_overwrite_time_msec
		if temporal_overwrite_time_msec < physics_interval_msec:
			weight_in_interpolation = 1.
		var current_snapshot = get_snapshot()
		state.transform = lerp(current_snapshot["transform"], snapshot_to_set["transform"], weight_in_interpolation)
		state.linear_velocity = snapshot_to_set["linear_velocity"] * BattleTimeline.instance.time_flow
		state.angular_velocity = snapshot_to_set["angular_velocity"]
		temporal_overwrite_time_msec -= physics_interval_msec

func respawn() -> void:
	correct_temporal_state(spawn_snapshot, 0.01)
	$temporal_recorder.start_recording()
