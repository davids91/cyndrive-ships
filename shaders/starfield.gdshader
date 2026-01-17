shader_type canvas_item;

uniform vec2 resolution = vec2(4096.0,4096.0);
uniform vec2 uv_offset = vec2(0.,0.);
uniform sampler2D noise_texture_star_strength: filter_nearest, repeat_enable;
uniform sampler2D noise_texture_star_color: filter_nearest, repeat_enable;
uniform float density: hint_range(0.0, 100.0) = 20.0;
uniform vec2 stars_speed = vec2(0.,0.);
uniform float layers: hint_range(1.0, 10.0, 1.0) = 5.0;
uniform float color_shift_strength: hint_range(0.0, 1.0) = 0.1;
uniform float sample_rounder: hint_range(0.0, 10000.0) = 0.1;
uniform float alpha: hint_range(0.0, 1.0) = 1.0;
uniform float noise_scale = 1.;

// https://github.com/curly-brace/Godot-3.0-Noise-Shaders/blob/master/assets/gpu_noise_shaders/simplex2d.tres
vec3 mod289_3(vec3 x) {
    return x - floor(x * (1.0 / 289.0)) * 289.0;
}

vec2 mod289_2(vec2 x) {
    return x - floor(x * (1.0 / 289.0)) * 289.0;
}

vec3 permute(vec3 x) {
    return mod289_3(((x*34.0)+1.0)*x);
}

float snoise(vec2 v) {
    vec4 C = vec4(0.211324865405187,  // (3.0-sqrt(3.0))/6.0
                  0.366025403784439,  // 0.5*(sqrt(3.0)-1.0)
                 -0.577350269189626,  // -1.0 + 2.0 * C.x
                  0.024390243902439); // 1.0 / 41.0
    // First corner
    vec2 i  = floor(v + dot(v, C.yy) );
    vec2 x0 = v -   i + dot(i, C.xx);

    // Other corners
    vec2 i1;
    //i1.x = step( x0.y, x0.x ); // x0.x > x0.y ? 1.0 : 0.0
    //i1.y = 1.0 - i1.x;
    i1 = (x0.x > x0.y) ? vec2(1.0, 0.0) : vec2(0.0, 1.0);
    // x0 = x0 - 0.0 + 0.0 * C.xx ;
    // x1 = x0 - i1 + 1.0 * C.xx ;
    // x2 = x0 - 1.0 + 2.0 * C.xx ;
    vec4 x12 = vec4(x0.xy, x0.xy) + C.xxzz;
    x12.xy -= i1;

    // Permutations
    i = mod289_2(i); // Avoid truncation effects in permutation
    vec3 p = permute( permute( i.y + vec3(0.0, i1.y, 1.0 ))
		+ i.x + vec3(0.0, i1.x, 1.0 ));

    vec3 m = max(0.5 - vec3(dot(x0,x0), dot(x12.xy,x12.xy), dot(x12.zw,x12.zw)), vec3(0.0));
    m = m*m ;
    m = m*m ;

    // Gradients: 41 points uniformly over a line, mapped onto a diamond.
    // The ring size 17*17 = 289 is close to a multiple of 41 (41*7 = 287)

    vec3 x = 2.0 * fract(p * C.www) - 1.0;
    vec3 h = abs(x) - 0.5;
    vec3 ox = floor(x + 0.5);
    vec3 a0 = x - ox;

    // Normalise gradients implicitly by scaling m
    // Approximation of: m *= inversesqrt( a0*a0 + h*h );
    m *= 1.79284291400159 - 0.85373472095314 * ( a0*a0 + h*h );

    // Compute final noise value at P
    vec3 g;
    g.x  = a0.x  * x0.x  + h.x  * x0.y;
    g.yz = a0.yz * x12.xz + h.yz * x12.yw;
    return 130.0 * dot(m, g);
}

void fragment() {
	vec2 uv = UV + uv_offset;
	vec2 speed = TIME * stars_speed * .01;
	uv.x *= resolution.x / resolution.y;

	// Calculate star brightness
	float stars = 0.0;
	for (float i = 0.0; i < layers; i += 1.0){
		float shift = i * 0.2;
		float brightness = 1.0 - i * 0.2;
		float sampled_noise = 1.;
		vec2 sample_coordinate = round((uv + shift + speed * (1.0 - i * 0.1)) * sample_rounder) / sample_rounder;
		sampled_noise *= (
			snoise(sample_coordinate * noise_scale) *
			texture(noise_texture_star_strength, sample_coordinate).r
		);
		stars += step(0.2, pow(sampled_noise, density)) * brightness;
	}

	// Add red and blue color shift
	vec3 star_color = vec3(stars);
	if (0. < stars) {
		float color_correction = texture(noise_texture_star_color, uv).r * 2. - 1.;
		star_color.r += min(0., color_correction) * color_shift_strength;
		star_color.b -= max(0., color_correction) * color_shift_strength;
		star_color.g -= color_shift_strength * ((1. - star_color.r) * 0.5 + (1. - star_color.b) * 0.5);
	}

	COLOR = vec4(star_color, stars * alpha);
}
