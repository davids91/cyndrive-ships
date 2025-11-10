shader_type canvas_item;

uniform float aspect_ratio = 1.0;
uniform float spaces = 0.5;
uniform float non_spaces = 0.5;
uniform int pulse_inverse_speed = 50;
uniform float border_size = 0.1;
uniform vec4 ring_color = vec4(0.5,0.9,0.7,1.0);

float get_angle(vec2 position){
	vec2 normal_position = normalize(position);
	vec2 reference_vector = vec2(1.,0.);
	float angle_rad = 0.;
	if(0. < position.y){
		normal_position.x *= -1.;
		angle_rad += PI;
	}
	angle_rad += acos(dot(normal_position, reference_vector));
	return angle_rad;
}

void fragment() {
	vec4 color = vec4(0,0,0,0);
	vec2 aspect_ratio_vec = vec2(aspect_ratio, 1.);
	vec2 position = (UV - vec2(0.5,0.5)) * 2. * aspect_ratio_vec;

	float pulse_modifier = float((int(TIME * 50.) % pulse_inverse_speed));
	pulse_modifier = abs(
		pulse_modifier
		- float(pulse_inverse_speed) / 2.
	)
	/ float(pulse_inverse_speed/3)
	;

	float circle_radius = 0.9;
	float circle_angle_rad = asin(position.y) * 100.;
	vec2 reference_position = normalize(position.xy) * circle_radius;
	float reference_angle = 180. * get_angle(reference_position) / PI + pulse_modifier;
	float display_value = tan(reference_angle / non_spaces);
	float space_modifier = 1. / spaces;
	float threshold = max(0.1 * pulse_modifier * border_size, 0.05);
	if(
		abs(length(position.xy) - circle_radius) < threshold
		&& ( display_value < space_modifier
		 || abs(reference_angle - 90.) < (10. * space_modifier)
		 || abs(reference_angle - 180.) < (10. * space_modifier)
		 || abs(reference_angle - 270.) < (10. * space_modifier)
		 || abs(reference_angle - 360.) < (10. * space_modifier)
		 || abs(reference_angle - 0.) < (10. * space_modifier)
		)
	){
		color = ring_color;
	}
	// if pixel is at display border
	else if(
		abs(length(position.xy) - circle_radius) <= threshold * 1.5
		&& ( display_value < space_modifier
		 || abs(reference_angle - 90.) <= (10. * space_modifier)
		 || abs(reference_angle - 180.) <= (10. * space_modifier)
		 || abs(reference_angle - 270.) <= (10. * space_modifier)
		 || abs(reference_angle - 360.) <= (10. * space_modifier)
		 || abs(reference_angle - 0.) <= (10. * space_modifier)
		)
	){
		color = vec4(0,0,0,1);
	}
	COLOR = color;
}
