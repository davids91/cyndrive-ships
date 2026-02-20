extends RigidBody2D

var pos_to_set: Vector2 = Vector2()
var pos_over_time_sec: float = 0.
static var physics_loop_sec = 1. / Engine.physics_ticks_per_second

func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	if 0 >= pos_over_time_sec: return
	state.apply_force((pos_to_set - state.transform.origin))
	state.transform.origin = lerp(
		state.transform.origin, pos_to_set,
		min(1., physics_loop_sec / max(pos_over_time_sec, 0.0001))
	)
	pos_over_time_sec -= physics_loop_sec

var ships_hurting: Dictionary = {}
func _process(delta: float) -> void: # Handle hotsaber damage
	if get_parent().is_shooting: for ship in ships_hurting:
		if ship.has_method("accept_damage"): ship.accept_damage(get_parent().base_damage * delta)

func _on_hurt_aura_body_entered(body: Node2D) -> void:
	if(
		body != get_parent().wielder
		and (
			not "team" in get_parent().wielder
			or not "team" in body
			or get_parent().wielder.team.is_enemy(body.team)
		)
	): ships_hurting[body] = BattleTimeline.instance.time_msec()

func _on_hurt_aura_body_exited(body: Node2D) -> void:
	if ships_hurting.has(body): ships_hurting.erase(body)
