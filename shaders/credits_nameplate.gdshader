shader_type canvas_item;

const float PI_DOUBLE = PI * 2.;

uniform sampler2D source_image;
uniform float displacement_length: hint_range(0.0, 0.4) = 0.5;
uniform sampler2D distortion_strength_;
uniform sampler2D distortion_direction_; // 0..1 --> 0..360 dgr
uniform float pixellize_size = 5.;

void fragment() {
	vec2 uv = UV;
	uv = round(uv * pixellize_size) / pixellize_size;
	float distortion_direction = texture(distortion_direction_, uv).r * PI_DOUBLE;
	float distortion_strength = texture(distortion_strength_, uv).r * displacement_length;
	vec2 distortion_position = vec2(cos(distortion_direction), sin(distortion_direction)) * distortion_strength;
	COLOR = texture(source_image, uv + distortion_position);
	COLOR.a = min(
		COLOR.a,
		smoothstep(1.25, 0.,length((uv - 0.5) * 2.))
	);
}
