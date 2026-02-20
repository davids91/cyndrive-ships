class_name Team extends Resource

@export var team_id: int = 0
var ship_id: int = 0
@export var color: Color = Color()

func initialize_with_team(other: Team) -> void:
	initialize(other.team_id, other.color)

func initialize(team_id__: int, color__):
	color = color__
	team_id = team_id__
	ship_id = team_id__
	reassign_ship_id()
	
func reassign_ship_id():
	var previous_id = ship_id
	ship_id = ship_id + 1
	return previous_id

func is_enemy(other):
	return other.team_id != team_id
