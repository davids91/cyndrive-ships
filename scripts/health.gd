extends Node2D

var starting_health = 10

var health = starting_health
var is_alive = true

func accept_damage(strength):
	get_parent().get_node("debug_label").set_text(str(health))
	health -= strength
	is_alive = 0 < health

func respawn():
	is_alive = true
	health = starting_health
