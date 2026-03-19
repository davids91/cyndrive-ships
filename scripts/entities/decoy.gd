class_name BattleDecoy extends BattleDebris

signal health_changed(percentage: float)
signal dead(BattleCharacter)
signal resurrected(BattleCharacter)

@export var seconds_per_frame: float = 0.25
@export var max_health: float = 10.
@export var team: Team = preload("res://resources/player_team.tres")

@onready var health: float = max_health

var frame: int = 0
var time_until_next_frame: float = seconds_per_frame
func _process(delta: float) -> void:
	super(delta)
	time_until_next_frame -= delta
	if time_until_next_frame < 0:
		time_until_next_frame = seconds_per_frame
		frame = (frame + 1) % 2
		$skin.region_rect.position.x = frame * 128.

func in_battle() -> bool:
	return super() and 0. < health

func get_snapshot() -> Dictionary:
	var snapshot = super()
	snapshot["health"] = health
	return snapshot

func correct_temporal_state(snapshot: Dictionary, over_time_msec: float = 0.001) -> void:
	super(snapshot, over_time_msec)
	if "health" in snapshot:
		var was_alive: bool = 0. < health
		health = snapshot["health"]
		if not was_alive and 0. < health: resurrected.emit(self)

func accept_damage(strength: float, _source: Node = null) -> void:
	health = max(0., health - strength)
	health_changed.emit(health / max_health)
	if health < 0: dead.emit(self)

func accept_healing(strength: float, _source: BattleCharacter = null) -> void:
	health = min(max_health, health + strength)
	health_changed.emit(health / max_health)

func get_velocity() -> Vector2: return get_linear_velocity()
func set_velocity(vel: Vector2) -> void: correct_temporal_state({"linear_velocity": vel})
func pause_control() -> void: pass
func resume_control() -> void: pass
