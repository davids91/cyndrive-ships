extends ShapeCast2D


@export var goldfish_memory_sec: float = 3.

@onready var character: BattleCharacter = get_parent()

var highligthed_body: Node2D

func set_disabled(yesno: bool) -> void:
	enabled = not yesno

func is_target_locked() -> bool:
	return not highligthed_body == null

func get_current_target() -> Node2D:
	return highligthed_body

func get_current_target_position() -> Vector2:
	if highligthed_body and enabled:
		return highligthed_body.get_global_position()
	return get_global_position()

var target_out_of_sight_countdown_sec = goldfish_memory_sec
func _physics_process(delta: float) -> void:
	var target: Node2D = null

	# Position target assist to align with player control
	set_global_position(character.get_global_position())
	set_global_rotation(PlayerInput.instance.current_action_direction.angle())

	# Reset target if the ship is not attacking
	if 0. == PlayerInput.instance.current_action_direction.length():
		if not highligthed_body == null and highligthed_body.has_method("set_highlight"):
			highligthed_body.set_highlight(false)
		highligthed_body = null
		return
	# Handle targeting
	force_shapecast_update()
	var still_in_view: bool = false
	for i in get_collision_count():
		var collider = get_collider(i)
		still_in_view = still_in_view or (collider == highligthed_body)
		if(
			# Only target neutral and enemy characters
			collider and collider.has_method("set_highlight")
			and ( # Either the parent doesn't have a team node
				not "team" in get_parent() or not "team" in collider
				or collider.team.is_enemy(get_parent().team)# Or collider is an enemy by team assignments
				or collider is ExplosiveMine # We can also shoot mines
			) and (
				target == null
				or (
					(get_global_position() - collider.get_global_position()).length() 
					< (get_global_position() - target.get_global_position()).length()
				)
			)
		): target = collider

	if (
		(highligthed_body == null or not highligthed_body.in_battle() or not still_in_view)
	):
		if not target == null and target != highligthed_body: # Switch targets
			if not highligthed_body == null and highligthed_body.has_method("set_highlight"):
				highligthed_body.set_highlight(false)
			if target.has_method("set_highlight"):
				target.set_highlight(true)
			highligthed_body = target
			target_out_of_sight_countdown_sec = goldfish_memory_sec
		else: 
			target_out_of_sight_countdown_sec -= delta
			if target_out_of_sight_countdown_sec <= 0.:
				if not highligthed_body == null and highligthed_body.has_method("set_highlight"):
					highligthed_body.set_highlight(false)
				highligthed_body = null
