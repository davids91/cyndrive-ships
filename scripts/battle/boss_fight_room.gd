extends BaseBattle

func _on_battle_character_dead(itsme: BattleCharacter) -> void:
	if itsme is PlayerShip or itsme is DrSpeedo or itsme is MrMustle:
		create_new_puppet($combatants/character)
		$timeline.reset()
