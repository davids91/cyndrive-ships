class_name BattleShipGUI
extends CanvasLayer

signal replay_round()
signal replay_game()
signal reset_game()

func configure(player_input: PlayerInput, level: Node2D, player: BattleCharacter) -> void:
	player_input.action_triggered.connect(player.process_input_action)
	player_input.time_control_triggered.connect(level.time_control_triggered)
	player.boost_energy_updated.connect(_on_character_boost_energy_updated)
	player.weapon_energy_updated.connect(_on_character_weapon_energy_updated)
	replay_game.connect(level.replay_game)
	reset_game.connect(level.reset_game)
	replay_round.connect(level.replay_round)
	if "GUI" in level: level.GUI = self
	set_visible("gui_visible" in level and level.gui_visible)

func set_score(score: String) -> void:
	$score.set_text(score)

func set_objective(text: String) -> void:
	$objective.set_text(text)

func set_time(seconds: float) -> void:
	$time.set_text("%d:%02d" % [int(seconds / 60.0), int(seconds) % 60])

func set_disabled_weapons_mask(mask: int) -> void:
	if 0 != (mask & 0x01): $laser_icon.set_visible(false)
	if 0 != (mask & 0x02): $chain_lightning_icon.set_visible(false)
	if 0 != (mask & 0x04): $hotsaber_icon.set_visible(false)
	if 0 != (mask & 0x08): $decoy_shooter_icon.set_visible(false)

func set_laupeerium_indicator(bars: float) -> void:
	%laupeerium_bar.bars_remaining = bars

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
