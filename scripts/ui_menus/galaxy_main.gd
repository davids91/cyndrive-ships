class_name MainMenu
extends Node2D

@export var star_speed: float = 0.005

@export var gui_visible: bool = true

func _ready() -> void:
	Difficulty.gameplay_speed = %difficulty_slider.value

var speed = star_speed
var angle: float = 0.
var hubble_angle: float = 0.
func _process(delta_time: float) -> void:
	angle += speed * delta_time / Difficulty.gameplay_speed
	hubble_angle += delta_time * speed * 100.
	$Hubble.offset = Vector2(sin(hubble_angle), cos(hubble_angle)) * 3.
	%difficuilty_text.modulate.a = (hubble_angle - floor(hubble_angle))

	# Update the stars
	$StarParticles.get_process_material().set_shader_parameter("angle", angle);

	# Update scene selection
	for s in $scenes.get_children(): if s.has_node("orbitable"):
		s.get_node("orbitable").angle += star_speed * delta_time / Difficulty.gameplay_speed

func _on_guides_button_pressed() -> void:
	speed = 0.
	%guides_cam.make_current()
	%guides_cam.offset = $movement_guide.position

func _on_back_button_pressed() -> void:
	speed = star_speed
	$main_cam.make_current()

func _on_next_button_pressed() -> void:
	%guides_cam.offset = $weapons_guide.position - Vector2(150., 0.)

func _on_next_button_pressed_2() -> void:
	%guides_cam.offset = $time_travel_guide.position

func _on_difficulty_slider_value_changed(value: float) -> void:
	Difficulty.gameplay_speed = value

func _on_dev_room_button_scene_selected() -> void: get_node("/root/Main").load_level("dev_room_battle")
func _on_tutorial_level_button_scene_selected() -> void: get_node("/root/Main").load_level("tutorial_level")
func _on_mr_mustle_battle_pressed() -> void: get_node("/root/Main").load_level("mr_mustle_battle")
func _on_dr_speedo_battle_pressed() -> void: get_node("/root/Main").load_level("dr_speedo_battle")
func _on_orange_boss_battle_pressed() -> void: get_node("/root/Main").load_level("orange_boss_battle")
func _on_level_1_pressed() -> void: get_node("/root/Main").load_level("level_1")
func _on_credits_button_pressed() -> void: get_node("/root/Main").load_menu("credits")
