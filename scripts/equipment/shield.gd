class_name BattleShipShield
extends Area2D

@export_range(0., 1.) var shield_speed: float = 0.3
@export var shield_fluctuation: float = 100.
@export var starting_health: float = 50.
@export var health_regen_per_sec: float = 4.5

@onready var wielder: Node2D = get_parent()
@onready var health: float = starting_health
@onready var original_shield_size: float = $shield_shape.shape.height
@onready var original_shield_display_range: float = 1.25

var shield_active: bool = false
var shield_angle: float = 0.
var shield_angle_target: float = 0.
var greeble_position: Vector2 = Vector2(randf(), randf())
var greeble_target: Vector2 = Vector2(randf(), randf())
func _process(delta: float) -> void:
	# Handle positioning
	set_global_position(wielder.get_global_position())
	set_global_rotation(shield_angle)

	$display.set_visible(shield_active and wielder.visible)
	$shield_shape.disabled =  not shield_active
	if shield_active: # Apply shield fluctuation distortions
		shield_angle = lerp_angle(shield_angle, shield_angle_target, shield_speed)
		var vec_to_greeble_target = (greeble_target - greeble_position)
		if(0.01 > vec_to_greeble_target.length()):
			vec_to_greeble_target = Vector2(randf(), randf())
			greeble_target = Vector2(randf(), randf())
		greeble_position += vec_to_greeble_target * delta * shield_fluctuation
		$display.get_material().set_shader_parameter("noise_offset", greeble_position)

	# Shield regenerate
	health = min(starting_health, health + health_regen_per_sec * delta)
	_refresh_display()

func process_input_action(action: Dictionary) -> void:
	var was_active = shield_active
	if "switch_shield" in action: shield_active = !shield_active
	if shield_active and not was_active: shield_angle = shield_angle_target
	if "action_direction" in action and 0. < action["action_direction"].length():
		shield_angle_target = action["action_direction"].angle()

func accept_damage(strength: float, _source: Node = null) -> void:
	health = max(0., health - strength)
	_refresh_display()

func shutdown(): shield_active = false

func _refresh_display() -> void:
	var shield_size_ratio = health/starting_health
	$shield_shape.shape.height = original_shield_size * shield_size_ratio
	$display.get_material().set_shader_parameter("shield_range", original_shield_display_range * shield_size_ratio)
