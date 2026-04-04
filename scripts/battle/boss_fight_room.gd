extends BaseBattle

func _on_battle_character_dead(_itsme: BattleCharacter) -> void:
	create_new_puppet($combatants/character)
	$combatants/character.respawn()
	$timeline.reset()
