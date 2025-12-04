class_name BattleDebris extends RigidBody2D

@onready var spawn_snapshot = get_snapshot()

var temporal_overwrite_time_msec: float = 0.
var snapshot_to_set : Dictionary
var debug_color: Color = Color.from_hsv(randf() * 6., 1., 1., 1.)
func correct_temporal_state(snapshot: Dictionary, over_time_msec: float) -> void:
	snapshot_to_set = snapshot
	temporal_overwrite_time_msec = abs(over_time_msec)
	# DEBUG FOR MOTION CORRECTION
	get_parent().get_parent().display_line(transform.get_origin(), snapshot_to_set["transform"].get_origin(), debug_color)

func get_snapshot() -> Dictionary:
	return {"transform": transform, "linear_velocity": linear_velocity, "angular_velocity": angular_velocity}

var physics_interval_msec = 1000. / Engine.physics_ticks_per_second
func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	if 0 < temporal_overwrite_time_msec:
		var weight_in_interpolation = physics_interval_msec / temporal_overwrite_time_msec
		if temporal_overwrite_time_msec < physics_interval_msec:
			weight_in_interpolation = 1.
		var interpolated_motion = BattleTimeline.lerp_motion( \
			get_snapshot(), snapshot_to_set, clamp(weight_in_interpolation * weight_in_interpolation, 0., 1.) \
		)
		state.transform = interpolated_motion["transform"]
		state.linear_velocity = interpolated_motion["linear_velocity"]
		state.angular_velocity = interpolated_motion["angular_velocity"]
		temporal_overwrite_time_msec -= physics_interval_msec

func respawn() -> void:
	correct_temporal_state(spawn_snapshot, 0.01)
	$temporal_recorder.start_recording()
