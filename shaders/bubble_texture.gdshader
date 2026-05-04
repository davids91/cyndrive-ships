shader_type canvas_item;

const float PI_DOUBLE = PI * 2.;

uniform vec4 border_color: source_color;
uniform float bubble_radius = 0.6;
uniform float bubble_edge = 0.6;
uniform float arrow_angle_diff_rad = 0.3;
uniform float arrow_angle_rad = 0.;
uniform float arrow_bluntness = 0.;
uniform float pixellize_size = 5.;

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
	vec2 uv = round(UV * pixellize_size) / pixellize_size;
	float pixel_distance_to_center = length((uv - 0.5) * 2.);
	float edge_value_band = smoothstep(bubble_radius, bubble_edge, pixel_distance_to_center);
	float pixel_distance_to_arrow_dir = abs(pixel_distance_to_angle((uv - 0.5), arrow_angle_rad));

	// Update edge value band to be within border if the current pixel is within the direction of the displayed arrow
	if(
		pixel_distance_to_arrow_dir < arrow_angle_diff_rad
		&& pixel_distance_to_center > bubble_radius * 0.8
		&& smoothstep(0., 1., pixel_distance_to_center) < smoothstep(arrow_angle_diff_rad, arrow_bluntness, pixel_distance_to_arrow_dir)
	){
		edge_value_band = bubble_edge * 0.5;
	}
	
	if(edge_value_band <= bubble_edge * 1.5 && edge_value_band >= bubble_edge * 0.3){
		COLOR = border_color;
	}
	COLOR.a = min(COLOR.a, edge_value_band);
}
