shader_type canvas_item;

const float PI_DOUBLE = PI * 2.;

uniform sampler2D screen_texture : hint_screen_texture;
uniform sampler2D greeble_noise;
uniform vec2 noise_offset = vec2(0, 0);

uniform float aspect_ratio = 1.777777778; //1920./ 1080.;
uniform float shield : hint_range(0.0, 1.0) = 0.5;
uniform vec4 shield_inner_color : source_color = vec4(0.,0.,1.,1.);
uniform vec4 shield_outer_color : source_color = vec4(0.,0.,1.,1.);
uniform float shield_range : hint_range(0.0, 6.28318530718) = 0.5;
uniform float shield_angle : hint_range(0.0, 6.28318530718) = 0.5;
uniform float shield_ring_width : hint_range(0.0, 1.0) = 0.9;
uniform float shield_ring_core_width : hint_range(0.0, 0.25) = 0.1;
uniform float shield_display_alpha : hint_range(0.0, 1.0) = 0.55;
uniform float greeble_strength : hint_range(0., 0.5) = 0.001;
uniform float pixel_size = 1.;

// Provides the distance of the given pixel to the given angle within a circular sweep
float pixel_distance_to_angle(vec2 uv, float angle_rad) {
  float pixel_angle = atan(uv.y, uv.x) + PI;
  if (pixel_angle > PI_DOUBLE) {
    pixel_angle -= PI_DOUBLE;
  } else if (pixel_angle < -PI_DOUBLE) {
    pixel_angle += PI_DOUBLE;
  }
  float angle_diff = abs(angle_rad - pixel_angle);
  if (angle_diff > PI) {
    angle_diff = PI_DOUBLE - angle_diff;
  }
  return angle_diff;
}

void fragment() {
  vec2 uv = (UV - 0.5) * vec2(aspect_ratio, 1.);
  vec2 greebled_uv = (
    uv
    + (
      texture(
        greeble_noise,
        round((UV + noise_offset) * pixel_size) / pixel_size
      ).r - 0.5
    ) * greeble_strength
  );
  greebled_uv = round(greebled_uv * pixel_size) / pixel_size; // Create pixellized greeble noise

  // Decide how far the pixel is from the center
  float pixel_center_distance = length(uv);
  float greebled_pixel_center_distance = length(greebled_uv);

	// Display user interface
	vec4 result_color = vec4(0., 0., 0., 0.);
 	float shield_angle_diff = pixel_distance_to_angle(greebled_uv, shield_angle);
 	if (
		(
			(greebled_pixel_center_distance > shield_ring_width)
			&& (greebled_pixel_center_distance <= shield_ring_width + shield_ring_core_width)
		)
		&& shield_angle_diff < shield_range
	) {
		// shield display
		shield_angle_diff /= max(shield, 0.001);
		result_color = mix(
			shield_inner_color, shield_outer_color,
			smoothstep(
				shield_ring_width,
				shield_ring_width + shield_ring_core_width,
				greebled_pixel_center_distance
			)
		);
		result_color.a = (
			smoothstep(
				shield_ring_width + shield_ring_core_width * 2.,
				shield_ring_width,
				greebled_pixel_center_distance
			) * shield_display_alpha
		);
	}

	// Set the output color
	COLOR = result_color;
}
