extends BaseBattle

var objective_blip: Node2D
func _ready() -> void:
	super()
	spawn_position = $combatants/player_carrier.global_position
	player_input.input_disabled = true
	GUI.set_objective("")
	GUI.set_disabled_weapons_mask(0xC)
	GUI.set_laupeerium_indicator(UIEnergyBar.max_bars / 5.)
	objective_blip = %character/sonar_sensor.add_blip($debris/silo)
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
			boss.control_disabled = true
			boss.acquired_target = %character
			boss.dead.connect(_on_boss_death)
			boss.recuperation_time_left_sec = 0.
			boss.time_until_next_attack_sec = 0.
			$combatants.add_child(boss)
			GUI.set_objective("Destroy Silo Door\nCollect Laupeerium\nSURVIVE")
	)

func _on_player_carrier_phased(phased_in: bool) -> void:
	%character.visible = phased_in

func _on_intro_dialouge_finished() -> void:
	player_input.input_disabled = false

func _on_silo_payload_reached() -> void:
	objective_blip.queue_free()
	create_tween().tween_method(
		func(w: float): GUI.set_laupeerium_indicator(w),
		UIEnergyBar.max_bars / 5., UIEnergyBar.max_bars, 0.5
	).set_ease(Tween.EASE_OUT)
	get_tree().create_timer(5.).timeout.connect(
		func(): 
			$dialogues/bang.finish()
			$dialogues/that_went_well.start()
	)

func _on_that_went_well_dialouge_finished() -> void:
	if $combatants/boss:
		objective_blip = %character/sonar_sensor.add_blip($combatants/boss)
		$combatants/boss.control_disabled = false

func _on_boss_death(_boss: BattleCharacter) -> void:
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
		$dialogues/bang.start()
		already_triggered = true
