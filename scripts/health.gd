extends Node2D

@export var starting_health = 10

@onready var health = starting_health

func value() -> int:
	return health

func set_value(new_value: int) -> void:
	health = new_value
	is_alive = 0 < health

var is_alive = true
func accept_damage(strength):
	if get_parent().has_node("debug_label"):
		get_parent().get_node("debug_label").set_text(str(health))
	health -= strength
	is_alive = 0 < health

func respawn():
	is_alive = true
	health = starting_health
