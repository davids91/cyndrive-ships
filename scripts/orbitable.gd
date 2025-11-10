extends Node2D

@export var angle = 0.;
@export var distance = 10.;
@export var z_angle_modifier = 0.25;

func _process(delta_time):
	#TODO: Z projection
	var projected_position = Vector2(-sin(angle) * distance, cos(angle) * distance * z_angle_modifier)
	get_parent().set_position(projected_position);
	return false;
