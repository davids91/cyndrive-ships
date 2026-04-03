extends ColorRect

@export var display_speed: float = 0.4

var current_angle: float = 0.
func _process(delta: float) -> void:
	current_angle = fmod(current_angle + delta * display_speed, PI * 2.)
	set_rotation(current_angle)
	get_material().get_shader_parameter("row_angle_offset").curve.set_point_value(
		0, 0.2 + abs(PI - current_angle) / PI * 0.4
	)
