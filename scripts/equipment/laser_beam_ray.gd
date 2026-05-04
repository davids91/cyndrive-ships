class_name BattleShipLaser extends BattleShipWeapon

@export var warmup_damage_modifier: float = 0.05
@export var ray_warmup_width: float = 5
@export var ray_full_width: float = 10
@export var warmup_time_sec: float = 0.25
@export var shutdown_time_sec: float = 0.15
@export var target_time_sec: float = 0.01
@export var wielder: Node2D = get_parent()
@export var offset: Vector2 = Vector2.ZERO
@export var color_intensity_gradient: GradientTexture2D
@export var laser_intensity_length: float = 1000.
@export var always_shooting: bool = false

func _ready() -> void:
	if always_shooting: # TechDebt: If a standalone laser beam should always be shooting, give it a direction
		process_input_action({
			"acquired_target_position": acquired_target,
			"action_direction": Vector2.ONE
		})
	is_shooting = always_shooting
	if not wielder: wielder = get_parent()

func shutdown() -> void:
	current_strength_modifier = warmup_damage_modifier
	# TECHDEBT: In case the laser is released before warmup, the tweens get in conflict, so wait until at least the warmup is finished
	get_tree().create_timer(warmup_time_sec).timeout.connect(func():
		create_tween().tween_method(func(a): $beam_line.self_modulate.a = a, $beam_line.self_modulate.a, 0., shutdown_time_sec)
		var laser_ray_tween: Tween = create_tween()
		laser_ray_tween.tween_property($beam_line, "width", ray_full_width * 2., shutdown_time_sec)
		laser_ray_tween.tween_callback(func() :
			$beam_line.width = 0.
			was_shooting = is_shooting
			is_shooting = always_shooting
		)
	)

func reset() -> void:
	was_shooting = is_shooting
	is_shooting = always_shooting
	current_strength_modifier = 1.
	if child_beam:
		child_beam.reset()
		child_beam.queue_free()
		beams_to_open += 1
	shutdown()

var current_strength_modifier: float = 1.
var was_shooting: bool = false
var acquired_target: Vector2 = Vector2.ZERO
func process_input_action(action: Dictionary) -> void:
	if "acquired_target_position" in action:
		create_tween().tween_method(
			func(pos): acquired_target = pos,
			acquired_target, action["acquired_target_position"], target_time_sec
		)
	was_shooting = is_shooting
	if "action_direction" in action:
		is_shooting = (
			always_shooting or(
				"acquired_target_position" in action and "action_direction" in action
				and 0. < action["action_direction"].length()
			)
		)
	if "action_toggled" in action and not action["action_toggled"]: is_shooting = false
	if is_shooting:
		$sound.play()
		if not was_shooting: # Laser alpha and width animation
			create_tween().tween_method(func(a): $beam_line.self_modulate.a = a, 0., 1., warmup_time_sec)
			var laser_ray_tween: Tween = create_tween()
			laser_ray_tween.tween_property($beam_line, "width", ray_warmup_width, warmup_time_sec)
			laser_ray_tween.tween_property($beam_line, "width", ray_full_width, warmup_time_sec)
			laser_ray_tween.chain()
	elif was_shooting: # Laser alpha and width animation
		shutdown()

func hit_position() -> Vector2:
	if $raycast.is_colliding():
		return $raycast.get_collision_point()
	return $raycast.target_position

@export var beams_to_open: int = 3
@export var follows_wielder: bool = true
const BEAM_TEMPLATE: PackedScene = preload("res://scenes/weapons/laser_beam.tscn")
var child_beam: BattleShipLaser = null
var last_hit: Node2D
func _process(_delta: float) -> void:
	if "control_disabled" in wielder and wielder.control_disabled:
		reset()
		return

	if( # Create a child beam if the current one is hitting a shield
		0 < beams_to_open and not child_beam
		and is_shooting and current_hit and current_hit != last_hit and current_hit is BattleShipShield
		and(not "wielder" in current_hit or current_hit.wielder != wielder)
	):
		child_beam = BEAM_TEMPLATE.instantiate()
		child_beam.wielder = wielder
		child_beam.follows_wielder = false
		child_beam.beams_to_open = beams_to_open - 1
		beams_to_open -= 1
		add_child(child_beam)

	if(child_beam and (not current_hit or not current_hit is BattleShipShield) and child_beam.is_shooting):
		child_beam.reset()

	if current_hit and current_hit is BattleShipShield and child_beam:
		child_beam.global_position = current_hit_position
		child_beam.process_input_action({
			"acquired_target_position": current_hit_position + current_hit_normal,
			"action_direction": current_hit_normal
		})
	last_hit = current_hit

@export var sound_loop_start_sec: float = 0.2
@export var sound_loop_end_sec: float = 2.0
@export var current_hit: Node2D
var current_hit_position: Vector2 = Vector2.ZERO
var current_hit_normal: Vector2 = Vector2.ZERO
func _physics_process(_delta: float) -> void:
	# Handle laser beam display and raycast
	if follows_wielder:
		global_position = wielder.get_global_position() + offset.rotated(wielder.get_global_rotation())
	$beam_line.points[0] = global_position

	# Decide to "pull back" laser if the wielder is not in battle anymore
	if wielder.has_method("in_battle") and not wielder.in_battle():
		$beam_line.points[1] = global_position
		$raycast.set_global_position(global_position)
		$raycast.target_position = global_position
		return
	$beam_line.points[1] = hit_position()
	$raycast.set_global_position(global_position)
	$raycast.target_position = global_position + (acquired_target - global_position) * 1000.

	# Handle sounds and applying damage
	if not is_shooting: current_strength_modifier = warmup_damage_modifier
	if is_shooting:
		current_strength_modifier = round(lerp(current_strength_modifier, 1., 0.5) * 100.) / 100.
		current_hit = $raycast.get_collider()
		if current_hit:
			current_hit_position = $raycast.get_collision_point()
			current_hit_normal = $raycast.get_collision_normal()
			var victim = $raycast.get_collider()
			if victim != wielder and victim.has_method("accept_damage"):
				victim.accept_damage(base_damage * current_strength_modifier, wielder)
			var hit_distance: float = (global_position - current_hit.global_position).length()
			$beam_line.default_color = color_intensity_gradient.gradient.sample(hit_distance / laser_intensity_length)
		if not was_shooting and not $sound.playing:
			$sound.play()
		if $sound.playing:
			if $sound.get_playback_position() > sound_loop_end_sec:
				$sound.seek(sound_loop_start_sec)
	elif was_shooting and $sound.playing:
		$sound.seek(sound_loop_end_sec)
