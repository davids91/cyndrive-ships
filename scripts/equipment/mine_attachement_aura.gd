extends Area2D

const mine_scene: PackedScene = preload("res://scenes/weapons/explossive_mine.tscn")
@onready var level = get_tree().current_scene

var ships_within: Dictionary = {}
func _on_body_entered(body: Node2D) -> void:
	# Do not equip the aura wielder, someone who doesn't have equipment to handle mines
	if(get_parent() == body or not "held_mine" in body): return

	if ( # Only Equip friendly or neutral shipsw
		not get_parent().has_node("team")
		or(
			body.has_node("team")
			and not get_parent().get_node("team").is_enemy(body.get_node("team"))
		)
	): ships_within[body] = BattleTimeline.instance.time_msec()

func _process(_delta: float) -> void:
	if BattleTimeline.instance.time_flow == BattleTimeline.TimeFlow.BACKWARD: return

	# attach mines to alive friendly ships when it's in contact with the aura
	for ship in ships_within:
		if("held_mine" in ship and ship.held_mine == null and ship.in_battle()):
			ship.held_mine = mine_scene.instantiate()
			level.get_node("debris").add_child(ship.held_mine)
			BattleTimeline.instance.round_reset.connect(ship.held_mine.respawn)
			ship.held_mine.attach_mine(ship)
			ship.held_mine.set_global_position(ship.get_global_position() + ship.held_mine.mount_offset)
			ship.held_mine.set_visible(ship.visible) # TECHDEBT: make first mine attached to the ship invisible
			ship.held_mine.spawn_snapshot = ship.held_mine.get_snapshot() # TECHDEBT: correct initial temporal snapshot of mine

func _on_body_exited(body: Node2D) -> void:
	ships_within.erase(body)
