class_name BattleShipWeapon extends Node2D

@export var base_damage: float = 1.
@export var energy_cost: float = 1.

var is_shooting:bool = false

## Functions to overwrite
func shutdown() ->  void: pass
func process_input_action(_action: Dictionary) -> void: pass
func reset() -> void: pass
