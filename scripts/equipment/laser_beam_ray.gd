class_name BattleShipLaser extends BattleShipWeapon

@export var warmup_damage_modifier: float = 0.35
@export var ray_warmup_width: float = 5
@export var ray_full_width: float = 10
@export var warmup_time_sec: float = 0.25
@export var shutdown_time_sec: float = 0.15
@export var target_time_sec: float = 0.01
@export var wielder: BattleCharacter = get_parent()
@export var offset: Vector2 = Vector2.ZERO

func _ready() -> void:
	if not wielder: wielder = get_parent()

func shutdown() -> void:
	# TECHDEBT: In case the laser is released before warmup, the tweens get in conflict, so wait until at least the warmup is finished
	await get_tree().create_timer(warmup_time_sec).timeout
	create_tween().tween_method(func(a): $beam_line.self_modulate.a = a, $beam_line.self_modulate.a, 0., shutdown_time_sec)
	var laser_ray_tween = create_tween()
	laser_ray_tween.tween_property($beam_line, "width", ray_full_width * 2., shutdown_time_sec)
	laser_ray_tween.tween_callback(func() :
		$beam_line.width = 0.
		was_shooting = is_shooting
		is_shooting = false
	)
	laser_ray_tween.chain()

func reset() -> void:
	was_shooting = is_shooting
	is_shooting = false
	current_strength_modifier = 1.
	shutdown()

var current_strength_modifier: float = 1.
var was_shooting: bool = false
var acquired_target: Vector2 = Vector2()
func process_input_action(action: Dictionary) -> void:
	if "acquired_target_position" in action:
		create_tween().tween_method(
			func(pos): acquired_target = pos,
			acquired_target, action["acquired_target_position"], target_time_sec
		)
	was_shooting = is_shooting
	if "action_direction" in action:
		is_shooting = (
			"acquired_target_position" in action and "action_direction" in action
			and 0. < action["action_direction"].length()
		)
	if "action_released" in action and action["action_released"]: is_shooting = false
	if is_shooting:
		$sound.play()
		if not was_shooting: # Laser alpha and width animation
			current_strength_modifier = warmup_damage_modifier
			create_tween().tween_property(self, "current_strength_modifier", warmup_damage_modifier, 1.)
			create_tween().tween_method(func(a): $beam_line.self_modulate.a = a, 0., 1., warmup_time_sec)
			var laser_ray_tween = create_tween()
			laser_ray_tween.tween_property($beam_line, "width", ray_warmup_width, warmup_time_sec)
			laser_ray_tween.tween_property($beam_line, "width", ray_full_width, warmup_time_sec)
			laser_ray_tween.chain()
	elif was_shooting: # Laser alpha and width animation
		shutdown()

func hit_position() -> Vector2:
	if $raycast.is_colliding():
		return $raycast.get_collision_point()
	return $raycast.target_position

@export var sound_loop_start_sec: float = 0.2
@export var sound_loop_end_sec: float = 2.0
func _physics_process(_delta: float) -> void:
	# Handle laser beam display and raycast
	var laser_origin = wielder.get_global_position() + offset.rotated(wielder.get_global_rotation())
	$beam_line.points[0] = laser_origin
	if not wielder.in_battle():
		$beam_line.points[1] = laser_origin
		$raycast.set_global_position(laser_origin)
		$raycast.target_position = laser_origin
		return
	$beam_line.points[1] = hit_position()
	$raycast.set_global_position(laser_origin)
	$raycast.target_position = laser_origin + (acquired_target - laser_origin) * 1000.

	# Handle sounds and applying damage
	if is_shooting:
		if null != $raycast.get_collider():
			var victim = $raycast.get_collider()
			if victim != wielder and victim.has_method("accept_damage"):
				victim.accept_damage(base_damage * current_strength_modifier, wielder)
			# Uncomment the following line if laser is behaving strangely
			# elif not victim.has_method("accept_damage"): print("ERROR: ", victim, " doesn't have `accept_damage` method!")
		if not was_shooting and not $sound.playing:
			$sound.play()
		if $sound.playing:
			if $sound.get_playback_position() > sound_loop_end_sec:
				$sound.seek(sound_loop_start_sec)
	elif was_shooting and $sound.playing:
		$sound.seek(sound_loop_end_sec)
