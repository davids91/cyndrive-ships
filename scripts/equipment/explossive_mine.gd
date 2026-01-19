extends Area2D

var is_activated = false

var drop_position 
var x_offset = -33

var attached_position 
var player_input 
static var active_mines = []

func _ready() -> void:
	$collide_to_activate.disabled = true
	player_input =  level.get_node("player_input")
	player_input.activate_mine.connect(check_mine_deploy)
	collision_layer = 1
	collision_mask = 0
	position.x = x_offset
	attached_position = Vector2(x_offset, position.y)

@onready var level = get_tree().current_scene
const EXPLOSION_FIREY = preload("uid://btx22762p6sdy")

func check_mine_deploy():	
	if player_input.has_mine == true and !is_activated:	
		deploy_mine()
		player_input.has_mine = false
	elif player_input.has_mine == false and is_activated:
		attach_mine()
		player_input.has_mine = true		

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
		active_mines.erase(self)
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
	active_mines.append(self)	
	$collide_to_activate.disabled = false
	drop_position=global_position	
	get_parent().remove_child(self)
	level.get_node("combatants").add_child(self)
	set_global_position(drop_position)
	set_global_rotation(0)
	run_deployed_tween()	
	is_activated = true

func find_closest_mine() -> Node2D:
	var closest_mine = null

	var closest_distance = INF
	var char_position = level.get_node("combatants/character").global_position
	for mine in active_mines:
		var dist = char_position.distance_to(mine.global_position)
		if dist < closest_distance:
			closest_distance = dist
			closest_mine = mine
	return closest_mine

func attach_mine() -> void:		
	var player = level.get_node("combatants/character")		
	var closest_mine = find_closest_mine()	
	if closest_mine != null:
		active_mines.erase(closest_mine)
		var tween_out = closest_mine.create_tween()
		closest_mine.get_node("collide_to_activate").disabled = true
		tween_out.tween_property(closest_mine, "scale", Vector2(0.0, 0.0), .5)
		tween_out.tween_callback(func():
			closest_mine.reparent(player)		
			closest_mine.position = attached_position			
			closest_mine.is_activated = false)
	
func _on_explode_radius_body_entered(body: Node2D) -> void:
	if body.has_node("team") and is_activated:		
		var body_team_id = body.get("team_id")		
		if body_team_id != 1:
			explode_mine()
