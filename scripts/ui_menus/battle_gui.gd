class_name BattleShipGUI
extends CanvasLayer

signal replay_round()
signal replay_game()
signal reset_game()

@export var rewind_animation_transition_sec: float = 0.75

func configure(player_input: PlayerInput, level: Node2D, player: BattleCharacter) -> void:
	player_input.action_triggered.connect(player.process_input_action)
	player_input.time_control_triggered.connect(level.time_control_triggered)
	player.boost_energy_updated.connect(_on_character_boost_energy_updated)
	player.weapon_energy_updated.connect(_on_character_weapon_energy_updated)
	player.weapon_changed.connect(_on_weapon_changed)
	replay_game.connect(level.replay_game)
	reset_game.connect(level.reset_game)
	replay_round.connect(level.replay_round)
	
	level.get_node("timeline").rewind_stopped.connect(func(): 
		create_tween().tween_method(
			func(w: float): $rewind_effects.material.set_shader_parameter("rewind_intensity", w),
			1., 0., rewind_animation_transition_sec
		).finished.connect(func(): $rewind_effects.set_visible(false))
	)
	level.get_node("timeline").rewind_started.connect(func(): 
		$rewind_effects.set_visible(true)
		create_tween().tween_method(
			func(w: float): $rewind_effects.material.set_shader_parameter("rewind_intensity", w),
			0., 1., rewind_animation_transition_sec
		)
	)
	
	if "GUI" in level: level.GUI = self
	set_visible("gui_visible" in level and level.gui_visible)

func fade_to(color: Color, duration_sec: float = 0.5) -> PropertyTweener:
		return (
			create_tween()
			.tween_property($fade_to_black, "self_modulate", color, duration_sec)
			.set_ease(Tween.EASE_IN)
		)

var fade_radius: float = 0.0
func set_fade_radius(radius: float) -> void:
	$fade_to_black.get_material().set_shader_parameter("fade_radius", radius)

func transform_fade_radius(radius: float = 2., duration_sec: float = 0.5) -> MethodTweener:
	var old_radius = fade_radius
	fade_radius = radius
	return(
		create_tween()
		.tween_method(func(w: float): set_fade_radius(w), old_radius, fade_radius, duration_sec)
		.set_ease(Tween.EASE_IN)
	)

func set_objectives_header(score: String) -> void:
	$score.set_text(score)

func set_objective(text: String) -> void:
	$objective.set_text(text)

func set_time(seconds: float) -> void:
	$time.set_text("%d:%02d" % [int(seconds / 60.0), int(seconds) % 60])

var disabled_weapons_mask: int = 0x0
func set_disabled_weapons_mask(mask: int) -> void:
	disabled_weapons_mask = mask
	if 0 != (mask & 0x01): $laser_icon.set_visible(false)
	if 0 != (mask & 0x02): $hotsaber_icon.set_visible(false)
	if 0 != (mask & 0x04): $chain_lightning_icon.set_visible(false)
	if 0 != (mask & 0x08): $decoy_shooter_icon.set_visible(false)

func set_laupeerium_indicator(bars: float) -> void:
	%laupeerium_bar.bars_remaining = bars

func clear_sonar_blips() -> void:
	for blip in $sensors_display.get_children(): blip.queue_free()

func set_weapons_panel_visible(weapons_visible: bool) -> void:
	for n in get_tree().get_nodes_in_group("weapon_selector"): n.visible = weapons_visible
	set_disabled_weapons_mask(disabled_weapons_mask)

func _process(_delta: float) -> void:
	$debug_stats/fps.set_text("%s fps" % Engine.get_frames_per_second())
	if BattleTimeline.instance: #TechDebt: BattleTimeline may not be
		if BattleTimeline.instance.time_flow == BattleTimeline.TimeFlow.BACKWARD:
			$rewind_effects.material.set_shader_parameter("rewind_amount", BattleTimeline.instance.player_rewind_amount_sec)

func _unhandled_input(event: InputEvent) -> void:
	var just_pressed = event.is_pressed() and not event.is_echo()
	if event.is_action_pressed("key_bindings") and just_pressed:
		$keybindings_panel.set_visible(not $keybindings_panel.visible)

const one_weapon_slot_width_with_padding: float = 128.5
func _on_weapon_changed(slot: int) -> void:
	$selected_weapon_panel.transform.origin.y = float(slot) * one_weapon_slot_width_with_padding

func _on_character_boost_energy_updated(new_energy_level: float) -> void:
	%boost_energy_bar.energy_updated(new_energy_level)

func _on_character_weapon_energy_updated(new_energy_level: float) -> void:
	$selected_weapon_panel/weapon_energy.energy_updated(new_energy_level)

func _on_restart_button_pressed() -> void:
	replay_round.emit()

func _on_replay_button_pressed() -> void:
	replay_game.emit()

func _on_reset_game_pressed() -> void:
	reset_game.emit()
