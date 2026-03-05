extends Area2D

@export var healing_power: float = 0.5
@export var strength_over_time: float = 0.005

var player_input
var battle_ref 

var ships_within_aura: Dictionary = {}
@onready var character: BattleCharacter = get_parent()


func _ready() -> void:
	battle_ref= get_tree().get_root().get_node("battle")
	player_input =  battle_ref.get_node("player_input")

func _on_body_entered(body: Node2D) -> void:
	if body != character and "team" in body and not body.team.is_enemy(character.team):
		ships_within_aura[body] = BattleTimeline.instance.time_msec()
		if "is_being_healed" in body: body.is_being_healed = true

func _on_body_exited(body: Node2D) -> void:
	ships_within_aura.erase(body)
	if "is_being_healed" in body: body.is_being_healed = false

func _process(delta: float) -> void:
	for ship in ships_within_aura:
		if not "health" in ship: continue
		var effect_strength = abs(BattleTimeline.instance.time_since_msec(ships_within_aura[ship])) * strength_over_time
		ship.accept_healing(healing_power * effect_strength * delta)
