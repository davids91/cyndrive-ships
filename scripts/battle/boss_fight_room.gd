extends BaseBattle

func _ready() -> void:
	super()
	GUI.set_objectives_header("Information:")
	GUI.set_objective("Boss Death\nrestarts round")

func _on_battle_character_dead(itsme: BattleCharacter) -> void:
	if itsme is PlayerShip or itsme is DrSpeedo or itsme is MrMustle:
		create_new_puppet($combatants/character)
		$timeline.reset()
