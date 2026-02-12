extends Node

@export var game_speed = 0.2

func _ready() -> void:
	Engine.time_scale = game_speed
