class_name PlayerShip
extends BattleCharacter

var is_boosting: bool = false
var target_locked: bool = false
func process_input_action(action: Dictionary) -> void:
	if"action_direction" in action:
		target_locked = $target_assist.is_target_locked()
		if target_locked:
			action["acquired_target_position"] = $target_assist.get_current_target_position()
			action["acquired_target"] =  $target_assist.get_current_target()
			$target_arrow.global_position = $target_assist.get_current_target_position()
		%RadarConeVisual.visible = (
			0. < action["action_direction"].length() and not target_locked
			and BattleTimeline.time_flow == BattleTimeline.TimeFlow.FORWARD
		)
	if "boost_toggled" in action: is_boosting = action["boost_toggled"]

	if "boost_toggled" in action and action["boost_toggled"]:
		if has_node("cam_remote_transform"):
			var boost_tween: Tween = create_tween()
			boost_tween.tween_property($cam_remote_transform, "position", $controller.intent_direction * approx_size * -2., 0.1)
			boost_tween.tween_property($cam_remote_transform, "position", Vector2(), 0.5)

	# TechDebt: Temporal replay reverses shoot and boost inputs
	# so if rewinding is stopped midway boosting, the character stays in invalid state
	if is_boosting and not PlayerInput.instance.is_boosting: action["boost_toggled"] = false
	super(action)

var monitored_slowdown: float = 1.
func time_control_triggered(action: Dictionary) -> void:
	if "slowdown" in action: monitored_slowdown = action["slowdown"]

func accept_damage(strength: float, source: Node = null) -> void:
	super(strength, source)
	if health > low_health: explosion_shake_smooth()
	else: explosion_shake()

func display_dock_message(should_be_visible: bool) -> void:
	if has_node("state_display"):
		if should_be_visible: $state_display.say("Press E to dock")
		else: $state_display.shutup()

func explosion_shake(intensity: float = 30.0, duration: float = 0.5, frequency: int = 20) -> Tween:
	if not has_node("cam_remote_transform"): return
	var tween = create_tween()

	# Create multiple random shakes
	for i in frequency:
		var shake_offset = Vector2(
			randf_range(-intensity, intensity),
			randf_range(-intensity, intensity)
		)
		tween.tween_property($cam_remote_transform, "position", shake_offset, duration / frequency)

	# Return to center
	tween.tween_property($cam_remote_transform, "position", Vector2.ZERO, duration / frequency)
	return tween

func explosion_shake_smooth(intensity: float = 30.0, duration: float = 0.5) -> Tween:
	if not has_node("cam_remote_transform"): return
	var tween = create_tween()
	var steps = 10

	for i in steps:
		var progress = float(i) / steps
		var current_intensity = intensity * (1.0 - progress)  # Decay
		var shake_offset = Vector2(
			randf_range(-current_intensity, current_intensity),
			randf_range(-current_intensity, current_intensity)
		)
		tween.tween_property($cam_remote_transform, "position", shake_offset, duration / steps)
	tween.tween_property($cam_remote_transform, "position", Vector2.ZERO, 0.1)
	return tween

@export var target_camera_radius: float = 750.
@export var world_covered_in_screen: float = 1500.
func _process(delta: float) -> void:
	super(delta)
	if $slowdown_effect.is_active != PlayerInput.instance.slowdown_being_held:
		$slowdown_effect.toggle(PlayerInput.instance.slowdown_being_held)

	if target_locked and $target_assist.is_target_locked():
		$target_arrow.set_visible(true)
		$target_bubble.set_visible(true)
		var target_pos: Vector2 = $target_assist.get_current_target().global_position
		var to_target: Vector2 = (target_pos - global_position)
		if to_target.length() > world_covered_in_screen:
			$target_viewport/target_camera.global_position = target_pos
			$target_bubble.global_position = global_position + to_target.normalized() * target_camera_radius
			$target_bubble.get_material().set_shader_parameter("arrow_angle_rad", to_target.angle() - PI)
		else: $target_bubble.set_visible(false)
		$target_arrow.global_position = lerp(
			$target_arrow.global_position,
			$target_assist.get_current_target_position(),
			0.95
		)
		if "approx_size" in $target_assist.get_current_target():
			$target_arrow.scale = Vector2.ONE * ($target_assist.get_current_target().approx_size / approx_size)
	else:
		$target_arrow.set_visible(false)
		$target_bubble.set_visible(false)
