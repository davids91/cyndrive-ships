extends BattleDebris

signal doors_toggled(is_open: bool)
signal health_changed(percentage: float)
signal payload_reached()

@export var starting_health: float = 100.
@export var color: Color = Color.YELLOW # Color for the minimap
@export var team: Team = preload("res://resources/enemy_team.tres")
@export var doors_fly_off_delay: float = 0.5

@onready var health: float = starting_health
@onready var is_alive: bool = true
@onready var was_alive: bool = is_alive
@onready var debris_container = get_node("/root/Main/LevelContainer/battle/debris")

# Overwrites function from BattleDebris
func get_snapshot() -> Dictionary:
	var snapshot = super()
	snapshot["health"] = health
	return snapshot

func correct_temporal_state(snapshot: Dictionary, over_time_msec: float = 0.001) -> void:
	if "health" in snapshot:
		health = snapshot["health"]
		_health_check()
	super(snapshot, over_time_msec)

const door_template: PackedScene = preload("res://scenes/entities/silo_door.tscn")
var doors: Array[BattleDebris]
var entangled: bool = false
func accept_damage(strength: float, _source: Node = null) -> void:
	health -= max(0., strength)
	_health_check()

func _health_check() -> void:
	is_alive = 0 < health
	health_changed.emit(health / starting_health)

	# Handle doors blasting open when silo is destroyed
	if is_alive != was_alive:
		doors_toggled.emit(not is_alive)
		for door in doors: door.erase()
		doors.clear()
		get_tree().create_timer(doors_fly_off_delay).timeout.connect(func():
			$collision_shape_closed.disabled = not is_alive
			if is_alive:
				for skin in get_tree().get_nodes_in_group("silo_closed_skin"): skin.set_visible(true)
				for skin in get_tree().get_nodes_in_group("silo_open_skin"): skin.set_visible(false)
			else:
				for skin in get_tree().get_nodes_in_group("silo_closed_skin"): skin.set_visible(false)
				for skin in get_tree().get_nodes_in_group("silo_open_skin"): skin.set_visible(true)
				# doors to fly away when silo is opened
				for relative_pos in [Vector2(412,0), Vector2(-412,0), Vector2(0,412), Vector2(0,-412)]:
					var door: BattleDebris = door_template.instantiate()
					door.global_position = global_position + relative_pos
					door.global_rotation = relative_pos.angle()
					door.linear_velocity = relative_pos + Vector2(randf(), randf()) * approx_size * 0.5
					door.angular_velocity = randf() * PI * 2.
					debris_container.add_child(door)
		)
	was_alive = is_alive

func _process(delta: float) -> void:
	$state_display.set_visible(visible)
	super(delta)

func _on_payload_trigger_body_entered(body: Node2D) -> void:
	if not is_alive and body is PlayerShip and $payload_trigger/payload:
		create_tween().tween_property($payload_trigger/payload, "self_modulate", Color.TRANSPARENT, 0.5).finished.connect(
			func(): if $payload_trigger/payload: $payload_trigger/payload.queue_free()
		)
		payload_reached.emit()
