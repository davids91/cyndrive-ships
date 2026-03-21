extends Area2D

@onready var character: BattleCharacter = get_parent()

var ships_within_aura: Dictionary = {}
func _on_body_entered(body: Node2D) -> void:
	if body != character and "team" in body and not body.team.is_enemy(character.team):
		ships_within_aura[body] = BattleTimeline.instance.time_msec()
		if body.has_method("display_dock_message"):
			body.display_dock_message(true) 

func _on_body_exited(body: Node2D) -> void:
	ships_within_aura.erase(body)
	if body.has_method("display_dock_message"):
		body.display_dock_message(false) 

func _process(delta: float) -> void:
	for ship in ships_within_aura:
		if (
			"carrier_ship" in ship and ship.carrier_ship == get_parent()
			and "docked" in ship and not ship.docked
			 and "needs_docking_support" in ship and ship.needs_docking_support
		): ship.apply_impulse((character.global_position - ship.global_position) * delta)
