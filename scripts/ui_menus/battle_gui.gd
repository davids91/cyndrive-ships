extends CanvasLayer

signal restart_round()
signal replay_game()
signal reset_game()

func set_time(minutes: int, seconds: int) -> void:
	$time.set_text("%d:%02d" % [minutes, seconds % 60])

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
