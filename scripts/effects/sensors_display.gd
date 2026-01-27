extends Node2D

const SONAR_BLIP_SCENE = preload("res://scenes/effects/sonar_blip.tscn")

@export_range(0., 1.,) var sonar_width: float = 0.0075
@export_range(-1., 5.,) var sonar_edge_open: float = -0.5
@export_range(-1., 5.,) var sonar_edge_close: float = 5.
@export var open_time = 0.4
@export var close_time = 0.2
func set_sonar_visibility(yes: bool) -> void:
	if yes:
		create_tween().tween_method(
			func(w) : get_material().set_shader_parameter("sonar_width_percent", w),
			0., sonar_width, open_time
		)
		create_tween().tween_method(
			func(e) : get_material().set_shader_parameter("sonar_sharpness", e),
			0., sonar_edge_open, open_time
		)
	else:
		create_tween().tween_method(
			func(w) : get_material().set_shader_parameter("sonar_width_percent", w),
			sonar_width, 0., open_time
		)
		create_tween().tween_method(
			func(e) : get_material().set_shader_parameter("sonar_sharpness", e),
			sonar_edge_close, 0., open_time
		)

func set_sonar_rotation(rot: float) -> void: 
	get_material().set_shader_parameter("sonar_angle", rot)

func expose_health(over_seconds: float = 0.01) -> void:
	create_tween().tween_method(
		func(v): 
			get_material().set_shader_parameter("health_ring_width", v)
			health_ring_width = v,
		health_ring_width, health_ring_default_width, 
		over_seconds
	)

func hide_health(over_seconds: float = 0.2) -> void:
	create_tween().tween_method(
		func(v): 
			get_material().set_shader_parameter("health_ring_width", v)
			health_ring_width = v,
		health_ring_width, 0., 
		over_seconds
	)

var prev_health: float = 1.
var health_greeble_offset: Vector2 = Vector2()
const health_ring_default_width: float = 0.4;
var health_ring_width: float = 0.
func set_health_percentage(percentage: float) -> void:
	# Display health data
	get_material().set_shader_parameter("health_ring_core_width", 0.075 * percentage)
	get_material().set_shader_parameter("health", percentage)

	# Nudge the health display greebles
	if percentage < prev_health:
		var current_greeble_offset = health_greeble_offset
		health_greeble_offset += Vector2(randf() - 0.5, randf() - 0.5) * 0.02
		create_tween().tween_method(
			func(vec): get_material().set_shader_parameter("noise_offset", vec),
			current_greeble_offset, health_greeble_offset, 0.2
		)
	prev_health = percentage

func add_display_object(parent: Node2D, parent_offset: int, target: Node2D, p_color: Color) -> Node2D:
	if not visible:
		return null
	var sonar_blip = SONAR_BLIP_SCENE.instantiate()
	sonar_blip.init(parent, parent_offset, target, p_color)
	return sonar_blip
