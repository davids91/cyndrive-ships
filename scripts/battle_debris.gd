class_name BattleDebris extends RigidBody2D

@onready var spawn_motion = get_motion()

var motion_overwrite_time_msec: float = 0.
var motion_to_set : Dictionary
var debug_color: Color = Color.from_hsv(randf() * 6., 1., 1., 1.)
func correct_motion_course(motion: Dictionary, over_time_msec: float) -> void:
	motion_to_set = motion
	motion_overwrite_time_msec = abs(over_time_msec)
	# DEBUG FOR MOTION CORRECTION
	get_parent().get_parent().display_line(transform.get_origin(), motion_to_set["transform"].get_origin(), debug_color)

func get_motion() -> Dictionary:
	return {"transform": transform, "linear_velocity": linear_velocity, "angular_velocity": angular_velocity}

var physics_interval_msec = 1000. / Engine.physics_ticks_per_second
func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	if 0 < motion_overwrite_time_msec:
		var weight_in_interpolation = physics_interval_msec / motion_overwrite_time_msec
		if motion_overwrite_time_msec < physics_interval_msec:
			weight_in_interpolation = 1.
		var interpolated_motion = BattleTimeline.lerp_motion( \
			get_motion(), motion_to_set, clamp(weight_in_interpolation * weight_in_interpolation, 0., 1.) \
		)
		state.transform = interpolated_motion["transform"]
		state.linear_velocity = interpolated_motion["linear_velocity"]
		state.angular_velocity = interpolated_motion["angular_velocity"]
		motion_overwrite_time_msec -= physics_interval_msec

func respawn() -> void:
	correct_motion_course(spawn_motion, 0.01)
	$temporal_recorder.start_recording()
