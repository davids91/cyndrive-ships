class_name DrSpeedo
extends BattleCharacter

@export var charge_attack_duration_sec: float = 1.
@export_range(0., 5.) var charge_attack_warning_swiftness: float = 0.8
@export var attack_swing_duration_sec: float = 0.5
@export var attack_trail_width_min: float = 0.5
@export var attack_trail_width_delta: float = 1.0
@export var sonar_blip_lifetime: float = SonarBlip.INFINITE_LIFETIME
@export var sonar_blip_scale: Vector2 = Vector2(1.5, 1.5)

@onready var combatants: Node = get_node("/root/Main/LevelContainer/battle/combatants")

func get_snapshot() -> Dictionary:
	var snapshot: Dictionary = super()
	snapshot["acquired_target"] = acquired_target
	return snapshot
	
func correct_temporal_state(snapshot: Dictionary, over_time_msec: float = 0.001) -> void:
	if "acquired_target" in snapshot: acquired_target = snapshot["acquired_target"]
	super(snapshot, over_time_msec)

func accept_damage(strength: float, source: Node = null) -> void:
	if strength >= BlackHole.DAMAGE:
		super(strength, source)

var current_impulse: Vector2 = Vector2.ZERO
func apply_impulse(impulse: Vector2) -> void:
	current_impulse += impulse

var charge_animation_tween: Tween = null
func _charge_attack() -> Tween:
	if charge_animation_tween: return charge_animation_tween
	$phase_effect.visible = true
	$phase_effect.modulate = Color.WHITE
	$phase_effect.get_material().set_shader_parameter("phase_red", 1.0)
	$phase_effect.get_material().set_shader_parameter("phase_green", 1.0)
	$phase_effect.get_material().set_shader_parameter("phase_blue", 1.0)
	create_tween().tween_method(
		func(w: float):
			$phase_effect.get_material().set_shader_parameter("zoom", 0.5 + 0.15 * w)
			$phase_effect.self_modulate = lerp(Color.WHITE, Color.TRANSPARENT, w),
		0., 1., charge_attack_duration_sec * 0.9
	)
	charge_animation_tween = create_tween()
	charge_animation_tween.tween_method(
		func(w: float): $skin.visible = 0.5 < (w - floor(w)),
		0., 3., charge_attack_duration_sec * 0.15
	).set_ease(Tween.EASE_IN).set_delay(charge_attack_duration_sec * 0.8)
	charge_animation_tween.tween_callback(func():
		$skin.visible = true
		$phase_effect.visible = false
		charge_animation_tween = null
	)
	return charge_animation_tween

var attack_position: Vector2
var attack_animation_tween: Tween = null
func _attack_swing(delay: float) -> Tween:
	if attack_animation_tween: return attack_animation_tween
	var to_attack_point = (attack_position - global_position)
	$trail.modulate = Color.WHITE
	$trail.points[0] = global_position
	$trail.points[1] = global_position + to_attack_point * 2.
	attack_animation_tween = create_tween()
	attack_animation_tween.tween_property(self, "global_rotation", to_attack_point.angle() + PI, delay)
	attack_animation_tween.tween_callback(func():
		$trail.visible = true
		create_tween().tween_property($trail, "modulate", Color.TRANSPARENT, attack_swing_duration_sec).finished.connect(
			func(): $trail.visible = false
		)
	)
	attack_animation_tween.tween_method(
		func(w: float): 
			$trail.width_curve.set_point_value(1, attack_trail_width_min + w * attack_trail_width_delta)
			$trail.width_curve.set_point_value(0, attack_trail_width_min + attack_trail_width_delta - w * attack_trail_width_delta)
			global_position = lerp(global_position, attack_position, w),
		0., 1., attack_swing_duration_sec
	)
	attack_animation_tween.tween_callback(func(): attack_animation_tween = null)
	return attack_animation_tween

func _ready() -> void:
	super()
	phase_in()
	$temporal_recorder.start_recording()

var victims_count: int = 0
func _process(_delta) -> void:
	for victim in bodies_hitting:
		if victim.has_method("accept_damage"):
			victim.accept_damage(BlackHole.DAMAGE)
		else: victim.queue_free()
		victims_count += 1

const HIT_AURA_RADIUS: float = 100.

@export var spin_speed_rad: float = 10.
@export var recuperate_time_sec: float = 3.
var acquired_target: Node2D = null
var time_until_next_attack_sec: float = recuperate_time_sec
var recuperation_time_left_sec: float = phase_in_duration_sec
var spin_around: bool = true
func _physics_process(delta: float) -> void:
	super(delta)
	current_impulse *= 0.8
	if current_impulse.length() < 0.1: current_impulse = Vector2.ZERO
	velocity += current_impulse
	if BattleTimeline.time_flow != BattleTimeline.TimeFlow.FORWARD or control_disabled: return

	if acquired_target:
		if 0. < time_until_next_attack_sec:
			# have the cross descend on the target
			$target_arrow.global_position = acquired_target.global_position
			$target_arrow.scale = Vector2.ONE * max(
				1., 10. * (time_until_next_attack_sec / (charge_attack_duration_sec * charge_attack_warning_swiftness))
			)
			time_until_next_attack_sec -= delta
		elif 0. >= recuperation_time_left_sec:
			create_tween().tween_property($target_arrow, "self_modulate", Color.TRANSPARENT, 0.5).finished.connect(func():
				$target_arrow.visible = false
			)
			recuperation_time_left_sec = recuperate_time_sec
			var attack_vec: Vector2 =  (acquired_target.global_position - global_position)
			attack_position = (
				global_position + attack_vec.normalized() * max(
					approx_size * 5., attack_vec.length() + min(attack_vec.length() * 0.6, approx_size * 5.)
				)
			)
			_charge_attack()
			_attack_swing(charge_attack_duration_sec * 0.2).finished.connect(func():
				acquired_target = null
				spin_around = false
			)
		else: recuperation_time_left_sec -= delta
		return

	# Spin around until target is acquired
	if spin_around: set_global_rotation(global_rotation + spin_speed_rad * delta)

	if 0. < recuperation_time_left_sec:
		if not spin_around and not $state_display.emote_in_progress():
			if 0 == victims_count: $state_display.annoyed_emote().finished.connect(func(): spin_around = true)
			else:
				victims_count = 0
				spin_around = true
		recuperation_time_left_sec -= delta
		return

	# Decide next target
	if not acquired_target and combatants:
		var random_target = combatants.get_children().pick_random()
		var tries: int = 0
		while (
			tries < 5
			and ("in_battle" not in random_target or !random_target.in_battle())
			and "team" in random_target and random_target.team.is_enemy(team)
		):
			random_target = combatants.get_children().pick_random()
			tries += 1
		if(
			tries < 5 and random_target != self
			and "team" in random_target and random_target.team.is_enemy(team)
		):
			acquired_target = random_target
			time_until_next_attack_sec = charge_attack_duration_sec
			$target_arrow.visible = true
			$target_arrow.self_modulate = Color.WHITE

var bodies_hitting: Dictionary = {}
func _on_hit_aura_body_entered(body: Node2D) -> void:
	if body != self: bodies_hitting[body] = BattleTimeline.instance.time_accured_msec

func _on_hit_aura_body_exited(body: Node2D) -> void:
	bodies_hitting.erase(body)
