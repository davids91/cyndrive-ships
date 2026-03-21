extends ColorRect

@export var toggle_time_sec: float = 0.2

var is_active: bool = true
var display_tween: Tween = null
func toggle(active: bool) -> void:
	if display_tween: display_tween.kill()
	display_tween = create_tween()
	is_active = active
	if active:
		display_tween.tween_method(
			func(w: float): get_material().set_shader_parameter("pixel_continuity", w),
			0., 0.07, toggle_time_sec
		).set_ease(Tween.EASE_OUT)
	else:
		display_tween.tween_method(
			func(w: float): get_material().set_shader_parameter("pixel_continuity", w),
			0.07, 0., toggle_time_sec
		).set_ease(Tween.EASE_IN)

var elapsed_time_sec: float = 0.
func _process(delta: float) -> void:
	elapsed_time_sec += delta * BattleTimeline.instance.time_flow

	if is_active:
		var angle: float = fmod(elapsed_time_sec, PI * 2.)
		get_material().set_shader_parameter("long_leg_angle_", angle * 4.)
		get_material().set_shader_parameter("short_leg_angle_", angle)
