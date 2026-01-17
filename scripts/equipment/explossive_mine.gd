extends Area2D

var is_activated = false
@onready var level = get_tree().current_scene	

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("drop_mine") and not is_activated:
		deploy_mine()

func run_deployed_tween():
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.3, 1.3), .5)
	tween.tween_property(self, "scale", Vector2(1, 1), .5)
	tween.set_loops(0)
	#tween.play()

func deploy_mine() -> void:	
	var drop_position = get_global_position()
	var drop_rotation = get_global_rotation()

	get_parent().remove_child(self)
	level.add_child(self)
	set_global_position(drop_position)
	set_global_rotation(0)
	run_deployed_tween()
	is_activated = true
