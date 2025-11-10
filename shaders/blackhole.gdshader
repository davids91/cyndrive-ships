shader_type canvas_item;

uniform float aspect_ratio = 2.0;
uniform float radius = 0.5;
uniform float halo_size = 0.1;
uniform float glow = 0.1;
uniform float ring_radius = 1.;
uniform float z_angle_modifier = 0.5;
uniform int pulse_inverse_speed = 50;

void fragment() {
	vec2 aspect_ratio_vec = vec2(aspect_ratio, 1.);
	vec2 position = (UV - vec2(0.5,0.5)) * 2. * aspect_ratio_vec;
	float halo_width = (radius * halo_size);
	float current_pixel_center_distance = length(position.xy);
	vec4 color;
	vec4 palette_base = vec4(0.93,0.6,0.3,1.);
	vec4 space_base = vec4(0.03,0.05,0.1,0);

	float pulse_modifier = float((int(TIME * 150.) % pulse_inverse_speed));
	pulse_modifier = abs(
		pulse_modifier
		- float(pulse_inverse_speed) / 2.
	)
	/ float(pulse_inverse_speed/3)
	;
	float pos_in_halo = (current_pixel_center_distance - radius) / halo_width;
	float halo_light_strength = (15. * E * pos_in_halo) / pow(E, (10. * pos_in_halo));

	// If current pixel is near the radius, make it brigther
	if(current_pixel_center_distance < radius){
		color = vec4(0,0,0,1);
	} else if(
		current_pixel_center_distance >= radius
		&& current_pixel_center_distance < radius + halo_width
	){
		// Construct halo
		color = palette_base * halo_light_strength + space_base * (1.- halo_light_strength);
		color += (halo_light_strength - 1.) * space_base * glow * 1./pulse_modifier;
	}else{
		color=space_base;
	}

	// Construct photon ring
	float projected_z = position.y * z_angle_modifier * min(0.6, max(pulse_modifier, 0.4));
	float circle_result = (position.x * position.x) + (projected_z * projected_z);
	if(projected_z > 0. || (halo_light_strength < 0.4 && length(position) > radius)){
		if(abs(circle_result - ring_radius) < halo_size){
			color += (sin(position.y) + 1.) / 2. * palette_base * pulse_modifier/3. * circle_result;
		}
	} else {
		if(abs(current_pixel_center_distance - (radius + ring_radius*0.095)) < 0.08){
			color += (sin(position.y) + 1.) / 2. * palette_base * pulse_modifier/3. * (circle_result - halo_light_strength);
		}
	}
	COLOR=color;
}
