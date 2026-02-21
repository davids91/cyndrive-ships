extends Node2D

enum TutorialPhases{INTRO, MOVEMENT, BOOST}

const time_to_get_to_marker: float = 5.

var marker_time_left_secs: float = time_to_get_to_marker
var current_tutorial_phase: TutorialPhases = TutorialPhases.INTRO
func _ready():
	$combatants/player_carrier.phased_in.connect(func():
		$dialogues/intro.set_visible(true)
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

var rewinding_to_previous_mark: bool = false
func _process(delta: float) -> void:
	if current_tutorial_phase == TutorialPhases.BOOST:
		if rewinding_to_previous_mark:
			marker_time_left_secs += delta
			$timeline.reverse(delta)
			if marker_time_left_secs >= time_to_get_to_marker:
				$timeline.finish_reverse()
				rewinding_to_previous_mark = false
		else:
			marker_time_left_secs -= delta
			if marker_time_left_secs <= 0.:
				rewinding_to_previous_mark = true
		$GUI.set_time(0, marker_time_left_secs)

func _on_marker_body_entered(body: Node2D) -> void:
	if "is_player" in body and body.is_player and current_tutorial_phase == TutorialPhases.MOVEMENT:
		$player_input.input_disabled = true
		$markers/marker.queue_free()
		$dialogues/boost.set_visible(true)
		$dialogues/boost.start()
		$dialogues/intro.set_visible(false)
		$dialogues/boost.is_dialogue_active = true
		body.pause_control()
		body.velocity = Vector2.ZERO

func _on_character_boost_energy_updated(new_energy_level: float) -> void:
	if new_energy_level < 8.: # TechDebt: This should be provided by the character energy systems
		$dialogues/boost.dialogue_conditionals[0] = true

func _on_intro_dialouge_finished() -> void:
	current_tutorial_phase = TutorialPhases.MOVEMENT
	$markers/marker.set_visible(true)

func _on_boost_dialouge_finished() -> void:
	current_tutorial_phase = TutorialPhases.BOOST
	$timeline.checkpoint()
	$markers/marker2.set_visible(true)
	$player_input.input_disabled = false
	$combatants/character/sonar_sensor.add_blip($markers/marker2)
	$combatants/character.resume_control()

func _on_marker_2_body_entered(_body: Node2D) -> void:
	$markers/marker2.queue_free()
	$markers/marker3.set_visible(true)
	$combatants/character/sonar_sensor.add_blip($markers/marker3)
	marker_time_left_secs = time_to_get_to_marker

func _on_marker_3_body_entered(_body: Node2D) -> void:
	$markers/marker3.queue_free()
	$markers/marker4.set_visible(true)
	$combatants/character/sonar_sensor.add_blip($markers/marker4)
	marker_time_left_secs = time_to_get_to_marker

func _on_marker_4_body_entered(_body: Node2D) -> void:
	$markers/marker4.queue_free()
	$markers/marker5.set_visible(true)
	$combatants/character/sonar_sensor.add_blip($markers/marker5)
	marker_time_left_secs = time_to_get_to_marker

func _on_marker_5_body_entered(_body: Node2D) -> void:
	$markers/marker5.queue_free()
