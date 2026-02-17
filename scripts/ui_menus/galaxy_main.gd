extends Node2D

@export var star_speed: float = 0.05

var angle: float = 0.
func _process(delta_time: float) -> void:
	angle += star_speed * delta_time

	# Update the stars
	$StarParticles.get_process_material().set_shader_parameter("angle", angle);

	# Update scene selection
	for s in $scenes.get_children():
		s.get_node("orbitable").angle += star_speed * delta_time

func _on_dev_room_button_scene_selected() -> void:
	get_tree().change_scene_to_packed(preload("res://scenes/battles/dev_room_battle.tscn"))

func _on_tutorial_level_button_scene_selected() -> void:
	get_tree().change_scene_to_packed(preload("res://scenes/battles/tutorial_level.tscn"))

func _on_mr_mustle_battle_pressed() -> void:
	get_tree().change_scene_to_packed(preload("res://scenes/battles/mr_mustle.tscn"))
