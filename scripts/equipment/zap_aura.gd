extends Area2D

@export var zap_occurence_sec: float = 1.
@onready var wielder: BattleCharacter = get_parent()

var ships_within_aura: Dictionary = {}
func _on_body_entered(body: Node2D) -> void:
	if body != wielder and "team" in body and body.team.is_enemy(wielder.team):
		ships_within_aura[body] = randf() * zap_occurence_sec
		wielder.process_input_action({"acquired_target": body})

func _on_body_exited(body: Node2D) -> void:
	ships_within_aura.erase(body)

func _process(delta: float) -> void:
	for ship in ships_within_aura:
		if 0. < ships_within_aura[ship]: ships_within_aura[ship] -= delta
		elif ship.in_battle(): # Let's ZAP the ship
			ships_within_aura[ship] = randf() * zap_occurence_sec
			wielder.process_input_action({"acquired_target": ship})
