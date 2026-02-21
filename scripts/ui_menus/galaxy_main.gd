extends Node2D

@export var star_speed: float = 0.005

var speed = star_speed
var angle: float = 0.
func _process(delta_time: float) -> void:
	angle += speed * delta_time / Difficulty.gameplay_speed

	# Update the stars
	$StarParticles.get_process_material().set_shader_parameter("angle", angle);

	# Update scene selection
	for s in $scenes.get_children():
		s.get_node("orbitable").angle += star_speed * delta_time / Difficulty.gameplay_speed

func _on_dev_room_button_scene_selected() -> void:
	get_tree().change_scene_to_packed(preload("res://scenes/battles/dev_room_battle.tscn"))

func _on_tutorial_level_button_scene_selected() -> void:
	get_tree().change_scene_to_packed(preload("res://scenes/battles/tutorial_level.tscn"))

func _on_mr_mustle_battle_pressed() -> void:
	get_tree().change_scene_to_packed(preload("res://scenes/battles/mr_mustle.tscn"))

func _on_guides_button_pressed() -> void:
	speed = 0.
	$guides_cam.make_current()
	$guides_cam.offset = $movement_guide.position

func _on_back_button_pressed() -> void:
	speed = star_speed
	$main_cam.make_current()

func _on_next_button_pressed() -> void:
	$guides_cam.offset = $weapons_guide.position - Vector2(150., 0.)

func _on_next_button_pressed_2() -> void:
	$guides_cam.offset = $time_travel_guide.position


func _on_difficulty_slider_value_changed(value: float) -> void:
	Difficulty.gameplay_speed = value
