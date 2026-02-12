@tool
extends ColorRect

@export var effect_change_interval_sec: float = 5.
@export var rewind_amount_jump_delta: float = 2.

var time_until_next_effect_change: float = effect_change_interval_sec
var rewind_intensity: float = 0.6
var rewind_amount: float = 0.
func _process(delta: float) -> void:
	rewind_amount += delta
	material.set_shader_parameter("rewind_amount", rewind_amount)
	material.set_shader_parameter("rewind_intensity", clamp(rewind_intensity, 0.2, 1.))
	time_until_next_effect_change -= delta
	if time_until_next_effect_change <= 0.:
		time_until_next_effect_change = effect_change_interval_sec
		if 0.05 < randf(): create_tween().tween_method(
			func(w: float): rewind_amount += w, (randf() - 0.5) * rewind_amount_jump_delta,
			0., randf() * 2.
		)
		if 0.05 < randf(): create_tween().tween_method(
			func(w: float): rewind_intensity += w,
			(randf() - 0.5) * 0.1, 0., 2.
		)
