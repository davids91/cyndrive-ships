class_name BattleDebris extends RigidBody2D

@export var debris_collision_layer_value = 0x01
@export var approx_size: float = 100.

@onready var spawn_snapshot: Dictionary
@onready var spawn_time_msec: float = BattleTimeline.instance.time_msec()
@onready var was_in_battle: bool = in_battle()

func in_battle() -> bool:
	return spawn_time_msec < BattleTimeline.instance.time_msec()

var temporal_overwrite_time_msec: float = 0.
var snapshot_to_set : Dictionary
func correct_temporal_state(snapshot: Dictionary, over_time_msec: float = 0.001) -> void:
	snapshot_to_set = snapshot
	temporal_overwrite_time_msec = abs(over_time_msec)

func get_snapshot() -> Dictionary:
	return {"transform": transform, "linear_velocity": linear_velocity, "angular_velocity": angular_velocity}

func erase() -> void: 
	create_tween().tween_method(func(w: float): $skin.set_burn_percentage(w), 0., 1., 0.5).finished.connect(func(): queue_free())

# This needs to be explicitly called here, instead of the @onready attr, to clearly set the order of initialization
func _ready() -> void: spawn_snapshot = get_snapshot()

func _process(_delta: float) -> void:
	# Erase from the map if time preceeds spawn time
	if BattleTimeline.instance.time_msec() < spawn_time_msec: erase()

	# Set battle presence state
	if not in_battle() and was_in_battle:
		create_tween().tween_method(func(value): $skin.set_burn_percentage(value), 0.0, 1.0, 0.5)
		set_collision_layer_value(debris_collision_layer_value, false)
		was_in_battle = false
	elif in_battle() and not was_in_battle:
		create_tween().tween_method(func(value): $skin.set_burn_percentage(value), 1.0, 0.0, 0.5)
		set_collision_layer_value(debris_collision_layer_value, true)
		was_in_battle = true

var physics_interval_msec = 1000. / Engine.physics_ticks_per_second
func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	if 0 < temporal_overwrite_time_msec:
		var weight_in_interpolation = physics_interval_msec / temporal_overwrite_time_msec
		if temporal_overwrite_time_msec < physics_interval_msec:
			weight_in_interpolation = 1.
		var current_snapshot = get_snapshot()
		if "transform" in snapshot_to_set:
			state.transform = lerp(current_snapshot["transform"], snapshot_to_set["transform"], weight_in_interpolation)
		if "linear_velocity" in snapshot_to_set:
			state.linear_velocity = snapshot_to_set["linear_velocity"] * BattleTimeline.time_flow
		if "angular_velocity" in snapshot_to_set:
			state.angular_velocity = snapshot_to_set["angular_velocity"]
		temporal_overwrite_time_msec -= physics_interval_msec

func respawn() -> void:
	correct_temporal_state(spawn_snapshot)
	$temporal_recorder.start_recording()
