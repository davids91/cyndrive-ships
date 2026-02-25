extends BattleCharacter

var last_source_of_damage: Node
func accept_damage(strength: float, source: Node = null) -> void:
	last_source_of_damage = source
	super(strength, source)
