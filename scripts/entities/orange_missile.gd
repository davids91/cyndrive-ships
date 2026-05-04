extends Node2D

var age = 0
var lifespan = 10
var speed = 650
var trigger_radius = 64

const XPLOSION: PackedScene = preload("res://scenes/effects/explosion-firey.tscn")
@onready var level: Node2D = get_node("/root/Main/LevelContainer/battle")
@onready var p1: BattleCharacter = level.get_node("%character")
@onready var spawn_time: float = BattleTimeline.instance.time_msec()

func _ready() -> void:
	$temporal_recorder.start_recording()

func get_snapshot() -> Dictionary:
	return {
		"transform": transform,
		"speed": speed,
		"is_expired": is_expired,
		"age": age,
	}

var debug_color: Color = Color.from_hsv(randf(), 1., 1., 1.)
func correct_temporal_state(snapshot: Dictionary, _over_time_msec: float = 0.001) -> void:
	if "transform" in snapshot: transform = snapshot["transform"]
	if "speed" in snapshot: speed = snapshot["speed"]
	if "age" in snapshot: age = snapshot["age"]
	if "is_expired" in snapshot: is_expired = snapshot["is_expired"]

var is_expired: bool = false
var was_expired: bool = false
func boom():
	explode()
	is_expired = true

var explosion: Explosion = null
func explode() -> void:
	if null == explosion:
		explosion = XPLOSION.instantiate()
		explosion.explosion_damage = 100.
		explosion.explosion_length = 3.
		explosion.explosion_range = 600.
		explosion.shockwave_strength = 5000.
		explosion.scale *= 3
		level.get_node("mush").add_child(explosion)
	explosion.global_position = get_global_position()
	explosion.reinit()
	# is_exploded = true
	# correct_temporal_state({"linear_velocity": Vector2.ZERO})

func _process(delta):
	var forward_dir: Vector2 = Vector2.RIGHT.rotated(rotation)
	position += forward_dir * speed * delta
	
	# see if we hit player
	if p1 != null:
		var d = global_position.distance_to(p1.global_position)
		if d <= trigger_radius: boom()
	
	age += delta
	if age > lifespan: is_expired = true
	if BattleTimeline.instance.time_msec() < spawn_time: queue_free()

	if is_expired and not was_expired:
		create_tween().tween_method(
			func(w: float):
				$missile_sprite.get_material().set_shader_parameter("burn_percentage", w)
				$glow.self_modulate.a = w,
			0., 1., 0.5
		)
	if not is_expired and was_expired:
		create_tween().tween_method(
			func(w: float):
				$missile_sprite.get_material().set_shader_parameter("burn_percentage", w)
				$glow.self_modulate.a = w,
			1., 0., 0.5
		)
		
	was_expired = is_expired
