shader_type canvas_item;

uniform float aspect_ratio = 1.0;
uniform float angle = 0.;
uniform float sonar_width_percent = 0.1;

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
	vec2 aspect_ratio_vec = vec2(aspect_ratio, 1.);
	vec2 position = (UV - vec2(0.5,0.5)) * 2. * vec2(1.,-1.) * aspect_ratio_vec;
	float px_angle = get_angle(position);
	float objective_angle = angle;

	if(0. < objective_angle){
		while(objective_angle > 2.*PI)objective_angle -= 2.*PI;
	}else if (objective_angle < 0.){
		while(objective_angle < -2.*PI)objective_angle += 2.*PI;
		objective_angle = 2.*PI + objective_angle;
	}

	float angle_diff = abs(px_angle - objective_angle) / sonar_width_percent;

	COLOR = vec4(0,0,0,0);
	COLOR.g = 1. - pow(angle_diff, 2.);
	if(0.6 < COLOR.g) {
		COLOR.a = COLOR.g;
	} else COLOR.a = 0.;
}
