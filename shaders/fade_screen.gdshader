shader_type canvas_item;

uniform float fade_radius: hint_range(0., 4.) = 0.6;

void fragment() {
	COLOR.a = smoothstep(0., fade_radius, length(UV - 0.5));
}