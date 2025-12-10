class_name BattleCharacter extends CharacterBody2D

const CHARACTER_APPROX_SIZE: float = 100.

@export var team_id = 0
@export var spawn_position = Vector2()
@export var color = Color()
@export var starting_health = 10.
@export var target_assist_shape: CollisionShape2D
@export var temporal_correction_distance_threshold: float = CHARACTER_APPROX_SIZE / 2.
@export_range(0., 200.) var mass: float = 10.

@onready var spawn_transform = get_transform()

var target_assist_original_size: float = 150.
func _ready() -> void:
	$skin.material = $skin.material.duplicate() # To have different colors for each ship
	$team.initialize(team_id, spawn_position, color)
	$skin.material.set_shader_parameter("team_color", $team.color)
	if has_node("ai_control"):
		$ai_control.enabled = true
	if target_assist_shape:
		target_assist_original_size = target_assist_shape.shape.radius

var debug_color: Color = Color.from_hsv(randf() * 6., 1., 1., 1.)
func correct_temporal_state(snapshot: Dictionary, over_time_msec: float) -> void:
	# DEBUG LINES FOR MOTION CORRECTION
	get_parent().get_parent().display_line(transform.get_origin(), snapshot["transform"].get_origin(), debug_color)
	# DEBUG LINES FOR MOTION CORRECTION

	if "health" in snapshot:
		was_alive = $health.is_alive
		$health.set_value(snapshot["health"])
		if not was_alive and $health.is_alive:
			resurrect_me()
			was_alive = $health.is_alive

	var correction_length = (snapshot["transform"].get_origin() - get_transform().get_origin()).length()
	var tween_length = max(0., over_time_msec) / 1000.;
	if "internal_force" in snapshot:
		create_tween().tween_property(self, "internal_force", snapshot["internal_force"], tween_length)
	if "velocity" in snapshot:
		create_tween().tween_property(self, "velocity", snapshot["velocity"], tween_length)

	# Add an afterimage of the character, and erase it shortafter
	if temporal_correction_distance_threshold < correction_length:
		create_tween().tween_property(self, "transform", snapshot["transform"], tween_length)
		var clone = $skin.duplicate()
		clone.set_material(clone.material.duplicate())
		clone.set_transform($skin.get_transform())
		clone.set_global_position(get_global_position())
		get_parent().add_child(clone)
		var tween = create_tween()
		tween.tween_method(
			func(value): clone.material.set_shader_parameter("burn_percentage", value),
			0.0, 1.0, 0.5
		)
		tween.finished.connect(func(): clone.queue_free())
	$controller.start()


func init_clone(predecessor: BattleCharacter) -> void:
	ship_explosion = null
	team_id = predecessor.team_id
	spawn_transform = predecessor.spawn_transform
	predecessor.spawn_transform = predecessor.transform
	$skin.material.set_shader_parameter("team_color", $team.color)

func is_alive() -> bool:
	return self.has_node("health") and $health.is_alive

func in_battle() -> bool:
	return is_alive()

func set_highlight(yesno: bool) -> void:
	$target_arrow.set_visible(yesno)

func get_mass() -> float:
	return mass

func apply_impulse(impulse: Vector2) -> void:
	$controller.internal_force += impulse

func _physics_process(delta: float) -> void:
	if control_enabled == true:
		var collision = move_and_collide(get_velocity() * delta)
		if collision != null and collision.get_collider().has_method("get_mass"):
			var mass_ratio = get_mass() / collision.get_collider().get_mass()
			collision.get_collider().apply_impulse($controller.internal_force * delta * mass_ratio * 0.9)

@onready var was_alive = is_alive()
var ship_explosion : ShipExplosion
var explosion_template = preload("res://scenes/effects/explosion-firey.tscn")
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
		if was_alive:
			#erase a previous explosion if there was any
			if ship_explosion == null:
				ship_explosion = explosion_template.instantiate().duplicate()
			ship_explosion.reinit()
			get_tree().get_root().add_child(ship_explosion)
			ship_explosion.set_global_position(get_global_position())
			was_alive = false
	
	# Erase explosion if alive
	if is_alive() and ship_explosion != null:
		ship_explosion.queue_free()
		ship_explosion = null

func accept_damage(strength):
	$health.accept_damage(strength)
	if $health.health > 3:
		explosion_shake_smooth($cam)
	else:
		explosion_shake($cam)

func move_to_spawn_position():
	set_transform(spawn_transform)
	move_and_slide()
	
func respawn():
	move_to_spawn_position()
	set_velocity(Vector2())
	set_collision_layer_value(1, true)
	set_visible(true)
	$health.respawn()
	was_alive = true
	$controller.stop()
	$controller.start()
	if has_node("temporal_recorder"):
		$temporal_recorder.start_recording()
	if has_node("replayer"):
		$replayer.reset()

func unalive_me():
	set_collision_layer_value(1, false)
	set_visible(false)
	if has_node("ai_control"):
		$ai_control.enabled = false
		
func resurrect_me():
	set_collision_layer_value(1, true)
	set_visible(true)
	if has_node("ai_control"):
		$ai_control.enabled = true

var accepts_inputs = false
var control_enabled = false
func accepts_user_input(yesno):
	accepts_inputs = yesno

func pause_control() -> void:
	control_enabled = false
	$controller.stop()
	if has_node("ai_control"):
		$ai_control.stop()

func resume_control() -> void:
	control_enabled = true
	$controller.start()
	if has_node("ai_control"):
		$ai_control.resume()

func _unhandled_input(inev: InputEvent) -> void:
	if not accepts_inputs:
		return;
	var action = BattleInputMap.get_action(get_viewport(), get_global_position(), inev)
	if(control_enabled):
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

func process_input_action(action):
	$controller.process_input_action(action)
	if(control_enabled):
		$laser_beam.process_input_action(action)
		if has_node("temporal_recorder"):
			$temporal_recorder.process_input_action(action)

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
