extends Control

@export var star_speed: float = 0.005

@export var gui_visible: bool = true

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
	for s in $scenes.get_children():
		s.get_node("orbitable").angle += star_speed * delta_time / Difficulty.gameplay_speed

func _unhandled_input(event: InputEvent) -> void:
	var just_pressed = event.is_pressed() and not event.is_echo()
	if event.is_action_pressed("key_bindings") and just_pressed:
		GUI.get_node("keybindings_panel").set_visible(not GUI.get_node("keybindings_panel").visible)

@onready var level_container: Node2D = get_node("/root/Main/LevelContainer")
@onready var player_input: PlayerInput = get_node("/root/Main/player_input")
@onready var GUI: BattleShipGUI = get_node("/root/Main/GUI")
func load_level(level_name: String) -> void:
	for n in level_container.get_children(): n.queue_free()
	var level = load("res://scenes/battles/" + level_name + ".tscn").instantiate()
	var player = level.get_node("%character")
	player_input.time_control_triggered.connect(player.time_control_triggered)
	GUI.configure(player_input, level, player)
	player_input.view_control_triggered.connect(level.view_control_triggered)
	level_container.add_child(level)
	get_node("/root/Main/background_music").play()

func _on_dev_room_button_scene_selected() -> void:
	load_level("dev_room_battle")

func _on_tutorial_level_button_scene_selected() -> void:
	load_level("tutorial_level")

func _on_mr_mustle_battle_pressed() -> void:
	load_level("mr_mustle_battle")

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

func _on_dr_speedo_battle_pressed() -> void:
	load_level("dr_speedo_battle")

func _on_level_1_pressed() -> void:
	load_level("level_1")
