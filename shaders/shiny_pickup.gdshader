shader_type canvas_item;

const float PI_DOUBLE = PI * 2.;
const int row_count = 3;

uniform vec4 color: source_color;
uniform float radius: hint_range(0.0, 1.0) = 0.6;
uniform sampler2D radius_curve: hint_anisotropy;
uniform sampler2D row_angle_offset: hint_anisotropy;
uniform int ray_count = 1;
uniform float ray_width: hint_range(0.0, 0.6) = 0.2;

void fragment() {
	vec2 uv = (UV - 0.5) * 2.;
	float px_angle = atan(uv.y, uv.x) + PI;
	int ray_count_in_row = int(round(float(ray_count) / float(row_count)));
	float light_strength = 0.;
	for(int row_i = 0; row_i < row_count; ++row_i){
		float row_radius = texture(radius_curve, vec2((radius / float(row_count)) * float(row_i), 0.)).r;
		for(int ray_i = 0; ray_i < ray_count_in_row; ++ray_i){
			float ray_angle = PI_DOUBLE * float(ray_i) / float(ray_count_in_row);
			ray_angle += texture(row_angle_offset, vec2(float(row_i)/float(row_count), 0.)).r;
			if (ray_angle >= (px_angle + PI)) ray_angle -= PI_DOUBLE;
			if (ray_angle <= (px_angle - PI)) ray_angle += PI_DOUBLE;
			light_strength += (1. - (length(uv) - row_radius)) * (smoothstep(ray_width, 0., abs(ray_angle - px_angle)));
		}
	}
	light_strength = min(COLOR.a, light_strength);
	COLOR = vec4(color.rgb, light_strength);
}
