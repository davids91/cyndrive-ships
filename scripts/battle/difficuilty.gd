class_name Difficulty extends Node

static var gameplay_speed: float = 1.:
	set(value):
		gameplay_speed = value
		Engine.time_scale = value
