extends Node2D

func set_burn_percentage(percentage: float) -> void:
	get_material().set_shader_parameter("burn_percentage", percentage)

func set_team_color(color: Color) -> void:
	get_material().set_shader_parameter("team_color", color)
