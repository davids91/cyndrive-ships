class_name BattleCharacter extends CharacterBody2D

const CHARACTER_APPROX_SIZE: float = 100.

@export var team_id = 0
@export var spawn_position = Vector2()
@export var color = Color()
@export var starting_health = 10.
@export var target_assist_shape: CollisionShape2D

var target_assist_original_size: float = 150.
func _ready() -> void:
	if target_assist_shape:
		target_assist_original_size = target_assist_shape.shape.radius

var motion_update_started = false
var motion_overwrite_time_msec: float = 0.
var motion_to_set : Dictionary
var debug_color: Color = Color.from_hsv(randf() * 6., 1., 1., 1.)
func correct_motion_course(motion: Dictionary, over_time_msec: float) -> void:
	motion_to_set = motion
	motion_overwrite_time_msec = abs(over_time_msec)
	# DEBUG FOR MOTION CORRECTION
	get_parent().get_parent().display_line(transform.get_origin(), motion_to_set["transform"].get_origin(), debug_color)
	motion_update_started = true
	
func _physics_process(delta: float) -> void:
	if 0 < motion_overwrite_time_msec:
		var this_frame_msec = delta * 1000
		var weight_in_interpolation = this_frame_msec / motion_overwrite_time_msec
		if motion_overwrite_time_msec < this_frame_msec:
			weight_in_interpolation = 1.
		var interpolated_motion = BattleTimeline.lerp_motion( \
			{"transform": transform, "velocity": velocity}, motion_to_set, \
			clamp(weight_in_interpolation * weight_in_interpolation, 0., 1.) \
		)
		transform = interpolated_motion["transform"]
		velocity = interpolated_motion["velocity"]
		
		if motion_update_started:
			if "internal_force" in motion_to_set:
				$controller.internal_force = motion_to_set["internal_force"]
			if "intent_force" in motion_to_set:
				$controller.intent_force = motion_to_set["intent_force"]
		motion_overwrite_time_msec -= delta * 1000
	else:
		motion_update_started = false

func init_clone(predecessor):
	predecessor.get_node("team").init_succesor($team)
	$skin.self_modulate = $team.color

func init_control_character():
	$team.initialize(team_id, spawn_position, color)
	$skin.self_modulate = $team.color

func is_alive():
	return self.has_node("health") and $health.is_alive

func set_highlight(yesno):
	$target_arrow.set_visible(yesno)

var zoom_value = 0.4
func _process(_delta):
	if has_node("cam"):
		var next_zoom_value = clamp($controller.top_speed / get_velocity().length() * 10., 0.25, 0.5)
		zoom_value = lerpf(zoom_value, next_zoom_value, 0.01)
		$cam.zoom.x = zoom_value
		$cam.zoom.y = zoom_value
		if target_assist_shape:
			target_assist_shape.shape.radius = target_assist_original_size * (0.5 / zoom_value)
		
	if !is_alive():
		unalive_me()

func process_input_action(action):
		$controller.process_input_action(action)
		$laser_beam.process_input_action(action)
		if has_node("temporal_recorder"):
			$temporal_recorder.process_input_action(action)
		
func accept_damage(strength):
	$health.accept_damage(strength)
	if $health.health > 3:
		explosion_shake_smooth($cam)
	else:
		explosion_shake($cam)

func move_to_spawn_position():
	set_position($team.get_spawn_position())
	move_and_slide()
	
func respawn():
	move_to_spawn_position()
	set_velocity(Vector2())
	set_collision_layer_value(1, true)
	set_visible(true)
	$health.respawn()
	$controller.stop()
	if has_node("temporal_recorder"):
		$temporal_recorder.start_recording()
	if has_node("replayer"):
		$replayer.reset()

func unalive_me():
	set_collision_layer_value(32, false)
	set_visible(false)
	if has_node("ai_control"):
		$ai_control.enabled = false

var accepted_input_previously = false
func pause_control() -> void:
	accepted_input_previously = accept_inputs
	accept_inputs = false
	$controller.stop()
	if has_node("ai_control"):
		$ai_control.stop()
		
func resume_control() -> void:
	accept_inputs = accepted_input_previously
	if has_node("ai_control"):
		$ai_control.resume()

var accept_inputs = false
func accepts_input(yesno):
	accept_inputs = yesno

func _unhandled_input(inev: InputEvent) -> void:
	if(accept_inputs):
		var action = BattleInputMap.get_action(get_viewport(), get_global_position(), inev)
		if $"../../target_assist".is_target_locked():
			var assisted_direction = ($"../../target_assist".get_current_target_position() - get_global_position()).normalized()
			action["cursor"] = assisted_direction
			
		# move camera lightly on boost  
		if action["boost"]:
			var camera_direction = $controller.intent_direction * -1
			var boost_tween = create_tween()
			boost_tween.tween_property($cam, "offset", camera_direction * CHARACTER_APPROX_SIZE * 2., 0.2)
			boost_tween.tween_property($cam, "offset", Vector2(), 0.5)
			boost_tween.chain()

		process_input_action(action)

func explosion_shake(target: Object, intensity: float = 30.0, duration: float = 0.5, frequency: int = 20):
	var tween = create_tween()
	
	# Create multiple random shakes
	for i in frequency:
		var shake_offset = Vector2(
			randf_range(-intensity, intensity),
			randf_range(-intensity, intensity)
		)
		tween.tween_property(target, "offset", shake_offset, duration / frequency)
	
	# Return to center
	tween.tween_property(target, "offset", Vector2.ZERO, duration / frequency)

func explosion_shake_smooth(target: Object, intensity: float = 30.0, duration: float = 0.5):
	var tween = create_tween()
	var steps = 10
	
	for i in steps:
		var progress = float(i) / steps
		var current_intensity = intensity * (1.0 - progress)  # Decay
		var shake_offset = Vector2(
			randf_range(-current_intensity, current_intensity),
			randf_range(-current_intensity, current_intensity)
		)
		tween.tween_property(target, "offset", shake_offset, duration / steps)
	
	tween.tween_property(target, "offset", Vector2.ZERO, 0.1)
