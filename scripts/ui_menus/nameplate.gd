class_name CreditsNamePlate
extends ColorRect

@export var dev_name: String = "Szarvas János"
@export var dev_role: String = "Lakatos - Zárszakértő; Biztonságtechnikus"

func _ready() -> void:
	set_nameplate(dev_name, dev_role)

func set_nameplate(dev_name_: String, dev_role_: String) -> void:
	dev_name = dev_name_
	dev_role = dev_role_
	%Name.text = dev_name
	%Role.text = dev_role

var phased: bool = true
var phase_tween: Tween
@export var phase_duration_sec: float = 2.
@export var phase_in_pixel_curve: Curve
@export var phase_in_distance_curve: Curve
func phase_in() -> Tween:
	phased = true
	return _phase_internal(0., 1.)

func phase_out() -> Tween:
	phased = false
	return _phase_internal(1., 0.)

func _phase_internal(start: float, end: float) -> Tween:
	if phase_tween: phase_tween.kill()
	phase_in_pixel_curve.set_point_value(1, randf() * 500.)
	phase_in_distance_curve.set_point_value(1, randf() * 0.35)
	phase_tween = create_tween()
	phase_tween.tween_method(
		func(w: float):
			get_material().set_shader_parameter("pixellize_size", phase_in_pixel_curve.sample(w))
			get_material().set_shader_parameter("displacement_length", phase_in_distance_curve.sample(w)),
		start, end,
		phase_duration_sec * Difficuilty.gameplay_speed
	)
	phase_tween.tween_callback(func():phase_tween = null)
	return phase_tween
