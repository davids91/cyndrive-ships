class_name BattleCharacter extends CharacterBody2D

signal health_changed(percentage: float)
signal dead(BattleCharacter)
signal resurrected(BattleCharacter)
signal boost_energy_updated(new_energy_level: float)
signal weapon_energy_updated(new_energy_level: float)

@export var approx_size: float = 100.
@export var team_id: int = 0
@export var spawn_position: Vector2 = Vector2()
@export var color: Color = Color.from_rgba8(0,0,0,0)
@export var skin_layers: Array[BattleShipSkin] = []
@export var starting_health: float = 10.
@export var max_health: float = 12.
@export var low_health: float = 3.
@export_range(0., 1000.) var mass: float = 10.

var health: float = starting_health
func _ready() -> void:
	$mini_health_bar.set_visible(name != "player_carrier")
	$team.initialize(team_id, spawn_position, color)
	$skin.init_skin(skin_layers, $team.color)
	if has_node("ai_control"): $ai_control.enabled = true
	else:
		$controller.set_script(preload("res://scripts/equipment/player_motion_control.gd"))
		$controller.character = self
		$controller.last_position = get_global_position()
		$controller.stop()
		$controller.start()

@export var red_curve_phasing: Curve
@export var green_curve_phasing: Curve
@export var blue_curve_phasing: Curve
func phase_in(phase_in_duration_sec: float) -> void:
	$phase_effect.set_visible(true)
	create_tween().tween_method(
		func(w):
			$phase_effect.get_material().set_shader_parameter(
				"phase_red", red_curve_phasing.sample(w)
			),
		0., 1.,
		phase_in_duration_sec
	)
	create_tween().tween_method(
		func(w):
			$phase_effect.get_material().set_shader_parameter("phase_green",
			green_curve_phasing.sample(w)),
		0., 1.,
		phase_in_duration_sec
	)
	create_tween().tween_method(
		func(w):
			$phase_effect.get_material().set_shader_parameter("phase_blue",
			blue_curve_phasing.sample(w)),
		0., 1.,
		phase_in_duration_sec
	)
	create_tween().tween_method(
		func(w):
			$phase_effect.get_material().set_shader_parameter("phase_green",
			green_curve_phasing.sample(w)),
		0., 1.,
		phase_in_duration_sec
	)
	var zoom_phase_tween = create_tween()
	zoom_phase_tween.tween_method(
		func(w): $phase_effect.get_material().set_shader_parameter("zoom", w),
		0., 1.,
		phase_in_duration_sec
	).set_ease(Tween.EASE_OUT)
	zoom_phase_tween.tween_callback(func() :
		$skin.set_visible(true)
		$mini_health_bar.visible = true
	)
	zoom_phase_tween.chain()


var debug_color: Color = Color.from_hsv(randf(), 1., 1., 1.)
func correct_temporal_state(snapshot: Dictionary, over_time_msec: float) -> void:
	if "held_mine" in snapshot and not null == snapshot["held_mine"]:
		held_mine = snapshot["held_mine"]

	if "health" in snapshot:
		was_alive = is_alive
		health = snapshot["health"]
		is_alive = 0 < health
		if not was_alive and is_alive:
			resurrect_me()
			was_alive = is_alive

	if "energy" in snapshot and has_node("energy_systems"):
		get_node("energy_systems").temporal_correction(snapshot["energy"])

	var correction_length = (snapshot["transform"].get_origin() - get_transform().get_origin()).length()
	var tween_length = max(0., over_time_msec) / 1000.;
	if "internal_force" in snapshot:
		$controller.internal_force = snapshot["internal_force"] * BattleTimeline.instance.time_flow
	if "velocity" in snapshot: velocity = snapshot["velocity"] * BattleTimeline.instance.time_flow
	if "rotation" in snapshot: set_global_rotation(snapshot["rotation"])

	# Add an afterimage of the character if correction moved it from course too much, and erase it short after
	if approx_size * 2. < correction_length:
		create_tween().tween_property(self, "transform", snapshot["transform"], tween_length)
		var clone = $skin.duplicate()
		clone.set_skins_material(preload("res://resources/implode_effect.tres").duplicate())
		clone.set_transform($skin.get_transform())
		clone.set_global_position(get_global_position())
		clone.set_global_rotation(get_global_rotation())
		if "replace_skin" in clone: clone.replace_skin = false
		$"../../mush".add_child(clone)
		var tween = create_tween()
		tween.tween_method(
			func(value): clone.set_burn_percentage(value),
			0.0, 1.0, 0.5
		)
		tween.finished.connect(func(): clone.queue_free())
		# DEBUG LINES FOR MOTION CORRECTION
		get_parent().get_parent().display_line(transform.get_origin(), snapshot["transform"].get_origin(), debug_color)
		# DEBUG LINES FOR MOTION CORRECTION


func init_clone(predecessor: BattleCharacter, new_color: Color) -> void:
	spawn_position = predecessor.spawn_position
	ship_explosion = null
	team_id = predecessor.team_id
	skin_layers = predecessor.skin_layers # set skin from predecessor(_ready will construct the skin)
	color = new_color

func in_battle() -> bool:
	return (
		is_alive
		and (
			# Only player or AI controlled characters don't have a replayer
			not has_node("replayer")
			# The replayer has records for the current time
			or $replayer.is_within_current_time()
			# AI can retake control after replayer runs out of moves
			or (has_node("ai_control") and ai_fallback)
		)
	)

func set_highlight(yesno: bool) -> void:
	$target_arrow.set_visible(yesno)

func get_mass() -> float:
	return mass

func apply_impulse(impulse: Vector2) -> void:
	$controller.apply_impulse(impulse)

# Keeping track of the body the character is in contact with
var body_in_contact: Object = null
var contact_time: float = 0.
func _physics_process(delta: float) -> void:
	var collision = move_and_collide(get_velocity() * delta)
	if collision != null and collision.get_collider().has_method("get_mass"):
		if body_in_contact == collision.get_collider():
			contact_time += delta
		else: contact_time = 0.
		body_in_contact = collision.get_collider()
		var mass_ratio = get_mass() / body_in_contact.get_mass()
		body_in_contact.apply_impulse($controller.internal_force * delta * mass_ratio * 0.15)
	else: contact_time = 0.

@onready var is_alive: bool = true
@onready var was_alive: bool = is_alive
@onready var was_in_battle: bool = in_battle()
@export var mini_health_bar_offset: Vector2 = Vector2(-64, 64)
var ship_explosion : ShipExplosion
var explosion_template = preload("res://scenes/effects/explosion-firey.tscn")
func _process(_delta):
	if has_node("target_assist"): $target_assist.set_position(get_global_mouse_position())
	if $mini_health_bar.top_level:
		$mini_health_bar.set_global_position(get_global_position() + mini_health_bar_offset)

	# Sync state for being alive and in battle
	if is_alive != was_alive: was_in_battle = in_battle()

	# Handle when player timeline gets different from characters timeline
	if not in_battle() and was_in_battle:
		create_tween().tween_method(func(value): $skin.set_burn_percentage(value), 0.0, 1.0, 0.5)
		was_in_battle = false
	elif in_battle() and not was_in_battle:
		create_tween().tween_method(func(value): $skin.set_burn_percentage(value), 1.0, 0.0, 0.5)
		was_in_battle = true

	# Erase explosion if ship is alive
	if is_alive and ship_explosion != null:
		ship_explosion.queue_free()
		ship_explosion = null

	# Do not continue if the ship is not in battle
	if not in_battle(): return

	if has_node("repair_indicator"):
		$repair_indicator.set_global_position(get_global_position() - $repair_indicator.size * 0.55)

	# Play thruster sound when ship is being steered
	if (
		0. < $controller.intent_direction.length() and in_battle()
		and not has_node("ai_control") and not has_node("replayer")
		and not $thruster_sound.playing
	):
		$thruster_sound.play(randf())
	elif 0. == $controller.intent_direction.length() and $thruster_sound.playing: 
		var stop_fnc = create_tween()
		stop_fnc.tween_interval(0.5)
		stop_fnc.tween_callback(func() : $thruster_sound.stop())
		stop_fnc.chain()

@export var laser_strength: float = 1.
@export var entanglement_chance: float = 0.05
var entangled: bool = false
func accept_damage(strength: float, source: BattleCharacter = null) -> void:
	# God mode - player team takes no damage when enabled
	if FeatureFlags.is_enabled("god_mode"):
		var battle_main = get_tree().current_scene
		if battle_main and "god_mode_active" in battle_main and battle_main.god_mode_active:
			if $team.team_id == 1: return

	if( # Damage from the main controlled character may induce temporal entanglement
		source != null and source.name == "character" and name != "characters"
		and entanglement_chance >= randf()
		and not has_node("replayer")
	):
		entangled = true
	health -= max(0., strength)
	is_alive = 0 < health
	health_changed.emit(health / starting_health)
	if health > low_health: explosion_shake_smooth()
	else: explosion_shake()

	# Handle explosion when ship is destroyed
	if !is_alive:
		if was_alive:
			#erase a previous explosion if there was any
			if ship_explosion == null:
				ship_explosion = explosion_template.instantiate().duplicate()
				$"../../mush".add_child(ship_explosion)
			ship_explosion.reinit()
			ship_explosion.set_global_position(get_global_position())
			was_alive = false
			was_in_battle = false
			$explosion_sound.play()
			if has_node("weapon_slot"): $weapon_slot.shutdown()
			dead.emit(self)
		unalive_me()


func accept_healing(strength: float, _source: BattleCharacter = null) -> void:
	health = min(health + max(0., strength), max_health)
	is_alive = 0 < health
	health_changed.emit(health / starting_health)

func respawn():
	if has_node("weapon_slot"): $weapon_slot.select_slot(0)
	set_global_position(spawn_position)
	set_velocity(Vector2())
	set_collision_layer_value(1, true)
	set_visible(true)
	is_alive = true
	was_alive = true
	health = starting_health
	$controller.stop()
	$controller.start()
	resume_control()
	if has_node("temporal_recorder"):
		$temporal_recorder.start_recording()
		if (
			extend_replayer and has_node("replayer")
			and not $replayer.usec_records.keys().is_empty()
			and not $replayer.msec_records.keys().is_empty()
		):
			var records = $temporal_recorder.copy_marked_records(
				$replayer.usec_records.keys()[-1],
				$replayer.msec_records.keys()[-1]
			)
			$replayer.usec_records.merge(records["action"])
			$replayer.msec_records.merge(records["motion"])
	if has_node("replayer"): $replayer.reset()
	if has_node("weapon_slot"): $weapon_slot.reset()
	if has_node("ai_control"):
		$ai_control.stop()
		$ai_control.resume()
	extend_replayer = false
	was_alive = true

func unalive_me():
	health = 0
	is_alive = false
	was_alive = false
	set_collision_layer_value(1, false)
	set_visible(false)
	if null != held_mine: held_mine.set_visible(false)
	if has_node("ai_control"): $ai_control.set_disabled(true)
	$controller.stop()

func resurrect_me():
	set_collision_layer_value(1, true)
	set_visible(true)
	if null != held_mine: held_mine.set_visible(true)
	if has_node("ai_control"): $ai_control.set_disabled(false)
	resurrected.emit(self)
	$controller.start()

var control_enabled = false
func pause_control() -> void:
	control_enabled = false
	$controller.stop()
	if has_node("ai_control"): $ai_control.stop()

func resume_control() -> void:
	control_enabled = true
	$controller.start()
	if has_node("ai_control"): $ai_control.resume()

var held_mine: ExplosiveMine = null
func process_input_action(action: Dictionary) -> void:
	if not in_battle(): return # cannot process any action while not in battle
	if "weapon_slot" in action and has_node("weapon_slot"):
		$weapon_slot.select_slot(action["weapon_slot"])
		action["pewpew_released"] = true

	if(control_enabled):
		if not null == held_mine and "deploy_mine" in action and action["deploy_mine"]:
			held_mine.deploy_mine()
			held_mine = null

		if has_node("energy_systems"):
			if "boost_initiated" in action and not $energy_systems.has_boost_energy():
				action.erase("boost_initiated")
			if "pewpew" in action and not $energy_systems.has_weapon_energy():
				action.erase("pewpew")
				action["pewpew_released"] = true
		
		if("pewpew" in action and has_node("target_assist") and $target_assist.is_target_locked()):
			action["pewpew"] = $target_assist.get_current_target_position()
			action["pewpew_target"] =  $target_assist.get_current_target()
			
		# move camera lightly on boost  
		if "boost_initiated" in action:
			$booster_sound.play()
			await $booster_sound.finished.connect(func():
				$booster_fx.visible = false
				$thruster_fx.visible = true
			)
			var camera_direction = $controller.intent_direction * -1
			var boost_tween = create_tween()
			if has_node("cam"):
				boost_tween.tween_property($cam, "offset", camera_direction * approx_size * 2., 0.1)
				boost_tween.tween_property($cam, "offset", Vector2(), 0.5)
				boost_tween.chain()

	# For targets representing past versions ( e.g. player previous round ), positions may mismatch slightly
	# because of the inaccuracies in the replay system and floating point inaccuracies of the physics system
	# Should the target be slightly off, but still around the actual laser position, the position is corrected
	# so past versions of the players can hit their targets more accurately
	if (
		"pewpew" in action and "pewpew_target" in action and null != action["pewpew_target"]
		and (action["pewpew_target"].get_global_position() - action["pewpew"]).length() < action["pewpew_target"].approx_size * 3
	): action["pewpew"] = action["pewpew_target"].get_global_position()

	$controller.process_input_action(action)
	if has_node("weapon_slot"): $weapon_slot.process_input_action(action)
	if has_node("temporal_recorder"): $temporal_recorder.process_input_action(action)


func explosion_shake(intensity: float = 30.0, duration: float = 0.5, frequency: int = 20) -> void:
	if not has_node("cam"): return
	var tween = create_tween()

	# Create multiple random shakes
	for i in frequency:
		var shake_offset = Vector2(
			randf_range(-intensity, intensity),
			randf_range(-intensity, intensity)
		)
		tween.tween_property($cam, "offset", shake_offset, duration / frequency)

	# Return to center
	tween.tween_property($cam, "offset", Vector2.ZERO, duration / frequency)

func explosion_shake_smooth(intensity: float = 30.0, duration: float = 0.5) -> void:
	if not has_node("cam"): return
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

var ai_fallback: bool = true
var extend_replayer: bool = false
func _on_replayer_temporal_scope_changed(in_scope: bool) -> void:
	# Mark the exact time and index values within the recorder that needs to be added to the replayer records
	if not in_scope and ai_fallback:
		$temporal_recorder.mark_current_time()
		extend_replayer = true

	# Fallback to AI once replayer runs out of records
	if has_node("ai_control"): $ai_control.set_disabled(in_scope or not ai_fallback)

func _on_controller_boosting(is_boosting: bool) -> void:
	$booster_fx.visible = is_boosting
	$thruster_fx.visible = not is_boosting
	if is_boosting: $booster_sound.play()
	else: $booster_sound.stop()

func _on_energy_systems_boost_energy_updated(new_energy_level: float) -> void:
	boost_energy_updated.emit(new_energy_level)

func _on_energy_systems_weapon_energy_updated(new_energy_level: float) -> void:
	weapon_energy_updated.emit(new_energy_level)

func _on_health_changed(percentage: float) -> void:
	$mini_health_bar.set_value_no_signal(percentage * $mini_health_bar.max_value)
