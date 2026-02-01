extends Node2D

signal boosting(is_boosting: bool)

@onready var character: BattleCharacter = get_parent()
@onready var team: Node2D = get_parent().get_node("team")
var enabled: bool = false
var intent_direction: Vector2 = Vector2()
var internal_force: Vector2 = Vector2()

@export_range(0.001, 200) var top_speed: float = 20.
@export_range(0.1, 10.) var booster_strength: float = 2.

func start() -> void:
	enabled = true

func pause() -> void:
	enabled = false

func stop() -> void:
	enabled = false
	internal_force = Vector2()
	last_intent = Vector2()
	current_impulse = Vector2()

var current_impulse: Vector2 = Vector2()
func apply_impulse(impulse: Vector2) -> void:
	current_impulse += impulse

var last_intent: Vector2 = Vector2()
var last_movement_input: Vector2 = Vector2()
var is_boosting: bool = false
@export_range(0., 1.) var angle_response: float = 0.5
@export_range(0., 1.) var speed_response: float = 0.45
@export_range(0., 1.) var floatiness: float = 0.965
func process_input_action(action: Dictionary) -> void:
	if "intent" in action:
		last_movement_input = action["intent"]
		if intent_direction.length() < 0.1:
			intent_direction = action["intent"]
		elif action["intent"].length() < 0.1:
			intent_direction = action["intent"] 
		else:
			var new_angle = lerp_angle(intent_direction.angle(), action["intent"].angle(), angle_response)
			intent_direction = Vector2(cos(new_angle), sin(new_angle))
			last_intent = intent_direction
	var was_boosting = is_boosting
	is_boosting = (
		(is_boosting and (not "boost_released" in action or not action["boost_released"]))
		or ("boost_initiated" in action and action["boost_initiated"])
	)
	if was_boosting != is_boosting: boosting.emit(is_boosting)

@onready var last_position = get_global_position()
func _physics_process(delta: float) -> void:
	if 0 < intent_direction.length():
		internal_force = lerp(internal_force, intent_direction, speed_response)
		if is_boosting:
			internal_force += intent_direction * booster_strength
	
	if intent_direction.length() < 0.15:
		intent_direction = Vector2()
	if not enabled or BattleTimeline.instance.time_flow == BattleTimeline.TimeFlow.BACKWARD:
		return
	
	# Calculate inner forces when not rewinding
	var pos_diff = (get_global_position() - last_position)
	if pos_diff.length() > 0.05: character.set_global_rotation(pos_diff.angle())
	character.set_velocity((internal_force + current_impulse * delta) * character.approx_size * top_speed)
	
	internal_force *= floatiness
	if internal_force.length() < 0.1: internal_force = Vector2()
	
	current_impulse *= 0.7
	if current_impulse.length() < 0.1: current_impulse = Vector2()
	
	last_position = get_global_position()

#region temporal corrective functions

func _set_internal_force(force: Vector2) -> void:
	internal_force = force

#endregion
