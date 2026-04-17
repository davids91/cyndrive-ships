extends Node2D

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
	level.get_node("cam").make_current()
	$background_music.play()

func load_menu(menu_name: String) -> void:
	var level = load("res://scenes/UI/" + menu_name + ".tscn").instantiate()
	level.get_node("main_cam").make_current()
	for n in level_container.get_children(): n.queue_free()
	GUI.set_visible(false)
	level_container.add_child(level)
	$background_music.stop()
