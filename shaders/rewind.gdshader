shader_type canvas_item;

const int CIRCLES_COUNT = 3;
const float circle_strip_components = 3.; // Each ring will have: a 0: width, a 1: start and a 2: length
const float PI_DOUBLE = PI * 2.;

uniform float screen_ratio_w_h = 1.777777778; //1920./ 1080.;
uniform sampler2D screen_texture : hint_screen_texture;
uniform sampler2D noise;

uniform float rewind_amount = 0.;
uniform float rewind_intensity: hint_range(0.0, 1.0) = 1.;
uniform vec2 circle_centers[CIRCLES_COUNT];
uniform float circle_radiuses[CIRCLES_COUNT];
uniform float max_rings = 5.;

uniform float pixellize_size = 5.;
uniform vec4 color_1 : source_color;
uniform vec4 color_2 : source_color;

void fragment() {
	vec2 uv = SCREEN_UV;
	if (1. < screen_ratio_w_h) {
		uv.y /= screen_ratio_w_h;
	}else{
		uv.x *= screen_ratio_w_h;
	}
	COLOR = vec4(0,0,0,0);
	if (rewind_intensity <= 0.0) {
		discard;
	}
	uv = round(uv * pixellize_size) / pixellize_size;

	// Determine circle index and distance
	int circle_index = 0;
	float distance_from_circle_center = length(circle_centers[0] - uv);
	for (int i = 1; i<CIRCLES_COUNT; ++i){
		float dist = length(circle_centers[i] - uv);
		if (dist < distance_from_circle_center && dist < circle_radiuses[i]) {
			distance_from_circle_center = dist;
			circle_index = i;
		}
	}
	vec2 vector_to_circle_center = circle_centers[circle_index] - uv;

	// Determine the number of rings within a circle, sample from the assigned noise area
	float circle_strip_width = 1. / float(CIRCLES_COUNT);
	float circle_strip_start_w = float(circle_index) * circle_strip_width;
	float number_of_rings = max_rings * texture(noise, vec2(circle_strip_start_w, 0.5)).r;
	float circle_strip_ring_height = 1. / number_of_rings;

	// Determine the ring this pixel lies on
	int ring_index = 0;
	float ring_distance = 0.;
	float strip_sample_y = 0.;
	float avg_ring_width = circle_radiuses[circle_index] / number_of_rings;
	float ring_width = texture(noise, vec2(circle_strip_start_w, strip_sample_y)).r * avg_ring_width;
	while(ring_distance < distance_from_circle_center && strip_sample_y < 1.)
	{
		strip_sample_y += circle_strip_ring_height;
		ring_width = texture(noise, vec2(circle_strip_start_w, strip_sample_y)).r * avg_ring_width;
		ring_distance += ring_width;
		++ring_index;
	}

	// Determine the offset based on time / rewind
	float manual_angle_offset = float(int(-rewind_amount * 10000.) % int(10000. * PI_DOUBLE)) / 10000.;

	// Determine ring start angle
	float strip_component_x_sample_width = circle_strip_width / circle_strip_components;
	float ring_start_angle_rad = PI_DOUBLE * texture(noise, vec2(circle_strip_start_w + strip_component_x_sample_width, strip_sample_y)).r;

	// determine ring length
	float strip_length_sample_x = circle_strip_start_w + strip_component_x_sample_width * 2.;
	float ring_filled_length_rad = PI_DOUBLE * texture(noise, vec2(strip_length_sample_x, strip_sample_y)).r;

	// determine position within the ring based on angle
	float current_px_angle_rad = atan(vector_to_circle_center.y, vector_to_circle_center.x);
	if (current_px_angle_rad < 0.0) {
		current_px_angle_rad += PI_DOUBLE;
	}

	// Add time as start offset
	ring_start_angle_rad += manual_angle_offset;

	while(current_px_angle_rad < ring_start_angle_rad){
		current_px_angle_rad += PI_DOUBLE;
	}

	vec4 clock_color = vec4(0,0,0,0);
	if (
		distance_from_circle_center <= ring_distance * 0.95
		&& distance_from_circle_center <= circle_radiuses[circle_index]
		&&
		(
			ring_start_angle_rad < current_px_angle_rad
			&& current_px_angle_rad < (ring_start_angle_rad + ring_filled_length_rad)
		)
	) {
		float pixel_alpha = rewind_intensity - (ring_distance - distance_from_circle_center) / ring_width;
		clock_color = vec4(
			mix(color_1, color_2, ring_width / avg_ring_width).rgb,
			pixel_alpha
		);
		if (distance_from_circle_center >= ring_distance * rewind_intensity){
			clock_color = mix(clock_color, vec4(1,1,1,1), 0.1);
		}
	}
	COLOR = clock_color;
}