extends BattleShipWeapon

const decoy_template = preload("res://scenes/entities/decoy.tscn")

@export var appear_time_sec: float = 0.2
@export var reload_time_sec: float = 0.2
@export var launch_radius: float = 50.
@export var launch_velocity: float = 750.

@onready var combatants: Node = get_tree().current_scene.get_node("combatants")
@onready var wielder: BattleCharacter = get_parent()

var time_to_shoot_again: float = reload_time_sec
func _process(delta: float) -> void:
	if 0 < time_to_shoot_again: time_to_shoot_again -= delta
	is_shooting = false

func process_input_action(action: Dictionary) -> void:
	if (
		BattleTimeline.time_flow == BattleTimeline.TimeFlow.FORWARD
		and "action_direction" in action and 0. < action["action_direction"].length()
		and time_to_shoot_again <= 0.
	):
		time_to_shoot_again = reload_time_sec
		is_shooting = true
		var bullet: BattleDecoy = decoy_template.instantiate()
		bullet.set_global_position(wielder.get_global_position() + action["action_direction"] * launch_radius)
		bullet.set_velocity(action["action_direction"] * launch_velocity)
		bullet.get_node("temporal_recorder").start_recording()
		BattleTimeline.instance.connect("round_reset", bullet.respawn)
		combatants.add_child(bullet)
		create_tween().tween_method(
			func(w: float): bullet.get_node("skin").set_burn_percentage(w),
			1., 0., appear_time_sec
		)
