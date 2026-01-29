shader_type canvas_item;

uniform sampler2D screen_texture: hint_screen_texture;

uniform float aspect_ratio = 2.0;
uniform float radius = 0.5;
uniform float halo_size = 0.1;
uniform float glow = 0.1;
uniform float ring_radius = 1.;
uniform int pulse_inverse_speed = 50;
uniform sampler2D distortion_curve;
uniform float distortion_strength = 1.;
uniform vec4 color_base: source_color = vec4(0.93,0.6,0.3,1.);

void fragment() {
	vec2 aspect_ratio_vec = vec2(aspect_ratio, 1.);
	vec2 position = (UV - vec2(0.5,0.5)) * 2. * aspect_ratio_vec;
	float halo_width = (radius * halo_size);
	float current_pixel_center_distance = length(position.xy);

	float pulse_modifier = float((int(TIME * 150.) % pulse_inverse_speed));
	pulse_modifier = abs(pulse_modifier - float(pulse_inverse_speed) / 2.)/ float(pulse_inverse_speed/3);
	float pos_in_halo = (current_pixel_center_distance - radius) / halo_width;
	float halo_light_strength = (15. * E * pos_in_halo) / pow(E, (10. * pos_in_halo));

	vec4 black_hole_color = vec4(0,0,0,1);
	if( // Construct halo
		current_pixel_center_distance >= radius
		&& current_pixel_center_distance < radius + halo_width
	) {
		black_hole_color = color_base * halo_light_strength;

		// If current pixel is near the radius, make it brigther
		black_hole_color += (halo_light_strength - 1.) * glow * smoothstep(1., 0., current_pixel_center_distance) / pulse_modifier;
	}

	// Screen distortion
	float curve_value = texture(distortion_curve, vec2(current_pixel_center_distance)).r;
	vec2 diff = normalize(position) * distortion_strength * curve_value;
	vec4 distorted_screen_color = texture(screen_texture, SCREEN_UV - diff);

	COLOR=max(black_hole_color, distorted_screen_color);
	COLOR.a = 1.;
}
