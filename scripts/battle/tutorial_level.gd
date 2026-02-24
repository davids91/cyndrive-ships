extends Node2D

enum TutorialPhases{INTRO, MOVEMENT, BOOST, DESTROY, DESTROY_AGAIN}

const time_to_get_to_marker: float = 5.

var marker_time_left_secs: float = time_to_get_to_marker
var current_tutorial_phase: TutorialPhases = TutorialPhases.INTRO
func _ready():
	$combatants/character/weapon_slot.disabled = true
	$combatants/player_carrier.phased_in.connect(func():
		$dialogues/intro.start()
		$combatants/character.set_visible(true)
		$player_input.input_disabled = false
	)
	$combatants/player_carrier.phase_in()

	# Show keybindings
	$dialogues/intro.connect(
		"dialogue_signal_0",
		func(): $GUI/keybindings_panel.set_visible(true)
	)

	# Show booster marker
	$dialogues/boost.connect( "dialogue_signal_0", func():
		$markers/marker2.set_visible(true)
		var show_next_tween = create_tween()
		show_next_tween.tween_method(
			func(w: float): $combatants/character/cam.set_global_position(lerp(
				$combatants/character/cam.get_global_position(),
				$markers/marker2.get_position(),
				w
			)),
			0., 1., 3.
		)
		show_next_tween.tween_callback(func(): $GUI.set_time(0, marker_time_left_secs))
		show_next_tween.tween_interval(1.)
		show_next_tween.tween_method(
			func(w: float): $combatants/character/cam.position *= w,
			1., 0., 1.
		)
	)

	# Deploy stolen droid
	$dialogues/destroy.connect(
		"dialogue_signal_0",
		func(): 
			$combatants/disabled_droid.modulate.a = 0.
			$combatants/disabled_droid.set_visible(true)
			create_tween().tween_method(func(w: float): $combatants/disabled_droid.modulate.a = w, 0., 1., 0.8)
			create_tween().tween_method(func(w: float): $combatants/disabled_droid.position.y = w, -3200., -3500., 0.8)
	)

var currently_failing_at_markers: bool = false
var last_entered_marker: BattleMarker
func _process(delta: float) -> void:
	if current_tutorial_phase == TutorialPhases.BOOST:
		marker_time_left_secs -= delta
		if marker_time_left_secs <= 0.:
			currently_failing_at_markers = true
			marker_time_left_secs = time_to_get_to_marker
			var reset_tween = create_tween()
			reset_tween.tween_method(func(w: float): $GUI/fade_to_black.self_modulate.a = w, 0., 1. , 0.5).set_ease(Tween.EASE_IN)
			reset_tween.tween_callback(func():
				$combatants/character.correct_temporal_state($combatants/character.spawn_snapshot)
				create_tween().tween_method(func(w: float): $GUI/try_again.modulate.a = w, 1., 0., 3.)
				if last_entered_marker: 
					last_entered_marker.set_visible(true)
					create_tween().tween_method(func(w: float): last_entered_marker.modulate.a = w, 1., 0., 0.5)
			)
			reset_tween.tween_method(func(w: float): $GUI/fade_to_black.self_modulate.a = w, 1., 0. , 0.3).set_ease(Tween.EASE_OUT).finished.connect(
				func(): currently_failing_at_markers = false
			)
		$GUI.set_time(0, marker_time_left_secs)

func _on_marker_body_entered(body: Node2D) -> void:
	if "is_player" in body and body.is_player and current_tutorial_phase == TutorialPhases.MOVEMENT:
		$player_input.input_disabled = true
		create_tween().tween_method(func(w: float): $markers/marker.modulate.a = w, 1., 0., 0.5)
		$dialogues/boost.start()
		body.pause_control()
		body.velocity = Vector2.ZERO
		last_entered_marker = $markers/marker

func _on_character_boost_energy_updated(new_energy_level: float) -> void:
	if new_energy_level < 8.: # TechDebt: This should be provided by the character energy systems
		$dialogues/boost.dialogue_conditionals[0] = true

func _on_intro_dialouge_finished() -> void:
	current_tutorial_phase = TutorialPhases.MOVEMENT
	$markers/marker.set_visible(true)
	create_tween().tween_method(func(w: float): $markers/marker.modulate.a = w, 0., 1., 0.5)

func _on_boost_dialouge_finished() -> void:
	current_tutorial_phase = TutorialPhases.BOOST
	$timeline.checkpoint()
	$markers/marker2.set_visible(true)
	$player_input.input_disabled = false
	$combatants/character/sonar_sensor.add_blip($markers/marker2)
	$combatants/character.spawn_snapshot = $combatants/character.get_snapshot()
	$combatants/character.resume_control()
	$combatants/character/temporal_recorder.start_recording()

func _on_marker_2_body_entered(_body: Node2D) -> void:
	if currently_failing_at_markers: return
	if $markers/marker: $markers/marker.queue_free()
	last_entered_marker = $markers/marker2
	$combatants/character.spawn_snapshot = $combatants/character.get_snapshot()
	create_tween().tween_method(func(w: float): $markers/marker2.modulate.a = w, 1., 0., 0.5).finished.connect(
		func(): $markers/marker2.set_visible(false)
	)
	$markers/marker3.set_visible(true)
	$combatants/character/sonar_sensor.add_blip($markers/marker3)
	marker_time_left_secs = time_to_get_to_marker

func _on_marker_3_body_entered(_body: Node2D) -> void:
	if currently_failing_at_markers: return
	if $markers/marker2: $markers/marker2.queue_free()
	last_entered_marker = $markers/marker3
	$combatants/character.spawn_snapshot = $combatants/character.get_snapshot()
	create_tween().tween_method(func(w: float): $markers/marker3.modulate.a = w, 1., 0., 0.5).finished.connect(
		func(): $markers/marker3.set_visible(false)
	)
	$markers/marker4.set_visible(true)
	$combatants/character/sonar_sensor.add_blip($markers/marker4)
	marker_time_left_secs = time_to_get_to_marker

func _on_marker_4_body_entered(_body: Node2D) -> void:
	if currently_failing_at_markers: return
	if $markers/marker3: $markers/marker3.queue_free()
	last_entered_marker = $markers/marker4
	$combatants/character.spawn_snapshot = $combatants/character.get_snapshot()
	create_tween().tween_method(func(w: float): $markers/marker4.modulate.a = w, 1., 0., 0.5).finished.connect(
		func(): $markers/marker4.set_visible(false)
	)
	$markers/marker5.set_visible(true)
	$combatants/character/sonar_sensor.add_blip($markers/marker5)
	marker_time_left_secs = time_to_get_to_marker

func _on_marker_5_body_entered(_body: Node2D) -> void:
	if currently_failing_at_markers: return
	current_tutorial_phase = TutorialPhases.DESTROY
	$markers/marker4.queue_free()
	last_entered_marker = $markers/marker5
	$combatants/character.spawn_snapshot = $combatants/character.get_snapshot()
	create_tween().tween_method(func(w: float): $markers/marker5.modulate.a = w, 1., 0., 0.5).finished.connect(
		func(): $markers/marker5.queue_free()
	)
	$player_input.input_disabled = true
	$combatants/character.pause_control()
	$combatants/character.velocity = Vector2.ZERO
	$dialogues/destroy.start()

func _on_destroy_dialouge_finished() -> void:
	$player_input.input_disabled = false
	$combatants/character/weapon_slot.disabled = false
	$combatants/character.resume_control()

#TODO: set objective text
#TODO: keep track if the droid is restored
#TODO: keep track if the droid is destroyed with mines
#TODO: enable/disable weapon slots

func _on_disabled_droid_dead(_itsme: BattleCharacter) -> void:
	current_tutorial_phase = TutorialPhases.DESTROY_AGAIN
	$player_input.input_disabled = true
	$combatants/character.pause_control()
	$combatants/character/weapon_slot.shutdown()
	$combatants/character.velocity = Vector2.ZERO
	$dialogues/destroy_again.start()
