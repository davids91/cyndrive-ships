extends Node

@export var game_speed = 0.2

func _ready() -> void:
	Difficulty.gameplay_speed = game_speed
