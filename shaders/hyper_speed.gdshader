shader_type canvas_item;

uniform sampler2D noise;
uniform sampler2D skin;

uniform float phase_red: hint_range(1.0, 1000.0) = 0.5;
uniform float phase_green: hint_range(1.0, 1000.0) = 0.5;
uniform float phase_blue: hint_range(1.0, 1000.0) = 0.5;
uniform float zoom: hint_range(0.01, 10.0) = 2.0;

void fragment() {
	vec2 uv = (UV - vec2(0.5,0.5)) * 2. * zoom;
	vec2 skin_uv = (UV - 0.5) / zoom + 0.5;
	vec2 red_uv = vec2(pow(skin_uv.x, phase_red), (skin_uv.y - 0.5) * max(1., phase_red * 0.1) + 0.5);
	vec2 green_uv = vec2(pow(skin_uv.x, phase_green), (skin_uv.y - 0.5) * max(1., phase_green * 0.1) + 0.5);
	vec2 blue_uv = vec2(pow(skin_uv.x, phase_blue), (skin_uv.y - 0.5) * max(1., phase_blue * 0.1) + 0.5);
	vec4 original_skin = texture(skin, skin_uv);
	vec4 red_skin = texture(skin, red_uv);
	vec4 green_skin = texture(skin, green_uv);
	vec4 blue_skin = texture(skin, blue_uv);
	COLOR = vec4(
		red_skin.r, green_skin.g, blue_skin.b,
		(original_skin.a + red_skin.a + green_skin.a + blue_skin.a) / 4.
	);
}