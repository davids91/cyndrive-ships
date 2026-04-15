class_name OrangeBossBrain extends BattleCharacter

const gothcha_lines: Array[String] = [
	"ORANGE YOU SCARED?",
	"PREPARE TO BE JUICED!",
	"I'LL SLICE YOU UP!"
]

@export var projectile_scene: PackedScene # missiles
@export var muzzleflash_scene: PackedScene # shooting fx

@export_range(0., 1.) var difficulty_sensor_speed: float = 0.1
@export_range(0., 1.) var difficulty_moving_speed: float = 0.1
@export_range(0., 1.) var difficulty_laser_speed: float = 0.25
@export_range(0., 5.) var difficulty_laser_warning_sec: float = 2.0
@export var goldfish_memory_sec: float = 1.
@export var search_loop_length_sec: float = 2. * PI
@export var whirlwind_length_sec: float = 3.5
@export var whirlwind_speed_rad_per_sec: float = 3 * PI
@export_range(0., 5.) var difficulty_whirlwind_warning_sec: float = 0.5

@onready var focusing_at: Vector2 = get_global_position()
@onready var moving_to: Vector2 = get_global_position()

func _ready() -> void:
	super()
	phase_in()

var acquired_target: Node2D = null
var aiming_to: Vector2 = Vector2.ZERO
var search_loop_progress: float = 0.
var time_until_target_drop: float = goldfish_memory_sec
var whirlwind_duration_left_sec: float = 0.
var boss_control_disabled: bool = false
var missile_chance:float = 0.02


func missile_spam():
	if randf() < missile_chance:
		# if Missles are fired in rapid succession so the sounds is being restarted over and over again
		# if not $missile_sound.playing: $missile_sound.play()
		$missile_sound.play()
		if projectile_scene:
			var miss = projectile_scene.instantiate()
			get_tree().root.add_child(miss)
			miss.rotation = rotation
			miss.position = position
		if muzzleflash_scene:
			var muzz = muzzleflash_scene.instantiate()
			get_tree().root.add_child(muzz)
			muzz.rotation = rotation
			muzz.position = position

func _process(delta: float):
	super(delta)
	if boss_control_disabled: return

	missile_spam()
	
	$player_detection.set_global_position(get_global_position())
	if not change_target_to and 0. < time_until_target_drop:
		time_until_target_drop -= delta
	if not acquired_target: search_loop_progress += delta
	if whirlwind_duration_left_sec <= 0.: _process_default_mode(delta)
	else:
		var still_warning: bool = whirlwind_duration_left_sec < whirlwind_length_sec
		whirlwind_duration_left_sec -= delta
		if whirlwind_duration_left_sec <= 0.:
			for saber in $hotsabers.get_children(): saber.shutdown()
		if whirlwind_duration_left_sec < whirlwind_length_sec:
			set_global_rotation(get_global_rotation() + whirlwind_speed_rad_per_sec * delta)
			if still_warning: for saber in $hotsabers.get_children():
				saber.process_input_action({
					"action_direction": (get_global_position() - saber.get_stem_position()).normalized() * 2.
				})

var time_until_lasers: float = difficulty_laser_warning_sec
var time_until_search_start: float = goldfish_memory_sec
var focus_change_from_damage:bool = false
func _process_default_mode(delta: float) -> void:
	# Handle rotation
	set_global_rotation((focusing_at - get_global_position()).angle())

	# Handle target changes
	var lost_target: Node2D = null
	if acquired_target != change_target_to:
		if not change_target_to and time_until_target_drop <= 0.:
			time_until_target_drop = goldfish_memory_sec
			lost_target = acquired_target
			for laser in $lasers.get_children(): laser.reset()
		elif change_target_to:
			aiming_to = get_global_position()
			$state_display.say(gothcha_lines.pick_random())
			$screaming.play() # play an extra sound on player taunt
			time_until_lasers = difficulty_laser_warning_sec
		acquired_target = change_target_to

	if 0. < time_until_lasers and acquired_target:
		$target_arrow.set_visible(true)
		$target_arrow.global_position = acquired_target.global_position
		$target_arrow.scale = Vector2.ONE * 10. * (time_until_lasers / difficulty_laser_warning_sec)
	else: $target_arrow.set_visible(false)

	# Shutdown lasers if target is dead
	if acquired_target and not acquired_target.in_battle():
		acquired_target = null
	if acquired_target == null or 0. < time_until_lasers:
		for laser in $lasers.get_children(): if laser.is_shooting: laser.reset()

	# Handle actions for targets
	if acquired_target:
		time_until_search_start = goldfish_memory_sec
		if (acquired_target.get_global_position() - get_global_position()).length() < approx_size:
			$state_display.exclaim_emote()
			whirlwind_duration_left_sec = whirlwind_length_sec + difficulty_whirlwind_warning_sec
			create_tween().tween_callback(
				func(): for laser in $lasers.get_children(): laser.reset()
			).set_delay(difficulty_whirlwind_warning_sec)
			return
		
		# Shoot the lasers and follow the target when it is active
		moving_to = lerp(
			moving_to, (get_global_position() + acquired_target.get_global_position()) * 0.5,
			difficulty_moving_speed
		)
		aiming_to = lerp(aiming_to, acquired_target.get_global_position(), difficulty_laser_speed)
		if not focus_change_from_damage:
			focusing_at = lerp(focusing_at, acquired_target.get_global_position(), difficulty_sensor_speed)
		if 0. < time_until_lasers: time_until_lasers -= delta
		else: for laser in $lasers.get_children():
			laser.process_input_action({
				"action_direction": (aiming_to - get_global_position()).normalized(),
				"acquired_target_position": aiming_to
			})
	else: 
		time_until_search_start -= delta
		if search_loop_progress >= search_loop_length_sec: search_loop_progress = 0.
		var radar_direction_center = (moving_to - get_global_position()).normalized()
		var radar_angle = (
			radar_direction_center.angle()
			+ (((search_loop_progress - search_loop_length_sec / 2.) / search_loop_length_sec) * (PI / 4.))
		)
		if lost_target:
			# Search loop is defined both in seconds and angles. A full search circle takes 2*PI seconds!
			search_loop_progress = (lost_target.get_global_position() - get_global_position()).angle()

		# The below makes the Queen move about when there's no target acquired
		moving_to = get_global_position() + Vector2(cos(search_loop_progress), sin(search_loop_progress)) * approx_size * 0.1

		if not focus_change_from_damage:
			focusing_at = get_global_position() + Vector2(cos(radar_angle), sin(radar_angle)) * approx_size

	var focus_angle: float = (focusing_at - get_global_position()).angle()
	if sign(focus_angle) != $player_detection.get_global_rotation():
		# TechDebt? LERP won't work well when the rotation changes from PI to -PI or vice versa
		# despite the actual angles being almost identical!
		$player_detection.set_global_rotation(focus_angle)
	else: $player_detection.set_global_rotation(clamp(
		focus_angle,
		lerp_angle(get_global_rotation(), get_global_rotation() - PI / 4., 1.),
		lerp_angle(get_global_rotation(), get_global_rotation() + PI / 4., 1.),
	))

	if approx_size < ((get_global_position() - moving_to)).length():
		aiming_to = lerp(aiming_to, focusing_at, difficulty_laser_speed)
		$controller.process_input_action({
			"movement_intent": (moving_to - get_global_position()).normalized(),
		})
	else: $controller.process_input_action({"movement_intent": Vector2.ZERO})

func phase_in() -> void:
	if not $screaming.playing: $screaming.play()
	super()

func accept_damage(strength: float, source: Node = null) -> void:
	if whirlwind_duration_left_sec > 0.: return # Do not accept damage while a hotsaber ball
	super(strength, source)
	if source and not acquired_target:
		acquired_target = source
		var new_focus = source.get_global_position()
		focus_change_from_damage = true
		create_tween().tween_method(func(w: float): focusing_at = lerp(focusing_at, new_focus, w), 0., 1., 1.).finished.connect(
			func(): focus_change_from_damage = false
		)

var change_target_to: Node2D = null
func _on_player_detection_body_entered(body: Node2D) -> void:
	if(
		not acquired_target and "team" in body and body.team.is_enemy(team)
		and body.has_method("in_battle") and body.in_battle()
	):
		if change_target_to == body and safeguard_for_accidental_drop:
			safeguard_for_accidental_drop.kill()
		change_target_to = body

@export var safeguard_time_for_accidental_drop_sec : float = 0.8
var safeguard_for_accidental_drop: Tween = null
func _on_player_detection_body_exited(body: Node2D) -> void:
	if body == acquired_target and acquired_target:
		if safeguard_for_accidental_drop: safeguard_for_accidental_drop.kill()
		safeguard_for_accidental_drop = create_tween()
		safeguard_for_accidental_drop.tween_interval(safeguard_time_for_accidental_drop_sec)
		safeguard_for_accidental_drop.tween_callback(func(): change_target_to = null)

func _on_phased(phased_in: bool) -> void:
	$skin.set_visible(phased_in)
	$RadarConeVisual.set_visible(phased_in)
	$state_display.visible = phased_in

func pause_control() -> void:
	control_disabled = true
	velocity = Vector2.ZERO
	$controller.internal_force = Vector2.ZERO
	$controller.intent_direction = Vector2.ZERO
	super()


func _on_dead(itsme):
	control_disabled = true # so it stops firing missiles
	pass # Replace with function body.
