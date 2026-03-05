extends CanvasLayer

signal restart_round()
signal replay_game()
signal reset_game()

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
	$status_padding/battleship_status/laupeerium.bars_remaining = bars

func _on_character_boost_energy_updated(new_energy_level: float) -> void:
	$status_padding/battleship_status/boost_energy.energy_updated(new_energy_level)

func _on_character_weapon_energy_updated(new_energy_level: float) -> void:
	$selected_weapon_panel/weapon_energy.energy_updated(new_energy_level)

func _on_restart_button_pressed() -> void:
	restart_round.emit()

func _on_replay_button_pressed() -> void:
	replay_game.emit()

func _on_reset_game_pressed() -> void:
	reset_game.emit()

func _on_timeline_round_reset() -> void:
	pass # Replace with function body.
