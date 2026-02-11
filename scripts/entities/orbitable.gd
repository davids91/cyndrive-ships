extends Node2D

@export var z_angle_modifier = 0.25;

var angle = 0.;
var distance = 10.;
func _ready() -> void:
	var pos = get_parent().get_position()
	pos.y = pos.y / z_angle_modifier
	angle = atan2(-pos.x, pos.y)
	distance = pos.length()

func _process(_delta_time: float) -> void:
	get_parent().set_position(Vector2(-sin(angle) * distance, cos(angle) * distance * z_angle_modifier));
