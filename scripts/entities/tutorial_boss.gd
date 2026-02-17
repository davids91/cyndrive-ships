class_name MrMustle extends BattleCharacter

const gothcha_lines: Array[String] = [
	"THERE YOU ARE",
	"THERE",
	"I SEE YOU"
]

const visual_lost_lines: Array[String] = [
	"HEY Where are you???",
	"LOST VISUAL",
	"STOP HIDING WEAKLING",
	"?????"
]

@export_range(0., 1.) var difficuilty_sensor_speed: float = 0.1
@export_range(0., 1.) var difficuilty_moving_speed: float = 0.1
@export_range(0., 1.) var difficuilty_laser_speed: float = 0.25
@export var goldfish_memory_sec: float = 1.
@export var search_loop_length_sec: float = 2. * PI
@export var whirlwind_length_sec: float = 3.5
@export var whirlwind_speed_rad_per_sec: float = 4. * PI

@onready var focusing_at: Vector2 = get_global_position()
@onready var moving_to: Vector2 = get_global_position()

var acquired_target: Node2D = null
var aiming_to: Vector2 = Vector2.ZERO
var search_loop_progress: float = 0.
var time_until_target_drop: float = goldfish_memory_sec
var whirlwind_duration_left_sec: float = 0.
func _process(delta: float):
	super(delta)
	$player_detection.set_global_position(get_global_position())
	if not change_target_to and 0. < time_until_target_drop:
		time_until_target_drop -= delta
	if not acquired_target: search_loop_progress += delta
	if whirlwind_duration_left_sec <= 0.: _process_default_mode()
	else:
		whirlwind_duration_left_sec -= delta
		if whirlwind_duration_left_sec <= 0.:
			$controller.handle_rotation = true
			for saber in $hotsabers.get_children(): saber.shutdown()
		set_global_rotation(get_global_rotation() + whirlwind_speed_rad_per_sec * delta)
		for saber in $hotsabers.get_children():
			saber.process_input_action({"action_direction": Vector2.UP})

func _process_default_mode() -> void:
	# Handle target changes
	var lost_target: Node2D = null
	if acquired_target != change_target_to:
		if not change_target_to and 0. >= time_until_target_drop:
			time_until_target_drop = goldfish_memory_sec
			lost_target = acquired_target
			$state_display.say(visual_lost_lines.pick_random())
			for laser in $lasers.get_children(): laser.reset()
		elif change_target_to:
			focusing_at = change_target_to.get_global_position()
			aiming_to = change_target_to.get_global_position()
			$state_display.say(gothcha_lines.pick_random())
		acquired_target = change_target_to
	
	# Shutdown lasers if target is dead
	if acquired_target and not acquired_target.in_battle():
		acquired_target = null
		for laser in $lasers.get_children(): laser.reset()

	# Handle actions for targets
	if acquired_target:
		if (acquired_target.get_global_position() - get_global_position()).length() < approx_size:
			$state_display.exclaim_emote()
			whirlwind_duration_left_sec = whirlwind_length_sec
			$controller.handle_rotation = false
			return
		
		# Shoot the lasers and follow the target when it is active
		moving_to = lerp(
			moving_to,
			(get_global_position() + acquired_target.get_global_position()) * 0.5,
			difficuilty_moving_speed
		)
		aiming_to = lerp(aiming_to, acquired_target.get_global_position(), difficuilty_laser_speed)
		focusing_at = lerp(focusing_at, acquired_target.get_global_position(), difficuilty_sensor_speed)
		var to_target = aiming_to - get_global_position()
		for laser in $lasers.get_children():
			laser.process_input_action({
				"action_direction": to_target.normalized(),
				"acquired_target_position": aiming_to
			})
	else: 
		if search_loop_progress >= search_loop_length_sec: search_loop_progress = 0.
		moving_to = get_global_position() + Vector2(cos(search_loop_progress), sin(search_loop_progress)) * approx_size * 1.5
		var radar_direction_center = (moving_to - get_global_position()).normalized()
		var radar_angle = (
			radar_direction_center.angle()
			+ (((search_loop_progress - search_loop_length_sec / 2.) / search_loop_length_sec) * (PI / 4.))
		)
		if lost_target:
			var lost_target_angle = (lost_target.get_global_position() + get_global_position()).angle()
			if angle_difference(lost_target_angle, radar_angle) < angle_difference(lost_target_angle, -radar_angle):
				radar_angle = -radar_angle
		focusing_at = get_global_position() + Vector2(cos(radar_angle), sin(radar_angle)) * approx_size

	$player_detection.set_global_rotation(clamp(
		(focusing_at - get_global_position()).angle(),
		lerp_angle(get_global_rotation(), get_global_rotation() - PI / 4., 1.),
		lerp_angle(get_global_rotation(), get_global_rotation() + PI / 4., 1.),
	))

	if approx_size < ((get_global_position() - moving_to)).length():
		aiming_to = lerp(aiming_to, focusing_at, difficuilty_laser_speed)
		$controller.process_input_action({
			"movement_intent": (moving_to - get_global_position()).normalized(),
			#"boost_intent": false
		})
	else: $controller.process_input_action({"movement_intent": Vector2.ZERO})

func phase_in() -> void:
	super()
	$screaming.play()

func accept_damage(strength: float, source: BattleCharacter = null) -> void:
	if whirlwind_duration_left_sec > 0.: return # Do not accept damage while a hotsaber ball
	super(strength, source)
	if source and not acquired_target:
		acquired_target = source
		focusing_at = source.get_global_position()

var change_target_to: Node2D = null
func _on_player_detection_body_entered(body: Node2D) -> void:
	if not acquired_target and body.has_node("team") and body.get_node("team").is_enemy($team):
		change_target_to = body

func _on_player_detection_body_exited(body: Node2D) -> void:
	if body == acquired_target: change_target_to = null
