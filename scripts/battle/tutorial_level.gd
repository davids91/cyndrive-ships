extends Node2D

enum TutorialPhases{
	INTRO, MOVEMENT, BOOST,
	DESTROY, RESTORE, EXPLODE,
	MUSTLE_ARRIVES, ROUND_RESET, MUSTLE_FIGHT
}

const time_to_get_to_marker: float = 5.

@export var GUI: BattleShipGUI
@export var gui_visible: bool = true
@onready var player_input: PlayerInput = get_node("/root/Main/player_input")

var boost_dialogue_showing_next_mark_tween: Tween
var marker_time_left_secs: float = time_to_get_to_marker
var current_tutorial_phase: TutorialPhases = TutorialPhases.INTRO
func _ready():
	GUI.set_score("Objective:")
	GUI.set_objective("")
	GUI.set_disabled_weapons_mask(0xE)
	GUI.set_laupeerium_indicator(UIEnergyBar.max_bars / 4.)
	GUI.get_node("pause_menu").restart_round_button_visible(false)
	$combatants/disabled_droid/skin.set_visible(false)
	%character.disabled_weapons_mask = 0xE
	%character/weapon_slot.disabled = true
	%player_carrier.phase_in()

	# Show keybindings
	$dialogues/intro.connect(
		"dialogue_signal_0",
		func(): GUI.get_node("keybindings_panel").set_visible(true)
	)
	
	# Display start mark
	$dialogues/intro.connect(
		"dialogue_signal_1",
		func():
			$markers/marker.set_visible(true)
			create_tween().tween_method(func(w: float): $markers/marker.modulate.a = w, 0., 1., 0.5)
			GUI.set_objective("Follow the\nred arrows")
	)

	# Show booster marker
	$dialogues/boost.connect( "dialogue_signal_0", func():
		$markers/marker2.set_visible(true)
		boost_dialogue_showing_next_mark_tween = create_tween()
		boost_dialogue_showing_next_mark_tween.tween_method(
			func(w: float): %character/cam.set_global_position(lerp(
				%character/cam.get_global_position(),
				$markers/marker2.get_position(),
				w
			)),
			0., 1., 3. * Difficulty.gameplay_speed
		)
		boost_dialogue_showing_next_mark_tween.tween_interval(1.)
		boost_dialogue_showing_next_mark_tween.tween_method(
			func(w: float): %character/cam.position *= w,
			1., 0., 1. * Difficulty.gameplay_speed
		)
	)

	# Deploy stolen droid
	$dialogues/destroy.connect(
		"dialogue_signal_0",
		func(): 
			$combatants/disabled_droid/skin.set_visible(true)
			$combatants/disabled_droid.modulate.a = 0.
			$combatants/disabled_droid.set_visible(true)
			create_tween().tween_method(func(w: float): $combatants/disabled_droid.modulate.a = w, 0., 1., 0.8)
			create_tween().tween_method(func(w: float): $combatants/disabled_droid.position.y = w, -3200., -3800., 0.8)
	)

	# Summon boss!
	$dialogues/boss_arrives.connect(
		"dialogue_signal_0",
		func(): 
			var to_player: Vector2 = (%character.get_global_position() - %player_carrier.get_global_position())
			var boss = preload("res://scenes/entities/tutorial_boss.tscn").instantiate()
			boss.name = "boss"
			boss.set_global_position(%character.get_global_position() + to_player.normalized() * 1000.)
			boss.look_at(%character.get_global_position())
			boss.control_disabled = true
			boss.difficulty_sensor_speed = 0.4
			boss.difficulty_laser_speed = 0.5
			boss.time_until_lasers = 0.5
			boss.acquired_target = %character
			boss.change_target_to = %character # TechDebt: if change_target_to differs from acquired target there's some UB
			boss.focusing_at = %character.get_global_position()
			boss.moving_to = %character.get_global_position() + Vector2(900., 0.)
			boss.connect("health_changed", _on_boss_health_changed)
			$combatants.add_child(boss)
			GUI.set_objective("New ship\nwho dis?")
	)

var currently_failing_at_markers: bool = false
func _process(delta: float) -> void:
	GUI.get_node("debug_stats/fps").set_text("%s fps" % Engine.get_frames_per_second())
	if(
		current_tutorial_phase == TutorialPhases.MUSTLE_ARRIVES
		or current_tutorial_phase == TutorialPhases.ROUND_RESET
		or current_tutorial_phase == TutorialPhases.MUSTLE_FIGHT
	): GUI.set_time(BattleTimeline.instance.time_msec() / 1000.)
	
	if is_rewinding:
		$timeline.reverse(delta)
		GUI.get_node("rewind_effects").material.set_shader_parameter("rewind_amount", BattleTimeline.instance.player_rewind_amount_sec)

	if current_tutorial_phase == TutorialPhases.BOOST:
		marker_time_left_secs -= delta
		if marker_time_left_secs <= 0.:
			currently_failing_at_markers = true
			marker_time_left_secs = time_to_get_to_marker
			var reset_tween: Tween = create_tween()
			reset_tween.tween_method(func(w: float): $level_ui/fade_to_black.self_modulate.a = w, 0., 1. , 0.5).set_ease(Tween.EASE_IN)
			reset_tween.tween_callback(func():
				%character.correct_temporal_state(%character.spawn_snapshot)
				if %character.held_mine:
					%character.held_mine.correct_temporal_state(%character.held_mine.spawn_snapshot)
				create_tween().tween_method(func(w: float): $level_ui/try_again.modulate.a = w, 1., 0., 3.)
			)
			reset_tween.tween_method(func(w: float): $level_ui/fade_to_black.self_modulate.a = w, 1., 0. , 0.3).set_ease(Tween.EASE_OUT).finished.connect(
				func(): currently_failing_at_markers = false
			)
		GUI.set_time(marker_time_left_secs)

func _unhandled_input(event: InputEvent) -> void:
	var just_pressed = event.is_pressed() and not event.is_echo()
	if event.is_action_pressed("key_bindings") and just_pressed:
		GUI.get_node("keybindings_panel").set_visible(not GUI.get_node("keybindings_panel").visible)

func _on_player_carrier_phased(phased_in: bool) -> void:
	$dialogues/intro.start()
	%character.set_visible(phased_in)

func _on_marker_body_entered(body: Node2D) -> void:
	if "is_player" in body and body.is_player and current_tutorial_phase == TutorialPhases.MOVEMENT:
		player_input.input_disabled = true
		create_tween().tween_method(func(w: float): $markers/marker.modulate.a = w, 1., 0., 0.5)
		$dialogues/boost.start()
		body.pause_control()
		body.velocity = Vector2.ZERO

func _on_character_boost_energy_updated(new_energy_level: float) -> void:
	if new_energy_level < 8.: # TechDebt: This should be provided by the character energy systems
		$dialogues/boost.dialogue_conditionals[0] = true

@export var info_highlight_blink_length_sec: float = 0.4
func _on_intro_dialouge_finished() -> void:
	player_input.input_disabled = false
	current_tutorial_phase = TutorialPhases.MOVEMENT
	create_tween().tween_method(func(w: float): $level_ui/marks_progress.modulate.a = w, 0., 1., 0.5)
	GUI.get_node("keybindings_panel").set_visible(false)
	var blink_info_tween = create_tween()
	for _i in 3:
		blink_info_tween.tween_method(func(w: float): GUI.get_node("info_highlight").modulate.a = w, 0., 1., info_highlight_blink_length_sec)
	blink_info_tween.tween_method(func(w: float): GUI.get_node("info_highlight").modulate.a = w, 1., 0., info_highlight_blink_length_sec)

func _on_boost_dialouge_finished() -> void:
	current_tutorial_phase = TutorialPhases.BOOST
	if boost_dialogue_showing_next_mark_tween: boost_dialogue_showing_next_mark_tween.kill()
	GUI.set_time(marker_time_left_secs)
	$markers/marker2.set_visible(true)
	player_input.input_disabled = false
	%character/cam.position = Vector2.ZERO
	%character/sonar_sensor.add_blip($markers/marker2)
	%character.spawn_snapshot = %character.get_snapshot()
	$timeline.checkpoint()
	%character.resume_control()
	%character/temporal_recorder.start_recording()

func _on_marker_2_body_entered(_body: Node2D) -> void:
	if currently_failing_at_markers or not $markers/marker2.visible: return
	create_tween().tween_property(%marks_progress, "value", 100. / 4., 0.6)
	if $markers/marker: $markers/marker.queue_free()
	%character.spawn_snapshot = %character.get_snapshot()
	create_tween().tween_method(func(w: float): $markers/marker2.modulate.a = w, 1., 0., 0.5).finished.connect(
		func(): $markers/marker2.set_visible(false)
	)
	$markers/marker3.set_visible(true)
	%character/sonar_sensor.add_blip($markers/marker3)
	marker_time_left_secs = time_to_get_to_marker

func _on_marker_3_body_entered(_body: Node2D) -> void:
	if currently_failing_at_markers or not $markers/marker3.visible: return
	create_tween().tween_property(%marks_progress, "value", 200. / 4., 0.6)
	if $markers/marker2: $markers/marker2.queue_free()
	%character.spawn_snapshot = %character.get_snapshot()
	create_tween().tween_method(func(w: float): $markers/marker3.modulate.a = w, 1., 0., 0.5).finished.connect(
		func(): $markers/marker3.set_visible(false)
	)
	$markers/marker4.set_visible(true)
	%character/sonar_sensor.add_blip($markers/marker4)
	marker_time_left_secs = time_to_get_to_marker

func _on_marker_4_body_entered(_body: Node2D) -> void:
	if currently_failing_at_markers or not $markers/marker4.visible: return
	create_tween().tween_property(%marks_progress, "value", 300. / 4., 0.6)
	if $markers/marker3: $markers/marker3.queue_free()
	%character.spawn_snapshot = %character.get_snapshot()
	create_tween().tween_method(func(w: float): $markers/marker4.modulate.a = w, 1., 0., 0.5).finished.connect(
		func(): $markers/marker4.set_visible(false)
	)
	$markers/marker5.set_visible(true)
	%character/sonar_sensor.add_blip($markers/marker5)
	marker_time_left_secs = time_to_get_to_marker

func _on_marker_5_body_entered(_body: Node2D) -> void:
	if currently_failing_at_markers or not $markers/marker5.visible: return
	create_tween().tween_property(%marks_progress, "value", 400. / 4., 0.6)
	create_tween().tween_method(func(w: float): $level_ui/marks_progress.modulate.a = w, 1., 0., 0.5)
	current_tutorial_phase = TutorialPhases.DESTROY
	$markers/marker4.queue_free()
	%character.spawn_snapshot = %character.get_snapshot()
	create_tween().tween_method(func(w: float): $markers/marker5.modulate.a = w, 1., 0., 0.5).finished.connect(
		func(): $markers/marker5.queue_free()
	)
	player_input.input_disabled = true
	%character.pause_control()
	%character.velocity = Vector2.ZERO
	$dialogues/destroy.start()

func _on_destroy_dialouge_finished() -> void:
	player_input.input_disabled = false
	%character/weapon_slot.disabled = false
	%character.resume_control()
	$combatants/disabled_droid/temporal_recorder.start_recording()
	%character/temporal_recorder.start_recording()
	$timeline.checkpoint()
	GUI.set_objective("Destroy\nthe prototype droid")

func _on_player_carrier_equipped_ship_with_mine(_ship: BattleCharacter) -> void:
	$dialogues/restore.dialogue_conditionals[0] = true

func _on_boss_arrives_dialouge_finished() -> void:
	current_tutorial_phase = TutorialPhases.MUSTLE_ARRIVES
	$timeline.checkpoint()
	%character/controller.process_input_action({
		"movement_intent": (%character.get_global_position() - %player_carrier.get_global_position()).normalized()
	})
	%character.resume_control()
	%character/temporal_recorder.start_recording()
	$combatants/boss.control_disabled = false
	GUI.set_objective("Try not to die a lot")

func _on_restore_dialouge_finished() -> void:
	player_input.input_disabled = false
	%character.resume_control()
	GUI.set_objective("Hold R to rewind\n(resurrect dummy droid)")

func _on_disabled_droid_dead(itsme: BattleCharacter) -> void:
	if current_tutorial_phase == TutorialPhases.DESTROY: 
		current_tutorial_phase = TutorialPhases.RESTORE
		%character/weapon_slot.shutdown()
		%character.pause_control()
		%character.velocity = Vector2.ZERO
		$dialogues/restore.start()
		GUI.set_objective("WHAT HAVE YOU DONE")
		player_input.input_disabled = true
	elif(
		current_tutorial_phase == TutorialPhases.EXPLODE
		and "last_source_of_damage" in itsme and itsme.last_source_of_damage is Explosion
	):
		await get_tree().create_timer(0.5).timeout # wait a bit, maybe player was caught in mine explosion
		if not %character.in_battle(): return
		current_tutorial_phase = TutorialPhases.MUSTLE_ARRIVES
		player_input.input_disabled = true
		GUI.set_objective("mmmm!\nCrisp!")
		for obj: Node2D in $mush.get_children(): # TechDebt: explosion may kill the player during dialogue
			if "explosion_damage" in obj: obj.explosion_damage = 0.
		get_tree().create_timer(0.8).timeout.connect(func(): 
			%character.velocity = Vector2.ZERO
			%character.pause_control()
			# Move the player next to the ship if it's outside
			var player_carrier_position_ratio: float = 0.3
			if( # Move the player outside the ship if it's insie
				%player_carrier.approx_size 
				< (%player_carrier.get_global_position() - %character.get_global_position()).length()
			): player_carrier_position_ratio = 1.7
			create_tween().tween_property(
				%character, "global_position",
				lerp(
					%player_carrier.get_global_position(),
					%character.get_global_position(),
					player_carrier_position_ratio
				),
				0.2
			).finished.connect(func():
				var to_player: Vector2 = (%player_carrier.get_global_position() - %character.get_global_position())
				if %player_carrier.approx_size < to_player.length():
					var new_pos: Vector2 =(
						%player_carrier.get_global_position()
						+ to_player.normalized() * %player_carrier.approx_size * 1.2
					)
					create_tween().tween_property(%character, "global_position", new_pos, 0.5)
			)
		)
		$dialogues/boss_arrives.start()
		if itsme: itsme.queue_free()

func _on_disabled_droid_resurrected(_itsme: BattleCharacter) -> void:
	if current_tutorial_phase == TutorialPhases.RESTORE:
		current_tutorial_phase = TutorialPhases.EXPLODE
		GUI.set_objective("E to equip mine\n within carrier;\nE to deploy it!")

@export var rewind_animation_transition_sec: float = 0.75
var is_rewinding: bool = false
func time_control_triggered(action: Dictionary) -> void:
	if(
		current_tutorial_phase == TutorialPhases.MOVEMENT
		or current_tutorial_phase == TutorialPhases.BOOST
		or current_tutorial_phase == TutorialPhases.DESTROY
	): return
	if "rewind_toggled" in action:
		is_rewinding = action["rewind_toggled"]
		if is_rewinding:
			GUI.get_node("rewind_effects").set_visible(true)
			create_tween().tween_method(
				func(w: float): GUI.get_node("rewind_effects").material.set_shader_parameter("rewind_intensity", w),
				0., 1., rewind_animation_transition_sec
			)
		if not action["rewind_toggled"]:
			$timeline.finish_reverse()
			var rewind_hide_tween: Tween = create_tween()
			rewind_hide_tween.tween_method(
				func(w: float): GUI.get_node("rewind_effects").material.set_shader_parameter("rewind_intensity", w),
				1., 0., rewind_animation_transition_sec
			)
			rewind_hide_tween.tween_callback(func() : GUI.get_node("rewind_effects").set_visible(false))
			rewind_hide_tween.chain()
	
	if(
		"checkpoint_reset_triggered" in action and action["checkpoint_reset_triggered"]
		and not is_rewinding
	):
		# Handling Battle restart
		if current_tutorial_phase == TutorialPhases.ROUND_RESET:
			current_tutorial_phase = TutorialPhases.MUSTLE_FIGHT
			$dialogues/player_dies.finish()
			replay_round(func():
				for combatant in $combatants.get_children():
					combatant.pause_control()
				$dialogues/player_resurrected.start()
			)
		else: replay_round()

func reset_game() -> void:
	get_tree().reload_current_scene()

@export var respawn_time_sec: float = 1.
func replay_round(call_on_restart: Callable = func(): pass) -> void:
	#TechDebt: Eliminate mine after round end
	if not %character.held_mine == null:
		%character.held_mine.queue_free()

	# Stop the fighting ( respawn will resume control )
	for combatant in $combatants.get_children():
		if "pause_control" in combatant:
			combatant.pause_control()

	 # Create a clone of the ship
	create_new_puppet(%character)

	# Set up UI for the new round
	GUI.get_node("rewind_effects").set_visible(true)

	# Move the player to its spawn position
	var player_move_tween: Tween = create_tween()
	player_move_tween.tween_method(
		func(pos):
			%character.set_global_position(pos)
			GUI.get_node("rewind_effects").material.set_shader_parameter(
				"rewind_amount",
				-(pos - %character.spawn_snapshot["transform"].origin).length() / 500.
			),
		%character.get_global_position(),
		%character.spawn_snapshot["transform"].origin,
		respawn_time_sec
	)
	player_move_tween.tween_callback(func():
		for combatant in $combatants.get_children():
			if "pause_control" in combatant:
				combatant.resume_control()
		GUI.get_node("rewind_effects").set_visible(false)
		$timeline.reset()
		GUI.get_node("defeat").set_visible(false)
		GUI.get_node("victory").set_visible(false)
		GUI.get_node("restart_round_panel").set_visible(false)
		call_on_restart.call()
	)
	player_move_tween.chain()

func create_new_puppet(predecessor: BattleCharacter) -> void:
	var records = predecessor.get_node("temporal_recorder").stop_recording()
	var puppet =  preload("res://scenes/entities/base_ship.tscn").instantiate();
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

	# set new spawn position for the predecessor
	predecessor.spawn_snapshot["transform"].origin = (
		%player_carrier.spawn_snapshot["transform"].origin
		+ (
			(
				predecessor.get_global_position()
				- %player_carrier.spawn_snapshot["transform"].origin
			).normalized()
			* %player_carrier.approx_size
		)
	)

	# Add the new puppet to battle
	$combatants.add_child(puppet)
	predecessor.get_node("temporal_recorder").start_recording()

func _on_timeline_checkpoint_triggered() -> void:
	for container_path in ["combatants", "debris", "mush"]:
		if not has_node(container_path): continue
		for object in get_node(container_path).get_children():
			if "spawn_snapshot" in object and object.has_method("get_snapshot"):
				object.spawn_snapshot = object.get_snapshot()
			# TechDebt: Mines have a spawn time, and rewinding after a new checkpoint deletes them
			if "spawn_time_msec" in object: object.spawn_time_msec = -50000.

func _on_player_carrier_dead(_itsme: BattleCharacter) -> void:
	if not %character.in_battle():
		reset_game()

func _on_character_dead(_itsme: BattleCharacter) -> void:
	if current_tutorial_phase == TutorialPhases.MUSTLE_ARRIVES and $combatants/boss:
		$combatants/boss.difficulty_sensor_speed = 0.1
		$combatants/boss.difficulty_laser_speed = 0.25
		$combatants/boss.pause_control()
		%character.pause_control()
		%character.velocity = Vector2.ZERO
		$dialogues/player_dies.start()
		GUI.set_objective("Good job")
		current_tutorial_phase = TutorialPhases.ROUND_RESET
	elif(
		current_tutorial_phase == TutorialPhases.ROUND_RESET
		or current_tutorial_phase == TutorialPhases.MUSTLE_FIGHT
	): # Player is currently fighting mr Mustle, show limbo dialog
		GUI.get_node("restart_round_panel").set_visible(true)
	elif(
		current_tutorial_phase == TutorialPhases.INTRO
		or current_tutorial_phase == TutorialPhases.MOVEMENT
		or current_tutorial_phase == TutorialPhases.BOOST
		or current_tutorial_phase == TutorialPhases.DESTROY
	): # No way to reverse time in these phases, restart level
		var failed_level_tween: Tween = create_tween()
		failed_level_tween.tween_method(
			func(w: float): $level_ui/try_again.modulate.a = w, 0., 1., 1.
		).set_ease(Tween.EASE_IN)
		failed_level_tween.tween_method(
			func(w: float): $level_ui/fade_to_black.self_modulate.a = w,
			0., 1., 0.5
		).set_ease(Tween.EASE_IN).finished.connect(func(): reset_game())
	else: GUI.set_objective("Rewind to try again")

func _on_character_shields_toggled(turned_on: bool) -> void:
	if turned_on:
		$dialogues/player_dies.dialogue_conditionals[0] = true

func _on_player_resurrected_dialouge_finished() -> void:
	current_tutorial_phase = TutorialPhases.MUSTLE_FIGHT
	GUI.set_objective("Defeat Mr Mustle")
	GUI.get_node("pause_menu").restart_round_button_visible(true)
	player_input.input_disabled = false
	for combatant in $combatants.get_children():
		combatant.resume_control()
	%character/temporal_recorder.start_recording()
	$timeline.reset()

func _on_boss_health_changed(percentage: float) -> void:
	if percentage < 0.2:
		player_input.input_disabled = true
		%character.pause_control()
		%character.velocity = Vector2.ZERO
		$combatants/boss.phase_out()
		$dialogues/boss_defeated.start()
		GUI.set_objective("Completed")

func _on_boss_defeated_dialouge_finished() -> void:
	GUI.get_node("restart_round_panel").set_visible(false)
	GUI.get_node("victory").set_visible(true)
	GUI.get_node("victory/replay_button").set_visible(false)
	GUI.get_node("victory/restart_button").set_visible(false)
	get_tree().create_timer(5.).timeout.connect(func():
		get_tree().change_scene_to_file("res://scenes/galaxy.tscn")
	)

func _on_player_dies_dialouge_finished() -> void:
	player_input.input_disabled = false
	GUI.set_objective("Ctrl+R\nto try again")

func _on_character_resurrected(_itsme: BattleCharacter) -> void:
	if current_tutorial_phase == TutorialPhases.EXPLODE:
		GUI.set_objective("E to equip mine\n within carrier;\nE to deploy it!")

func _on_timeline_rewind_started() -> void:
	%background_music.pitch_scale = -1.

func _on_timeline_rewind_stopped() -> void:
	%background_music.pitch_scale = 1.

func replay_game() -> void: pass # Dummy function as there is no replay on this level
