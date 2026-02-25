extends BattleCharacter

signal equipped_ship_with_mine(ship: BattleCharacter)

func _on_mine_attachement_aura_equipped_ship(ship: BattleCharacter) -> void:
	equipped_ship_with_mine.emit(ship)
