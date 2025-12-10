shader_type canvas_item;

uniform sampler2D noise;
uniform vec4 burn_color : source_color;
uniform vec4 team_color: source_color;

uniform float burn_percentage: hint_range(0.0, 1.0) = 0.5;
uniform sampler2D burn_curve;
uniform float burn_threshold: hint_range(0.001, 1.0) = 0.1;
uniform float burn_flame_supression: hint_range(0.0, 0.8) = 0.1;
uniform float pixel_scale: hint_range(1., 100.);
uniform float color_aberration: hint_range(0.0, 0.2) = 0.1;

void fragment() {
	vec2 pixel_uv = floor(UV * pixel_scale) / pixel_scale;
	vec2 large_pixel_uv = floor(UV * pixel_scale * 4.) / pixel_scale / 4.;
	vec4 skin_color;
	float red_abberation_angle = texture(noise, pixel_uv).r * 2. * PI;
	float green_abberation_angle = texture(noise, pixel_uv + vec2(0., 1.)).r * 2. * PI;
	float blue_abberation_angle = texture(noise, pixel_uv + vec2(1., 0.)).r * 2. * PI;
	float aberration = color_aberration * burn_percentage;
	skin_color = vec4(
		texture(TEXTURE, UV + vec2(cos(red_abberation_angle), sin(red_abberation_angle)) * aberration).r,
		texture(TEXTURE, UV + vec2(cos(green_abberation_angle), sin(green_abberation_angle)) * aberration).g,
		texture(TEXTURE, UV + vec2(cos(blue_abberation_angle), sin(blue_abberation_angle)) * aberration).b,
		max(max(
			texture(TEXTURE, UV + vec2(cos(red_abberation_angle), sin(red_abberation_angle)) * aberration).a,
			texture(TEXTURE, UV + vec2(cos(green_abberation_angle), sin(green_abberation_angle)) * aberration).a),
			texture(TEXTURE, UV + vec2(cos(blue_abberation_angle), sin(blue_abberation_angle)) * aberration).a
		)
	);
	skin_color = vec4(mix(skin_color, team_color, 0.45).rgb, skin_color.a);
	float corrected_burn_prec = texture(burn_curve, vec2(burn_percentage, 0.)).r;
	float skin_alpha = clamp(pow(texture(noise, large_pixel_uv).r, mix(0.001, 25., corrected_burn_prec)), 0., 1.);
	float skin_alpha_larger = clamp(pow(texture(noise, large_pixel_uv).r, mix(0.001, 10., corrected_burn_prec)), 0., 1.);
	vec4 burned_color = mix(burn_color, skin_color, clamp(skin_alpha / max(0.01, (burn_threshold - burn_flame_supression)), 0., 1.));
	skin_alpha = clamp(min(skin_alpha * 4., skin_color.a), 0., 1.);
    COLOR = vec4(burned_color.rgb, skin_alpha);
}