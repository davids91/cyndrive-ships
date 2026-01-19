extends Area2D

var is_activated = false

var drop_position 
var x_offset = -33

var attached_position 

func _ready() -> void:
	$collide_to_activate.disabled = true	
	collision_layer = 1
	collision_mask = 0
	position.x = x_offset
	attached_position = Vector2(x_offset, position.y)

@onready var level = get_tree().current_scene	
const EXPLOSION_FIREY = preload("uid://btx22762p6sdy")

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("drop_mine") and !is_activated:
		deploy_mine()		
	elif event.is_action_pressed("drop_mine") and is_activated:		
		attach_mine()		

func explode_mine() -> void:
	var explode_effect = EXPLOSION_FIREY.instantiate()
	if explode_effect != null:						
		explode_effect.global_position = drop_position
		level.get_node("mush").add_child(explode_effect)
		explode_effect.reinit()
		explode_effect.scale = Vector2(3,3)
		var bodies_in_radius =$explode_radius.get_overlapping_bodies()	
		for body in bodies_in_radius:
			if body.has_node("team") and body.was_alive:		
				var body_team_id = body.get_node("team").team_id
				if body_team_id != 1:					
					body.was_alive = false
					body.was_in_battle = false
					body.dead.emit(body)
					body.unalive_me()
		await get_tree().create_timer(.2).timeout #give lightning time to draw
		queue_free() #remove the mine

func run_deployed_tween():	
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.3, 1.3), .5)
	tween.tween_property(self, "scale", Vector2(1, 1), .5)
	tween.set_loops(0)	

func accept_damage(_x,_y):
	if self != null:
		explode_mine()

func deploy_mine() -> void:	
	if self == null:
		return
	$collide_to_activate.disabled = false
	drop_position=global_position	
	get_parent().remove_child(self)
	level.get_node("combatants").add_child(self)
	set_global_position(drop_position)
	set_global_rotation(0)
	run_deployed_tween()	
	is_activated = true

func attach_mine() -> void:	
	var player = level.get_node("combatants/character")	
	var tween_out = create_tween()	
	$collide_to_activate.disabled = true
	tween_out.tween_property(self, "scale", Vector2(0.0, 0.0), .5)
	tween_out.tween_callback(func():
		reparent(player)		
		position = attached_position
		z_index = -1
		is_activated = false)	

func _on_explode_radius_body_entered(body: Node2D) -> void:
	if body.has_node("team") and is_activated:		
		var body_team_id = body.get("team_id")		
		if body_team_id != 1:
			explode_mine()
