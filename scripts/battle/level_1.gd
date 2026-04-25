extends BaseBattle

func _ready() -> void:
	super()
	spawn_position = $combatants/player_carrier.global_position
	player_input.input_disabled = true
	GUI.set_objective("")
	GUI.set_disabled_weapons_mask(0xC)
	GUI.set_laupeerium_indicator(UIEnergyBar.max_bars / 5.)
	%character.set_disabled_weapons_mask(0xC)
	$dialogues/intro.start()
	$dialogues/intro.connect(
		"dialogue_signal_0",
		func(): GUI.set_objective("Destroy Silo Door\nCollect Laupeerium\nSurvive")
	)
	
	$dialogues/that_went_well.connect(
		"dialogue_signal_0",
		func(): 
			var boss : DrSpeedo = preload("res://scenes/entities/level1_boss.tscn").instantiate()
			boss.name = "boss"
			var to_player: Vector2 = (%character.global_position - %player_carrier.global_position)
			if to_player.length() < %player_carrier.approx_size * 2.:
				boss.set_global_position(%player_carrier.global_position + to_player.normalized() * 1000.)
			else: boss.set_global_position((%character.global_position + %player_carrier.global_position) * 0.5)
			boss.look_at(%character.get_global_position())
			boss.acquired_target = %character
			boss.dead.connect(_on_boss_death)
			boss.recuperation_time_left_sec = 0.
			boss.time_until_next_attack_sec = 0.
			$combatants.add_child(boss)
			GUI.set_objective("Lead Dr Speedo into\nthe nearby Black hole")
			for c in $combatants.get_children(): c.pause_control()
			$timeline.checkpoint()
			create_tween().tween_method(
				func(w: float):
					player_input.current_zoom_value = w
					view_control_triggered({"zoom": player_input.current_zoom_value}),
				player_input.current_zoom_value, 0.2, 1.
			)
	)

func _on_player_carrier_phased(phased_in: bool) -> void:
	%character.visible = phased_in

func _on_intro_dialouge_finished() -> void:
	player_input.input_disabled = false
	$timeline.checkpoint()

var summoning_dr_speedo: bool = false
func _on_silo_payload_reached() -> void:
	$debris/silo.sonar_blip_lifetime = 1.
	$debris/silo.sonar_blip_scale = Vector2(1.0, 1.0)
	create_tween().tween_method(
		func(w: float): GUI.set_laupeerium_indicator(w),
		UIEnergyBar.max_bars / 5., UIEnergyBar.max_bars, 0.5
	).set_ease(Tween.EASE_OUT)
	get_tree().create_timer(5.).timeout.connect( func():
		if %character.in_battle():
			summoning_dr_speedo = true
			$dialogues/that_went_well.start()
			for c in $combatants.get_children():
				c.pause_control()
				c.velocity = Vector2.ZERO
	)

func time_control_triggered(action: Dictionary) -> void:
	if not summoning_dr_speedo:	super(action)

func _on_that_went_well_dialouge_finished() -> void:
	for c in $combatants.get_children(): c.resume_control()
	summoning_dr_speedo = false

func _on_boss_death(_boss: BattleCharacter) -> void:
	for c in $combatants.get_children(): c.pause_control()
	$dialogues/scurry.start()

func _on_scurry_dialouge_finished() -> void:
	GUI.get_node("restart_round_panel").set_visible(false)
	GUI.get_node("victory").set_visible(true)
	GUI.get_node("victory/replay_button").set_visible(false)
	GUI.get_node("victory/restart_button").set_visible(false)
	get_tree().create_timer(5.).timeout.connect(func():
		var level_container: Node2D = get_node("/root/Main/LevelContainer")
		var level = load("res://scenes/UI/galaxy.tscn").instantiate()
		level.get_node("main_cam").make_current()
		for n in level_container.get_children(): n.queue_free()
		GUI.set_visible(false)
		level_container.add_child(level)
	)

var already_triggered: bool = false
func _on_silo_doors_toggled(is_open: bool) -> void:
	if is_open and not already_triggered:
		already_triggered = true
