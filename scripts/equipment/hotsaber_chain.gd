extends RigidBody2D

var pos_to_set: Vector2 = Vector2()
var pos_over_time_sec: float = 0.
static var physics_loop_sec = 1. / Engine.physics_ticks_per_second

func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	if 0 >= pos_over_time_sec: return
	state.transform.origin = lerp(
		state.transform.origin, pos_to_set,
		min(1., physics_loop_sec / max(pos_over_time_sec, 0.0001))
	)
	pos_over_time_sec -= physics_loop_sec
