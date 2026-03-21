shader_type canvas_item;

uniform float clock_radius: hint_range(0., 1.) = 0.5;
uniform float clock_width: hint_range(0., 0.05) = 0.02;
uniform float long_leg_width: hint_range(0., 0.15) = 0.02;
uniform float long_leg_height: hint_range(0., 0.15) = 0.02;
uniform float short_leg_width: hint_range(0., 0.45) = 0.02;
uniform float short_leg_height: hint_range(0., 0.15) = 0.02;
uniform vec4 clock_color: source_color;
uniform float long_leg_angle_ : hint_range(0.0, 6.28318) = 0.;
uniform float short_leg_angle_ : hint_range(0.0, 6.28318) = 0.;
uniform float pixellize_size = 5.;
uniform float pixel_continuity: hint_range(0., 1.) = 1.;

void fragment() {
	vec2 uv = (UV - 0.5) * 2.;
	vec2 pixellated_uv = round(uv * pixellize_size) / pixellize_size;
	float clock_a = 0.;
	float px_angle = atan(pixellated_uv.y, pixellated_uv.x) + PI;
	float px_distance = length(pixellated_uv);
	float long_leg_angle = mod(long_leg_angle_, 2. * PI);
	float short_leg_angle = mod(short_leg_angle_, 2. * PI);

	// Make sure the angles are in the same phase
	if(abs(px_angle - long_leg_angle) > PI){
		if( long_leg_angle > px_angle) long_leg_angle -=  2. * PI;
		else long_leg_angle +=  2. * PI;
	}
	if(abs(px_angle - short_leg_angle) > PI){
		if( short_leg_angle > px_angle) short_leg_angle -=  2. * PI;
		else short_leg_angle +=  2. * PI;
	}

	if(
		( abs(px_distance - clock_radius) < clock_width ) // Display the face of the clock
		||( // Display the long leg
			abs(px_distance - clock_radius * 0.7) < long_leg_height
			&& abs(px_angle - long_leg_angle) < long_leg_width
		)
		||( // Display the short leg
			abs(px_distance - clock_radius * 0.5 ) < short_leg_height
			&& abs(px_angle - short_leg_angle) < short_leg_width
		)
	){
		clock_a = 1. - length(pixellated_uv - uv) / pixel_continuity;
	}
	COLOR = vec4(clock_color.rgb, clock_a);
}
