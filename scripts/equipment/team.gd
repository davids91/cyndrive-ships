extends Node2D

var team_id = 0 
var ship_id = 0 
var color = Color()

@export var  max_teammates = 10
@export var radius = 250

func initialize(team_id__, color__):
	color = color__
	team_id = team_id__
	ship_id = team_id__ * max_teammates
	reassign_ship_id()
	
func reassign_ship_id():
	var previous_id = ship_id
	ship_id = ship_id + 1
	return previous_id

func is_enemy(other):
	return other.team_id != team_id
