class_name Difficulty extends Node

static var gameplay_speed: float = 1.:
	set(value):
		gameplay_speed = value
		Engine.time_scale = value * slowdown_multiplier

static var slowdown_multiplier: float = 1.:
	set(value):
		slowdown_multiplier = value
		Engine.time_scale = value * slowdown_multiplier
