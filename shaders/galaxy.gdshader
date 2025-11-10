shader_type particles;
uniform int number_of_arms = 5;
uniform float radius = 25.;
uniform float center_ratio = 0.1;
uniform float angle = 0.;
uniform float curvyness = 0.05;
uniform float scatter_width = 10;
uniform float scatter_length = 1.5;
uniform float z_angle_modifier = 0.25;
uniform sampler2D random_source;

/*
	// finalize random system
	// make starts in the back less visible
	// make stars in the center less visible
*/
uniform float wtf_am_i_doing = 6.;



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

int random_number(int range, inout uint seed){
	seed += uint(TIME * 10000.);
	uint t = seed ^ (seed << 101u);
	uint result = seed ^ (seed >> 190u) ^ (t ^ (t >> 80u));

	// simple formulae based way
	// return int(result % uint(range * 2)) - int(range); //including negative range
	return int(result) % int(range);
}

float tex_rand(vec2 co){
    return texture(random_source, co).r;
}

float std_rand(vec2 co){
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

float combined_rand(vec2 co){
	return tex_rand(vec2(std_rand(co.xy), std_rand(co.yx)));
}

vec2 centripetal_direction(vec3 pos){
	vec3 direction_to_center = -pos;
	vec3 direction;
	if(length(pos - vec3(0,0,1)) < 0.01){
		 direction = vec3(1,0,0);
	}else{
		direction = normalize(cross(vec3(0,0,1), direction_to_center));
	}
	/*direction.x = abs(direction.x);
	direction.x *= (true == clockwise) ? -1. : 1.; */
	return direction.xy;
}

vec2 get_target_position(int arm_index, inout uint random_seed){
	float random_value1 = float(random_number(100, random_seed)) / 100.;
	float random_value2 = float(random_number(100, random_seed)) / 100.;
	float random_value3 = float(random_number(100, random_seed)) / 100.;
	float random_value4 = float(random_number(100, random_seed)) / 100.;

	vec2 target_position;
	float center_size = radius * center_ratio;
	float arc_distance = center_size + random_value1 * radius * (1. - center_ratio);

	// Calculate default curve
	target_position.x = radius * arc_distance * cos(curvyness * arc_distance);
	target_position.y = radius * arc_distance * sin(curvyness * arc_distance);

	// push to arm
	float required_distance = length(target_position.xy);
	float current_angle_rad = get_angle(target_position.xy);
	float required_angle_rad = float(arm_index) * (2. * PI) / float(number_of_arms) + angle;
	target_position.x = cos(current_angle_rad + required_angle_rad) * required_distance;
	target_position.y = sin(current_angle_rad + required_angle_rad) * required_distance;

	// Scatter the arm
	vec2 scatter_direction = normalize(vec2((random_value3 - 0.5) / 2., (random_value4 - 0.5) / 2.));
	//vec2 scatter_direction = normalize(vec2(
		//(combined_rand(target_position.xy) - 0.5) * 2.,
		//(combined_rand(target_position.yx) - 0.5) * 2.
	//));
	target_position.xy += scatter_direction * pow(arc_distance - center_size, 2) * scatter_width / (arc_distance * scatter_length);

	// project y to z coordinate
	target_position.y *= z_angle_modifier;

	return target_position;
}

void start(){
	int arm_index = int(INDEX) % number_of_arms;
	uint random_seed = uint(INDEX + NUMBER);
	COLOR = vec4(1,1,1,1);
	VELOCITY = vec3(0,0,0);
	TRANSFORM[3].xy = get_target_position(arm_index, random_seed);
}

void process(){
	uint random_seed = uint(TIME);
	float random_value1 = float(random_number(200, random_seed)) / 200. - 0.5;
	float random_value2 = float(random_number(200, random_seed)) / 200. - 0.5;

	//Calculate the centripetal velocity and add it
	vec2 velo_direction = centripetal_direction(TRANSFORM[3].xyz) / 10.;
	velo_direction += normalize(vec2(
		(combined_rand(TRANSFORM[3].xy) - 0.5) * 2.,
		(combined_rand(TRANSFORM[3].yx) - 0.5) * 2.
	)) * length(velo_direction);
	VELOCITY.x = velo_direction.x;
	VELOCITY.y = velo_direction.y;
}