class_name CarrierShip
extends BattleCharacter

signal equipped_ship_with_mine(ship: BattleCharacter)

@export var sonar_blip_scale: Vector2 = Vector2(1., 1.)

func _on_mine_attachement_aura_equipped_ship(ship: BattleCharacter) -> void:
	equipped_ship_with_mine.emit(ship)
