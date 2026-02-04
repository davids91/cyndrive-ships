extends Node2D

var angle = 0.

func _process(delta_time):
	angle += 0.1 * delta_time
	
	# Update the stars
	var star_field = $StarParticles;
	star_field.get_process_material().set_shader_parameter("angle", angle);
	
	# Update habitable areas
	var habitable = $planet_marker/orbitable
	habitable.angle = angle
	
	return false;
