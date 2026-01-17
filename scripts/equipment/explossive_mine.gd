extends Area2D

var is_activated = false
@onready var level = get_tree().current_scene

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("drop_mine") and not is_activated:
		deploy_mine()

func deploy_mine() -> void:
	print("tree: ", get_tree())
	print("current scene: ", get_tree().current_scene)
	print("root Children: ", get_tree().get_root().get_children())
	print("owner: ", owner)
	var drop_position = get_global_position()
	var drop_rotation = get_global_rotation()

	get_parent().remove_child(self)
	level.add_child(self)
	set_global_position(drop_position)
	set_global_rotation(drop_rotation)
