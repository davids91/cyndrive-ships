extends CharacterBody2D

@export var team_id = 0
@export var spawn_position = Vector2()
@export var color = Color()
@export var starting_health = 10.

var do_overwrite_transform = false
var transform_to_set : Transform2D
func overwrite_transform(new_transform) -> void:
	transform_to_set = new_transform
	do_overwrite_transform = true

func _physics_process(delta: float) -> void:
	if do_overwrite_transform:
		transform = transform_to_set
		do_overwrite_transform = false

func init_clone(predecessor):
	predecessor.get_node("team").init_succesor($team)
	$skin.self_modulate = $team.color

func init_control_character():
	$team.initialize(team_id, spawn_position, color)
	$skin.self_modulate = $team.color

var accept_keyboard_inputs = false
func accepts_input(yesno):
	accept_keyboard_inputs = yesno
	$controller.stop()

func is_alive():
	return $health.is_alive

func set_highlight(yesno):
	$target_arrow.set_visible(yesno)

func _process(delta):
	if !is_alive():
		unalive_me()

func process_input_action(action):
		$controller.process_input_action(action)
		$laser_beam.process_input_action(action)
		if has_node("move_recorder"):
			$move_recorder.process_input_action(action)
		
func accept_damage(strength):
	$health.accept_damage(strength)
	if $health.health > 3:
		explosion_shake_smooth()
	else:
		explosion_shake()

func respawn():
	$health.respawn()
	$controller.move_to_spawn_pos()
	set_collision_layer_value(1, true)
	set_visible(true)

func unalive_me():
	set_collision_layer_value(32, false)
	set_visible(false)

func _unhandled_input(inev):
	if(accept_keyboard_inputs):
		var action = BattleInputMap.get_action(get_viewport(), get_global_position(), inev)
		var target_assist = get_parent().get_node("target_assist")
		if target_assist.is_target_locked():
			var assisted_direction = ( \
				target_assist.get_current_target_position() \
				- get_global_position() \
			).normalized()
			action["cursor"] = assisted_direction
		process_input_action(action)

func explosion_shake(intensity: float = 30.0, duration: float = 0.5, frequency: int = 20):
	var tween = create_tween()
	
	# Create multiple random shakes
	for i in frequency:
		var shake_offset = Vector2(
			randf_range(-intensity, intensity),
			randf_range(-intensity, intensity)
		)
		tween.tween_property($cam, "offset", shake_offset, duration / frequency)
	
	# Return to center
	tween.tween_property(self, "offset", Vector2.ZERO, duration / frequency)

func explosion_shake_smooth(intensity: float = 30.0, duration: float = 0.5):
	var tween = create_tween()
	var steps = 10
	
	for i in steps:
		var progress = float(i) / steps
		var current_intensity = intensity * (1.0 - progress)  # Decay
		var shake_offset = Vector2(
			randf_range(-current_intensity, current_intensity),
			randf_range(-current_intensity, current_intensity)
		)
		tween.tween_property($cam, "offset", shake_offset, duration / steps)
	
	tween.tween_property($cam, "offset", Vector2.ZERO, 0.1)
