extends Node2D

@export var starting_laupeerium: float = 25.
@export_range(0., 1.) var replay_screen_responsiveness: float = 0.05

@onready var character_template = preload("res://scenes/entities/base_ship.tscn")
@onready var laupeerium_bar: UIEnergyBar = $GUI/status_padding/battleship_status/laupeerium

const round_start_delay_sec: float = 2.
var init_countdown_sec: float = round_start_delay_sec
var current_laupeerium: float = starting_laupeerium
var living_team_members: Dictionary = {}
var god_mode_active: bool = false
var infinite_ammo_active: bool = false
var infinite_boost_active: bool = false

func _ready():
	laupeerium_bar.bars_remaining = UIEnergyBar.max_bars
	$combatants/character/controller.stop()
	$combatants/character/cam.make_current()
	living_team_members[2] = 0
	living_team_members[1] = 0
	for combatant in $combatants.get_children():
		$timeline.connect("round_reset", combatant.respawn)
		$timeline.connect("rewind_started", combatant.pause_control)
		$timeline.connect("rewind_stopped", combatant.resume_control)
		combatant.dead.connect(_on_battle_character_dead)
		combatant.resurrected.connect(_on_battle_character_resurrected)
		living_team_members[combatant.team.team_id] += 1

	for debris in $debris.get_children():
		$timeline.connect("round_reset", debris.respawn)

	# Connect weapon slot signal for UI updates
	if $combatants/character.has_node("weapon_slot"):
		$combatants/character/weapon_slot.weapon_changed.connect(_on_weapon_changed)
	$combatants/player_carrier.phase_in()

func reset_game() -> void:
	for explosion in $mush.get_children():
		explosion.queue_free()
	get_tree().call_deferred("reload_current_scene")

@export var rewind_battle_laupeerium_cost: float = 1.
func restart_round(rewind_animation: bool = true) -> void:
	if current_laupeerium < rewind_battle_laupeerium_cost: return

	# Handle resource changes with round restart
	if not is_replay: current_laupeerium -= rewind_battle_laupeerium_cost
	laupeerium_bar.bars_remaining = round(float(UIEnergyBar.max_bars) * (current_laupeerium / starting_laupeerium))
	$combatants/character/energy_systems.reset()

	#TechDebt: Eliminate mine after round end
	if not $combatants/character.held_mine == null:
		$combatants/character.held_mine.queue_free()

	# Stop the fighting
	for combatant in $combatants.get_children():
		if "pause_control" in combatant:
			combatant.pause_control()

	# Create a clone of the ship
	create_new_puppet($combatants/character)

	# Handle temporal entanglement for affected ships
	for c in $combatants.get_children():
		if(
			"entangled" in c and c.entangled and not c.has_node("replayer")
			and "team" in c and c.team.is_enemy($combatants/character.team)
		):
			entangle_ship_with_player(c)

	if not rewind_animation:
		for combatant in $combatants.get_children():
			if "pause_control" in combatant:
				combatant.resume_control()
		$timeline.reset()
		queue_redraw()
		$GUI/defeat.set_visible(false)
		$GUI/victory.set_visible(false)
		$GUI/restart_round_panel.set_visible(false)
		return

	# Set up UI for the new round
	$GUI/rewind_effects.set_visible(true)

	# Move the player to its spawn position
	var respawn_time = 1.
	var player_move_tween = create_tween()
	player_move_tween.tween_method(
		func(pos):
			$combatants/character.set_global_position(pos)
			$GUI/rewind_effects.material.set_shader_parameter(
				"rewind_amount",
				-(pos - $combatants/character.spawn_snapshot["transform"].origin).length() / 500.
			),
		$combatants/character.get_global_position(),
		$combatants/character.spawn_snapshot["transform"].origin,
		respawn_time
	)
	player_move_tween.tween_callback(func():
		for combatant in $combatants.get_children():
			if "pause_control" in combatant:
				combatant.resume_control()
		$GUI/rewind_effects.set_visible(false)
		$timeline.reset()
		queue_redraw()
		$GUI/defeat.set_visible(false)
		$GUI/victory.set_visible(false)
		$GUI/restart_round_panel.set_visible(false)
		living_team_members[1] = 0
		living_team_members[2] = 0
		for c in $combatants.get_children():
			if "is_alive" in c and c.is_alive:
				living_team_members[c.team.team_id] += 1
	)
	player_move_tween.chain()

const tap_interval_msec: int = 500
const short_reverse_hold_time_sec: float = 0.15 # How long to hold down the reverse action to start reversing time
var reverse_being_held: bool = false
var reverse_initiated: bool = false
var reverse_hold_time_sec: float = 0.
var reverse_tap_count: int = 0
var reverse_last_tap_at: int = Time.get_ticks_msec()
var replay_viewport = Rect2()
func _process(delta):
	$GUI/debug_stats/fps.set_text("%s fps" % Engine.get_frames_per_second())
	var display_time: float = BattleTimeline.instance.time_msec()
	var total_seconds: int = int(display_time / 1000.0)
	var minutes: int = int(total_seconds / 60.0)
	$GUI.set_time(minutes, total_seconds)

	# Countdown to battle start
	if 0 < init_countdown_sec:
		init_countdown_sec = max(init_countdown_sec - delta / Difficuilty.gameplay_speed, 0)
		$GUI/score.set_text("%0.3f" % init_countdown_sec)
		if init_countdown_sec <= 0:
			$combatants/character.set_visible(true)
			$combatants/character/temporal_recorder.start_recording()
			$combatants/player_carrier/temporal_recorder.start_recording()
			for combatant in $combatants.get_children():
				combatant.resume_control()
			$timeline.reset()
			$player_input.set_disabled(false)
			$GUI/score.set_text(str(
				living_team_members[1], " vs ", living_team_members[2],
				" - Score: ", int(kill_score * kill_score_multiplier)
			))
		else: return

	# Handle camera while replay
	if is_replay:
		var view_rectangle: Rect2 = Rect2()
		var characters_in_battle = 0
		for c: BattleCharacter in $combatants.get_children():
			if c.in_battle():
				view_rectangle = view_rectangle.expand(c.get_global_position())
				characters_in_battle += 1
		if 2 < characters_in_battle:
			var viewport_size = get_viewport_rect().size
			var zoom_level = min(
				viewport_size.x / min(view_rectangle.size.x, 4096),
				viewport_size.y / min(view_rectangle.size.y, 4096),
			) * 0.9
			replay_viewport.position = lerp(replay_viewport.position, view_rectangle.position, replay_screen_responsiveness)
			replay_viewport.size = lerp(replay_viewport.size, view_rectangle.size, replay_screen_responsiveness)
			$replay_camera.zoom = Vector2(zoom_level, zoom_level)
			$replay_camera.set_global_position(replay_viewport.position + replay_viewport.size / 2.)
	else:
		# Handle dynamic zoom for camera
		var next_zoom_value = clamp(
			$combatants/character/controller.top_speed / $combatants/character.get_velocity().length() * 10.,
			motion_zoom_center - motion_zoom_range, motion_zoom_center + motion_zoom_range
		)
		current_zoom_value = lerpf(current_zoom_value, next_zoom_value, 0.01)
		$combatants/character/cam.zoom.x = current_zoom_value
		$combatants/character/cam.zoom.y = current_zoom_value

	# Handling Battle restart
	if (Time.get_ticks_msec() - reverse_last_tap_at) > tap_interval_msec and rewind_battle_laupeerium_cost < current_laupeerium:
		reverse_tap_count = 0
	if 2 <= reverse_tap_count:
		reverse_tap_count = 0
		restart_round()

	# Handling Timeline reverse
	if current_laupeerium <= 0.: reverse_being_held = false
	if reverse_being_held:
		reverse_hold_time_sec += delta
		if reverse_hold_time_sec > short_reverse_hold_time_sec:
			if not reverse_initiated:
				$GUI/rewind_effects.set_visible(true)
				create_tween().tween_method(
					func(w: float): $GUI/rewind_effects.material.set_shader_parameter("rewind_intensity", w),
					0., 1., short_reverse_hold_time_sec * 2.
				)
			reverse_initiated = true
			current_laupeerium -= delta
			laupeerium_bar.bars_remaining = round(float(UIEnergyBar.max_bars) * (current_laupeerium / starting_laupeerium))
			$timeline.reverse(delta)
			$GUI/defeat.set_visible(false)
			$GUI/victory.set_visible(false)
			$GUI/restart_round_panel.set_visible(false)
			$GUI/rewind_effects.material.set_shader_parameter("rewind_amount", BattleTimeline.instance.player_rewind_amount_sec)
	if reverse_initiated:
		if not reverse_being_held:
			$timeline.finish_reverse()
			reverse_hold_time_sec = 0.
			reverse_initiated = false
			var rewind_hide_tween = create_tween()
			rewind_hide_tween.tween_method(
				func(w: float): $GUI/rewind_effects.material.set_shader_parameter("rewind_intensity", w),
				1., 0., short_reverse_hold_time_sec * 2.
			)
			rewind_hide_tween.tween_callback(func() : $GUI/rewind_effects.set_visible(false))
			rewind_hide_tween.chain()

func entangle_ship_with_player(ship: BattleCharacter) -> void:
	if ship.has_node("replayer") or ship.name == "character": return # Nothing to do when ship is already entangled
	var records = ship.get_node("temporal_recorder").stop_recording()
	var replayer = Node2D.new()
	replayer.set_script(preload("res://scripts/battle/temporal_replayer.gd"))
	replayer.name = "replayer"
	replayer.usec_records = records["action"]
	replayer.msec_records = records["temporal_snapshots"]
	replayer.temporal_scope_changed.connect(ship._on_replayer_temporal_scope_changed)
	$timeline.connect("round_reset", replayer.reset)
	$timeline.connect("round_reset", replayer.start_replay)
	replayer.reset()
	ship.add_child(replayer)
	if ship.has_node("ai_control"):
		ship.get_node("ai_control").set_disabled(true)

func create_new_puppet(predecessor: BattleCharacter) -> void:
	var records = predecessor.get_node("temporal_recorder").stop_recording()
	var puppet = character_template.instantiate();
	var replayer = Node2D.new()
	puppet.init_clone(predecessor, Color.from_rgba8(29, 191, 0, 104))
	replayer.set_script(preload("res://scripts/battle/temporal_replayer.gd"))
	replayer.name = "replayer"
	replayer.usec_records = records["action"]
	replayer.msec_records = records["temporal_snapshots"]
	$timeline.connect("round_reset", puppet.respawn)
	$timeline.connect("rewind_started", puppet.pause_control)
	$timeline.connect("rewind_stopped", puppet.resume_control)
	replayer.reset()
	puppet.add_child(replayer, true)
	puppet.dead.connect(_on_battle_character_dead)
	puppet.resurrected.connect(_on_battle_character_resurrected)

	# set new spawn position for the predecessor
	predecessor.spawn_snapshot["transform"].origin = (
		$combatants/player_carrier.spawn_snapshot["transform"].origin
		+ (
			(
				predecessor.get_global_position()
				- $combatants/player_carrier.spawn_snapshot["transform"].origin
			).normalized()
			* $combatants/player_carrier.approx_size
		)
	)

	# Add the new puppet to battle
	$combatants.add_child(puppet)
	predecessor.get_node("temporal_recorder").start_recording()

@export var motion_zoom_range: float = 0.02
@export var motion_zoom_center: float = 0.3
var current_zoom_value: float = motion_zoom_center
func _unhandled_input(event: InputEvent) -> void:
	if is_replay: return
	var just_pressed = event.is_pressed() and not event.is_echo()
	
	# Infinite ammo toggle (F7)
	if FeatureFlags.is_enabled("infinite_ammo"):
		if event is InputEventKey and event.physical_keycode == KEY_F7 and just_pressed:
			infinite_ammo_active = !infinite_ammo_active
			$GUI/debug_stats/infinite_ammo_label.visible = infinite_ammo_active
			
	# Infinite boost toggle (F8)
	if FeatureFlags.is_enabled("infinite_boost"):
		if event is InputEventKey and event.physical_keycode == KEY_F8 and just_pressed:
			infinite_boost_active = !infinite_boost_active
			$GUI/debug_stats/infinite_boost_label.visible = infinite_boost_active
	
	# God mode toggle (F9)
	if FeatureFlags.is_enabled("god_mode"):
		if event is InputEventKey and event.physical_keycode == KEY_F9 and just_pressed:
			god_mode_active = !god_mode_active
			$GUI/debug_stats/god_mode_label.visible = god_mode_active

	if event.is_action_pressed("key_bindings") and just_pressed:
		$GUI/keybindings_panel.set_visible(not $GUI/keybindings_panel.visible)

	if event.is_action_pressed("replay") and just_pressed and 0 < current_laupeerium:
		if (Time.get_ticks_msec() - reverse_last_tap_at) < tap_interval_msec:
			reverse_tap_count += 1
		reverse_last_tap_at = Time.get_ticks_msec()
		reverse_being_held = true
		$GUI/rewind_effects.material.set_shader_parameter("rewind_amount", BattleTimeline.instance.player_rewind_amount_sec)

	if event.is_action_released("replay"):
		reverse_being_held = false

	if event.is_action_pressed("zoom_in"):
		motion_zoom_center *= 0.95
		current_zoom_value *= 0.95
	elif event.is_action_pressed("zoom_out"):
		motion_zoom_center *= 1.05
		current_zoom_value *= 1.05

func player_defeated() -> bool:
	return (
		# character is deleted upon replaying the round
		$combatants.has_node("character")
		and( 
			(
				not $combatants/player_carrier.is_alive
				and not $combatants/character.is_alive
			) or (
				0. == current_laupeerium
				and not $combatants/character.is_alive
			)
		)
	)

func are_you_winning_son() -> bool:
	return (
		not player_defeated()
		and 0 == living_team_members[2]
	)

var kill_score: float = 0.
@export var kill_score_multiplier: float = 100.
@export var resource_score_multiplier: float = 500.
func _on_battle_character_dead(character: BattleCharacter) -> void:
	if is_replay: return
	var dead_character_team = character.team
	living_team_members[dead_character_team.team_id] -= 1
	if $combatants/character.team.is_enemy(dead_character_team):
		kill_score += character.starting_health * Difficuilty.gameplay_speed
	$GUI/score.set_text(str(
		living_team_members[1], " vs ", living_team_members[2],
		" - Score: ", int(kill_score * kill_score_multiplier)
	))
	if player_defeated():
		$GUI/victory.set_visible(false)
		$GUI/restart_round_panel.set_visible(false)
		$GUI/defeat.set_visible(true)
	elif are_you_winning_son():
		$GUI/restart_round_panel.set_visible(false)
		$GUI/defeat.set_visible(false)
		$GUI/victory.set_visible(true)
		$GUI/score.set_text(str(
			living_team_members[1], " vs ", living_team_members[2],
			" - Score: ", int(kill_score * kill_score_multiplier + current_laupeerium * resource_score_multiplier)
		))
	elif $combatants.has_node("character") and not $combatants/character.is_alive:
		$GUI/victory.set_visible(false)
		$GUI/defeat.set_visible(false)
		$GUI/restart_round_panel.set_visible(true)

func _on_battle_character_resurrected(character: BattleCharacter) -> void:
	if is_replay: return
	if $combatants.has_node("character") and $combatants/character.is_alive:
		$GUI/restart_round_panel.set_visible(false)
	living_team_members[character.team.team_id] += 1
	$GUI/score.set_text(str(
		living_team_members[1], " vs ", living_team_members[2],
		" - Score: ", int(kill_score * kill_score_multiplier)
	))

const one_weapon_slot_width_with_padding: float = 128.5
func _on_weapon_changed(slot: int) -> void:
	$GUI/selected_weapon_panel.transform.origin.y = float(slot) * one_weapon_slot_width_with_padding

var is_replay = false
func _on_replay_button_pressed() -> void:
	is_replay = true
	replay_viewport = Rect2()
	for c in $combatants.get_children():
		replay_viewport.expand(c.get_global_position())
		if c.has_node("ai_control"):
			c.ai_fallback = false
			c.get_node("ai_control").set_disabled(true)
		entangle_ship_with_player(c)
		if c.has_node("target_assist"):
			c.get_node("target_assist").set_disabled(true)
	restart_round(false)
	$player_input.set_disabled(true)
	$combatants/character.queue_free()
	$replay_camera.make_current()
	$GUI/restart_during_replay.set_visible(true)
	$GUI/score.set_visible(false)
