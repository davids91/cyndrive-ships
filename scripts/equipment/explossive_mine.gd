extends Area2D

var is_activated = false

var drop_position 
var x_offset = -33

func _ready() -> void:
	position.x = x_offset

@onready var level = get_tree().current_scene	
const EXPLOSION_FIREY = preload("uid://btx22762p6sdy")

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("drop_mine") and not is_activated:
		deploy_mine()	

func explode_mine() -> void:
	var explode_effect = EXPLOSION_FIREY.instantiate()
	if explode_effect != null:						
		explode_effect.global_position = drop_position
		level.get_node("mush").add_child(explode_effect)
		explode_effect.reinit()
		var bodies_in_radius =$explode_radius.get_overlapping_bodies()	
		for body in bodies_in_radius:
			if body.has_node("team"):		
				var body_team_id = body.get("team_id")		
				if body_team_id != 1:
					print("kill an enemy!")
					body.queue_free() #need to trigger death/explosion on the body seems it might be auto based on queue_free?
		queue_free()

func run_deployed_tween():	
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.3, 1.3), .5)
	tween.tween_property(self, "scale", Vector2(1, 1), .5)
	tween.set_loops(0)	

func deploy_mine() -> void:
	if self == null:
		return		
	drop_position=global_position
	get_parent().remove_child(self)
	level.add_child(self)
	set_global_position(drop_position)
	set_global_rotation(0)
	run_deployed_tween()
	is_activated = true


func _on_body_entered(body: Node2D) -> void:	
	if body.has_node("team"):		
		var body_team_id = body.get("team_id")		
		if body_team_id != 1:
			explode_mine()
