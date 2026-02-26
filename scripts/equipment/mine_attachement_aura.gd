extends Area2D

signal equipped_ship(ship: BattleCharacter)

const mine_scene: PackedScene = preload("res://scenes/weapons/explossive_mine.tscn")
@onready var level = get_tree().current_scene

var ships_within: Dictionary = {}
func _on_body_entered(body: Node2D) -> void:
	# Do not equip the aura wielder, someone who doesn't have equipment to handle mines
	if(get_parent() == body or not "held_mine" in body): return

	if ( # Only Equip friendly or neutral ships
		not "team" in get_parent()
		or not "team" in body
		or not get_parent().team.is_enemy(body.team)
	): ships_within[body] = BattleTimeline.instance.time_msec()

func _process(_delta: float) -> void:
	if BattleTimeline.time_flow == BattleTimeline.TimeFlow.BACKWARD: return

	# attach mines to alive friendly ships when it's in contact with the aura
	for ship in ships_within:
		if(
			ship.in_battle()
			and "held_mine" in ship and not ship.held_mine
			and "ready_to_receive_mine" in ship and ship.ready_to_receive_mine
		):
			ship.ready_to_receive_mine = false
			ship.held_mine = mine_scene.instantiate()
			level.get_node("mush").add_child(ship.held_mine)
			BattleTimeline.instance.round_reset.connect(ship.held_mine.respawn)
			ship.held_mine.attach_mine(ship)
			ship.held_mine.set_global_position(ship.get_global_position() + ship.held_mine.mount_offset)

			# TechDebt: Mine shouldn't collide, and BattleDeris doesn't have a reliable method to initiate collision layer values
			for i in range(32): ship.held_mine.set_collision_layer_value(i, false)
			ship.held_mine.set_collision_layer_value(ship.held_mine.debris_collision_layer_value, true)
			equipped_ship.emit(ship)
			$attached_mine_sound.play()

func _on_body_exited(body: Node2D) -> void:
	ships_within.erase(body)
